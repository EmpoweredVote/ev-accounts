-- 1642_seed_ca_county_san_mateo.sql
--
-- CA county wave: San Mateo County. 6 countywide elected officials, 726,353 residents.
-- Wave total: 13 counties, 66 seats, 21.61M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- smcgov.org is not bot-walled. The county's own site carries an "Elected Officials" nav block
-- naming its elected offices, and every holder below was read off that office's own page on
-- 2026-08-09:
--   Assessor-County Clerk-Recorder  smcacre.gov/profile/mark-church
--   County Controller               smcgov.org/controller/profile/juan-raigoza
--   Coroner                         smcgov.org/coroner/about-us + /coroner/profile/robert-foucrault
--   District Attorney               smcgov.org/da/overview + /da/profile/stephen-m-wagstaffe
--   Sheriff                         smcsheriff.com/administration
--   Treasurer-Tax Collector         smcgov.org/tax + /tax/profile/sandie-arnott
--
-- TITLES are the contest names on the county's CERTIFIED Election Summary Report for the
-- 2026-06-02 primary (certified 2026-06-30, smcacre.gov/system/files/2026-06/
-- 51_ElectionSummaryReportFINAL.pdf, read as a PDF): "Assessor-County Clerk-Recorder",
-- "County Controller", "Coroner", "Treasurer-Tax Collector". District Attorney and Sheriff take
-- their own office's name, because neither was on that ballot -- see below. Note the county's nav
-- says "Tax Collector - Treasurer" while the ballot says "Treasurer-Tax Collector"; the certified
-- ballot name wins.
--
-- 🔴 SAN MATEO ELECTS A SEPARATE CORONER. Most CA counties fold it into a Sheriff-Coroner. This is
-- the fourth distinct office set in this wave and the reason the standing rule is never to
-- template one -- the county's own elected-officials list is the only authority for which offices
-- exist.
--
-- ── 🔴🔴 AB 759 (2022): DA AND SHERIFF ARE ON THE PRESIDENTIAL CYCLE, WITH SIX-YEAR TERMS ──────
-- Every earlier migration in this wave carries a note that all countywide seats were on the
-- 2026-06-02 ballot and that winners take office in January 2027. THAT IS WRONG FOR DA AND SHERIFF
-- IN EVERY CALIFORNIA COUNTY, and this file is where it was finally run down.
--
-- San Joaquin (migration 1641) showed the symptom: no DA and no Sheriff contest on its 2026
-- ballot. San Mateo's certified summary shows exactly the same gap, which is a statewide cause,
-- not a local quirk. It is AB 759 (Chapter 743, approved 2022-09-29), amending Elections Code
-- section 1300 and Government Code section 24200 (bill text read at leginfo.legislature.ca.gov):
--   "An election to select a district attorney and sheriff shall be held with the presidential
--    primary."                                                       -- Elec. Code 1300(a)(1)
--   "A district attorney or sheriff elected in 2022 shall serve a six-year term and the next
--    election for that office shall occur at the 2028 presidential primary."  -- Elec. Code 1300(d)
--
-- Consequences for this wave, all of which are corrections to earlier headers:
--   * The 2026 winners for Assessor / Controller / Auditor / Clerk / Treasurer seats DO take
--     office in January 2027 -- that part stands, and San Mateo turns over one of them (below).
--   * DA and Sheriff seats DO NOT turn over in January 2027. Next election 2028, taking office
--     2029. Ventura's, Kern's, Contra Costa's and Fresno's DA/Sheriff rows are therefore good for
--     two years longer than their migration headers claim. No seeded row is wrong -- occupancy is
--     unaffected -- only the re-check dates in those comments.
--
-- 🔴 ONE SEAT TURNS OVER IN JANUARY 2027. The certified summary shows DAVID CANEPA won
-- Assessor-County Clerk-Recorder 56.21% over Jim Irizarry. Mark Church did not run. Church is the
-- correct holder through December 2026 and is seeded as such; re-check this county in January
-- 2027. Raigoza, Foucrault and Arnott each won unopposed (100%), so those three continue.
--
-- 🔴 THE SHERIFF SEAT CHANGED HANDS OUTSIDE ANY ELECTION -- AND THE OFFICE'S HOME PAGE NAMES NO
-- SHERIFF AT ALL. Christina Corpus, elected in 2022, was REMOVED from office in 2025. The Board of
-- Supervisors appointed Kenneth Binder to serve the remainder of the term; he took the oath on
-- 2025-11-12 (county press release "Supervisors Appoint Ken Binder as San Mateo County Sheriff",
-- smcgov.org/ceo/news/..., dated 2025-11-13 and describing the oath as taken "yesterday"; the
-- Sheriff's Office administration page says "sworn in as San Mateo County's 27th Sheriff on
-- Nov. 12, 2025"). Seeding Corpus off any stale roster would have been the single worst error
-- available in this county. Recency of a source is not freshness of a roster: what matters is
-- whether an election OR A REMOVAL fell in between.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Binder      2025-11-12  day    appointed by the Board; oath date from two county documents
--   Church      2011-01-01  month  "has served as San Mateo County's Assessor-County Clerk-Recorder
--                                  and Chief Elections Officer since January 2011" (his own page)
--   Raigoza     2015-01-01  month  "assumed the office of County Controller in January 2015"
--                                  (his own county profile page)
--   Wagstaffe   2011-01-01  month  elected unopposed in June 2010, took office January 2011
--   Arnott      2011-01-01  month  elected November 2010, took office January 2011
--   Foucrault   2002-01-01  year   APPOINTED after his predecessor's death and elected later the
--                                  same year. A 2002-06-04 appointment date is reported, but only
--                                  by a secondary source, so the year is recorded and the day is
--                                  not. (He had covered the office's duties from 2000 while the
--                                  previous coroner was ill -- that is not occupancy.)
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62081001..6.
-- Pre-flight: 0 external_id collisions. Surname sweep found two unrelated people -- "Jim Arnott"
-- (external_id -29077004, Sheriff of Greene County, MISSOURI) and "Lindsay Church" (-170404, no
-- office). Different first names, so new rows are created and nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-County Clerk-Recorder', -62081001,'Mark Church','Mark','Church',NULL,'2011-01-01','month','elected'),
  ('County Controller',              -62081002,'Juan Raigoza','Juan','Raigoza',NULL,'2015-01-01','month','elected'),
  ('Coroner',                        -62081003,'Robert J. Foucrault','Robert','Foucrault','J','2002-01-01','year','appointed'),
  ('District Attorney',              -62081004,'Stephen M. Wagstaffe','Stephen','Wagstaffe','M','2011-01-01','month','elected'),
  ('Sheriff',                        -62081005,'Kenneth Binder','Kenneth','Binder',NULL,'2025-11-12','day','appointed'),
  ('Treasurer-Tax Collector',        -62081006,'Sandie Arnott','Sandie','Arnott',NULL,'2011-01-01','month','elected');

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
SELECT 'San Mateo County, California, US', 'County', 'CA', '06081'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06081' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
   AND g.geo_id='06081' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'San Mateo County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06081' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='San Mateo County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1642 — San Mateo County department pages + certified 2026-06-02 Election Summary Report, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='San Mateo County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1642 — San Mateo County department pages + certified 2026-06-02 Election Summary Report, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_corpus integer;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 San Mateo offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Named guard: the removed sheriff must never end up holding this seat.
  SELECT count(*) INTO v_corpus
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
     AND p.last_name ILIKE 'Corpus';
  IF v_corpus > 0 THEN RAISE EXCEPTION 'Removed sheriff Corpus is seated in San Mateo County'; END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06081'
     AND g.geo_id='06081' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'San Mateo district not linked to its government row (%)', v_gov; END IF;
END $$;

COMMIT;
