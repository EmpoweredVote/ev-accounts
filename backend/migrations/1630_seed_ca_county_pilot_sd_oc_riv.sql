-- 1630_seed_ca_county_pilot_sd_oc_riv.sql
--
-- CA county wave, PILOT: San Diego, Orange, Riverside countywide elected officials.
-- 15 seats, 8.90M residents. Proves the method before the remaining 22 counties.
--
-- ── ROSTER FIRST, OFFICE SECOND ────────────────────────────────────────────────────────────────
-- Every office below has a verified sitting holder seated in the same migration. No office is
-- created empty. That is the 504-invisible-judicial-seats rule: an office with no office_terms row
-- is invisible everywhere and NOTHING ERRORS.
--
-- ── THE OFFICE SET IS READ PER COUNTY, NEVER TEMPLATED ─────────────────────────────────────────
-- These three counties have 4, 5 and 6 countywide elected offices respectively, and they combine
-- them differently:
--   San Diego  folds Assessor + Recorder + County Clerk into ONE office, and does NOT elect an
--              Auditor (it is appointed there) -- 4 offices.
--   Orange     splits Clerk-Recorder from Assessor and DOES elect an Auditor-Controller,
--              and combines Sheriff-Coroner -- 6 offices.
--   Riverside  folds Assessor + County Clerk + Recorder, elects an Auditor-Controller,
--              and combines Sheriff-Coroner -- 5 offices.
-- A shared 6-office template would have invented seats in two of three counties. Sources are the
-- counties' own rosters, fetched 2026-08-08:
--   San Diego  https://www.sandiegocounty.gov/            ("Elected offices")
--   Orange     https://www.ocgov.com/about-county/info-oc/elected-officials
--   Riverside  https://rivco.gov/elected-officials-compensation  ("Countywide Elected Officials")
-- Web SEARCH was wrong on two Riverside seats (it returned Paul Angulo and Jon Christensen, both
-- years out of date). Only the counties' own pages were trusted.
--
-- ── BOARDS OF SUPERVISORS ARE DELIBERATELY EXCLUDED ────────────────────────────────────────────
-- CA supervisors are elected by SUB-COUNTY district and those polygons do not exist for these
-- counties. Seating them against the countywide polygon would create exactly the unreachable
-- officeholder that check:reachability exists to catch. Separate geography project.
--
-- ── TERM STARTS ARE OCCUPANCY STARTS, NOT CURRENT-TERM STARTS ──────────────────────────────────
-- Matching the convention of the two well-sourced rows in this table (Dane County's Ozanne carries
-- 2010, not his latest re-election): term_start is when the person FIRST took the office and held
-- it continuously. Re-election does not end occupancy.
--
-- 4 of these 15 reached office by APPOINTMENT mid-term, not election. A blanket statutory
-- "first Monday after January 1" date would have been wrong for every one of them, by up to 12
-- years -- Nguyen (2013), Stephan (2017), Jennings (2020), Cohen (2025). how_started records this.
--
-- Dates are day-precision ONLY where a source names the day. Where sources give a month, or
-- conflict on the day, start_precision is 'month' and the date is the 1st -- NOT a guessed day.
--   Freidenrich  source says "January 2011" only
--   Aldana       source says "assumed office January 2015" only
--   Barnes       sources conflict: sworn in Jan 7 vs Jan 9 2019
--   Bianco       sources conflict: sworn in Jan 8 vs Jan 9 2019
--
-- ── LOS ANGELES IS NOT TOUCHED HERE ────────────────────────────────────────────────────────────
-- LA has 3 DUPLICATE county district rows (all geo_id 06037) with its 3 offices spread one per
-- row, on 3 different chamber_ids, plus duplicate supervisor chambers. It also sits at
-- state='CA' while all 57 other CA counties are state='ca'. Adding offices there without first
-- electing a canonical row would deepen the duplication. Separate repair migration.
--
-- ── external_id BAND ───────────────────────────────────────────────────────────────────────────
-- -(6000000 + <3-digit county FIPS> * 1000 + seq). Verified 0 collisions before writing: the
-- CA band in use is -6015201..-6000101 (217 rows), well clear of -6059001..-6065004.
-- Chad Bianco is NOT created here -- he already exists (-6003002, seeded as a 2026 CA Governor
-- candidate) and currently holds NO seat, so seating him also makes an existing invisible
-- officeholder visible. Reused, not duplicated.
--
-- Party is deliberately left NULL: these CA county offices are nonpartisan, and party belongs on
-- races.primary_party regardless.
--
-- Idempotent: keyed on external_id / slug / (district_id,title). Re-running changes nothing and
-- re-passes the gate. seat_officeholder is itself idempotent.

BEGIN;

CREATE TEMP TABLE _cty (
  geo_id   text,
  gov_name text,
  ch_slug  text,
  ch_formal text
) ON COMMIT DROP;

INSERT INTO _cty VALUES
  ('06073','San Diego County, California, US','san-diego-county-countywide-elected-officials','San Diego County Countywide Elected Officials'),
  ('06059','Orange County, California, US',   'orange-county-countywide-elected-officials',   'Orange County Countywide Elected Officials'),
  ('06065','Riverside County, California, US','riverside-county-countywide-elected-officials','Riverside County Countywide Elected Officials');

CREATE TEMP TABLE _seed (
  geo_id     text,
  title      text,
  seq        int,
  ext_id     bigint,      -- NULL => person already exists, match on existing_pid
  existing_pid uuid,
  full_name  text,
  first_name text,
  last_name  text,
  mid        text,
  term_start date,
  precision  text,
  how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  -- San Diego -- 4 offices
  ('06073','Assessor, Recorder, County Clerk',1,-6073001,NULL,'Jordan Z. Marks','Jordan','Marks','Z','2023-01-02','day','elected'),
  ('06073','District Attorney',              2,-6073002,NULL,'Summer Stephan','Summer','Stephan',NULL,'2017-07-07','day','appointed'),
  ('06073','Sheriff',                        3,-6073003,NULL,'Kelly A. Martinez','Kelly','Martinez','A','2023-01-02','day','elected'),
  ('06073','Treasurer-Tax Collector',        4,-6073004,NULL,'Larry Cohen','Larry','Cohen',NULL,'2025-11-18','day','appointed'),
  -- Orange -- 6 offices
  ('06059','Assessor',                       1,-6059001,NULL,'Claude Parrish','Claude','Parrish',NULL,'2015-01-05','day','elected'),
  ('06059','Auditor-Controller',             2,-6059002,NULL,'Andrew N. Hamilton','Andrew','Hamilton','N','2023-01-02','day','elected'),
  ('06059','Clerk-Recorder',                 3,-6059003,NULL,'Hugh Nguyen','Hugh','Nguyen',NULL,'2013-04-02','day','appointed'),
  ('06059','District Attorney',              4,-6059004,NULL,'Todd Spitzer','Todd','Spitzer',NULL,'2019-01-07','day','elected'),
  ('06059','Sheriff-Coroner',                5,-6059005,NULL,'Don Barnes','Don','Barnes',NULL,'2019-01-01','month','elected'),
  ('06059','Treasurer-Tax Collector',        6,-6059006,NULL,'Shari L. Freidenrich','Shari','Freidenrich','L','2011-01-01','month','elected'),
  -- Riverside -- 5 offices
  ('06065','Assessor-County Clerk-Recorder', 1,-6065001,NULL,'Peter Aldana','Peter','Aldana',NULL,'2015-01-01','month','elected'),
  ('06065','Auditor-Controller',             2,-6065002,NULL,'Ben J. Benoit','Ben','Benoit','J','2023-01-02','day','elected'),
  ('06065','District Attorney',              3,-6065003,NULL,'Michael Hestrin','Michael','Hestrin',NULL,'2015-01-05','day','elected'),
  ('06065','Treasurer-Tax Collector',        4,-6065004,NULL,'Matt Jennings','Matt','Jennings',NULL,'2020-09-24','day','appointed'),
  ('06065','Sheriff-Coroner',                5,NULL,'5bcf2a31-2fb6-43e5-88d7-ca9c25d5fb6f'::uuid,'Chad Bianco','Chad','Bianco',NULL,'2019-01-01','month','elected');

-- ── 1. governments ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT c.gov_name, 'County', 'CA', c.geo_id
  FROM _cty c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g
                    WHERE g.geo_id = c.geo_id AND g.type = 'County');

-- ── 2. link the county district row to its government ──────────────────────────────────────────
-- SCOPED BY district_type. geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g, _cty c
 WHERE d.district_type = 'COUNTY'
   AND lower(d.state) = 'ca'
   AND d.geo_id = c.geo_id
   AND g.geo_id = c.geo_id AND g.type = 'County'
   AND d.government_id IS DISTINCT FROM g.id;

-- ── 3. one "Countywide Elected Officials" chamber per county ───────────────────────────────────
-- Matches the working precedent in Dane WI / Racine WI / Deschutes OR -- NOT the LA shape, which
-- spreads 3 offices across 3 per-role chambers.
-- chambers.slug is GENERATED ALWAYS from name_formal -- it must NOT be inserted. The _cty.ch_slug
-- values are what that expression derives from ch_formal, and are used only for lookups below.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', c.ch_formal, g.id,
       (SELECT count(*) FROM _seed s WHERE s.geo_id = c.geo_id),
       'full'
  FROM _cty c
  JOIN essentials.governments g ON g.geo_id = c.geo_id AND g.type = 'County'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.slug = c.ch_slug);

-- ── 4. politicians (14 new; Bianco reused) ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1630 — ' || c.gov_name || ' official roster, fetched 2026-08-08',
       true, true
  FROM _seed s JOIN _cty c ON c.geo_id = s.geo_id
 WHERE s.ext_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

-- ── 5. offices ─────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN _cty c   ON c.geo_id = s.geo_id
  JOIN essentials.chambers ch ON ch.slug = c.ch_slug
  JOIN essentials.districts d ON d.district_type = 'COUNTY' AND lower(d.state) = 'ca' AND d.geo_id = s.geo_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                    WHERE o.district_id = d.id AND o.title = s.title);

-- ── 6. seat every holder ───────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  r record;
  v_office_id uuid;
  v_pid       uuid;
BEGIN
  FOR r IN SELECT s.*, c.gov_name FROM _seed s JOIN _cty c ON c.geo_id = s.geo_id LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'ca' AND d.geo_id = r.geo_id
       AND o.title = r.title;

    IF v_office_id IS NULL THEN
      RAISE EXCEPTION 'No office row for % / %', r.geo_id, r.title;
    END IF;

    IF r.existing_pid IS NOT NULL THEN
      v_pid := r.existing_pid;
    ELSE
      SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id = r.ext_id;
    END IF;

    IF v_pid IS NULL THEN
      RAISE EXCEPTION 'No politician for % (%)', r.full_name, r.ext_id;
    END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id,
      v_pid,
      r.term_start,
      'migration 1630 — ' || r.gov_name || ' official roster, fetched 2026-08-08',
      r.how_started,
      r.precision
    );
  END LOOP;
END $$;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices   integer;
  v_seated    integer;
  v_vacant    integer;
  v_chambers  integer;
  v_la        integer;
  v_percounty text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id IN ('06073','06059','06065');

  IF v_offices <> 15 THEN
    RAISE EXCEPTION 'Expected 15 pilot offices, found %', v_offices;
  END IF;

  -- Every office must have a holder. This is the whole point of the migration.
  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id IN ('06073','06059','06065')
     AND och.politician_id IS NOT NULL;

  IF v_seated <> 15 THEN
    RAISE EXCEPTION 'Expected 15 seated holders, found % -- an office was created without an occupant', v_seated;
  END IF;

  -- Per-county counts must be 4 / 6 / 5, not a uniform template value.
  SELECT string_agg(x.geo_id || '=' || x.n, ' ' ORDER BY x.geo_id) INTO v_percounty
    FROM (SELECT d.geo_id, count(*) AS n
            FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.district_type='COUNTY' AND lower(d.state)='ca'
             AND d.geo_id IN ('06073','06059','06065')
           GROUP BY d.geo_id) x;

  IF v_percounty <> '06059=6 06065=5 06073=4' THEN
    RAISE EXCEPTION 'Per-county office counts wrong -- expected "06059=6 06065=5 06073=4", got "%"', v_percounty;
  END IF;

  -- Exactly one chamber per county, no per-role chamber sprawl.
  SELECT count(*) INTO v_chambers
    FROM essentials.chambers WHERE slug IN (
      'san-diego-county-countywide-elected-officials',
      'orange-county-countywide-elected-officials',
      'riverside-county-countywide-elected-officials');

  IF v_chambers <> 3 THEN
    RAISE EXCEPTION 'Expected 3 countywide chambers, found %', v_chambers;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id IN ('06073','06059','06065')
     AND o.is_vacant;

  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'Expected 0 vacant pilot offices, found %', v_vacant;
  END IF;

  -- LA must be untouched by this migration.
  SELECT count(*) INTO v_la
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '06037' AND d.district_type = 'COUNTY';

  IF v_la <> 3 THEN
    RAISE EXCEPTION 'Los Angeles office count changed to % -- this migration must not touch LA', v_la;
  END IF;
END $$;

COMMIT;
