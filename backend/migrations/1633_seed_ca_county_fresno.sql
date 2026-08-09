-- 1633_seed_ca_county_fresno.sql
--
-- CA county wave: Fresno County. 6 countywide elected officials, 1.02M residents.
-- Running total for the wave: 8 counties, 38 seats, 17.19M residents.
--
-- ── 🔴 WHY THIS COUNTY IS A MIGRATION BY ITSELF ────────────────────────────────────────────────
-- Fresno was researched as part of a four-county batch (with Contra Costa, Kern and Ventura).
-- Only Fresno is seeded here, because only Fresno could be sourced from a primary document.
-- Contra Costa and Ventura publish their office TITLES but not the officeholders' names, and
-- Kern's names were only ever available from web search. After what search did to Fresno --
-- below -- seeding any of those three from a search summary is not defensible. They are deferred
-- until their rosters are read from source.
--
-- ── 🔴 THE OFF-BY-ONE THAT NO GATE COULD HAVE CAUGHT ───────────────────────────────────────────
-- Web search summarised Fresno's own ROV roster PDF and shifted every name one row up the table,
-- pairing each person with the NEXT office, while silently dropping two offices entirely:
--
--     SEARCH SAID                                   THE PDF ACTUALLY SAYS
--     Assessor-Recorder .......... Oscar J. Garcia  Assessor-Recorder .......... Paul Dictos
--     Auditor-Ctrl/Treas-Tax ..... James A. Kus     Auditor-Ctrl/Treas-Tax ..... Oscar J. Garcia
--     (missing)                                     County Clerk ............... James A. Kus
--     District Attorney .......... John J. Zanoni   District Attorney .......... Lisa A. Smittcamp
--     Sheriff/Coroner/Pub Admin .. M. Cantwell-Copher Sheriff/Coroner/Pub Admin  John J. Zanoni
--     (missing)                                     Superintendent of Schools .. M. Cantwell-Copher
--
-- Four real people would have been installed in four wrong offices, and the identity gate added
-- in migration 1631 would have PASSED -- it compares the seated name against the name we intended,
-- and we would have intended the wrong one. No gate in this pipeline can detect a uniformly
-- shifted source. Only reading the primary document can. (Same shape as the CivicPatch
-- off-by-one image defect.)
--
-- Source, read as a binary PDF rather than via any summariser:
--   https://www.fresnocountyca.gov/files/sharedassets/county/v/1/county-clerk-registrar-of-voters/
--     0_elected-officials/2025-01-06-county-officials.pdf   (Last Updated: 1/06/2025)
-- The county's own site 403s ordinary fetches; the file was retrieved by a same-origin fetch from
-- inside a browser session that already held the site's cookies.
--
-- ── TERM STARTS ────────────────────────────────────────────────────────────────────────────────
-- The ROV PDF prints "Begin & End Term Dates" of 01/02/2023 - 01/04/2027 for EVERY officer. That
-- is the CURRENT TERM, not occupancy. This wave records occupancy start -- when the person first
-- took the office and held it continuously -- so the PDF's begin date is used only where it is
-- also the occupancy start (Zanoni). The others are sourced separately:
--   Dictos            assumed 2011 (elected 2010)                     -> year precision
--   Garcia            assumed 2016, then sworn for a full term 1/7/19 -> year precision
--   Kus               assumed 2021                                    -> year precision
--   Smittcamp         elected June 2014, sworn January 2015           -> month precision
--   Zanoni            sworn 2023-01-02                                -> day precision
--   Cantwell-Copher   became Superintendent 2023-01-03                -> day precision
--
-- Garcia (2016) and Kus (2021) began in ODD years. CA county officers are elected in gubernatorial
-- years (2018, 2022, 2026), so an off-cycle start is necessarily an appointment to a vacancy, not
-- an election. how_started='appointed' for those two is read off the election calendar, not
-- guessed at. Their exact days are not published, hence year precision.
--
-- external_id: reserved county band -(62000000 + <3-digit county FIPS> * 1000 + seq). Migration
-- 1631 documents why the old 7-digit formula was abandoned -- it collided with the state-leader
-- band and, worse, with ITSELF (Alameda's shifted -6101001 is Sutter County's natural id). The
-- 8-digit reserved band is disjoint from every existing allocation; verified 0 collisions.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

-- ── RENUMBERED 1632 -> 1633 ───────────────────────────────────────────────────────────────────
-- This file was originally applied as 1632. A parallel session had already renumbered its own
-- Euless roster fix 1631 -> 1632 and pushed it first, so both files claimed 1632. Note that
-- `npm run check:migrations` did NOT catch this: it compares newly added files against
-- origin/master, so once both sides are pushed the collision is invisible to it.
--
-- Renumbering after apply means the number is already embedded in data in prod (CLAUDE.md warns
-- about exactly this), so the rewrite below repairs the 6 politicians + 6 office_terms rows this
-- migration wrote. Guarded and idempotent: it matches only this migration's own Fresno source
-- string and is a no-op once corrected.

BEGIN;

UPDATE essentials.politicians
   SET source = replace(source, 'migration 1632 — Fresno', 'migration 1633 — Fresno')
 WHERE source LIKE 'migration 1632 — Fresno%';

UPDATE essentials.office_terms
   SET source = replace(source, 'migration 1632 — Fresno', 'migration 1633 — Fresno')
 WHERE source LIKE 'migration 1632 — Fresno%';

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-Recorder',                          -62019001,'Paul Dictos','Paul','Dictos',NULL,'2011-01-01','year','elected'),
  ('Auditor-Controller/Treasurer-Tax Collector', -62019002,'Oscar J. Garcia','Oscar','Garcia','J','2016-01-01','year','appointed'),
  ('County Clerk',                               -62019003,'James A. Kus','James','Kus','A','2021-01-01','year','appointed'),
  ('District Attorney',                          -62019004,'Lisa A. Smittcamp','Lisa','Smittcamp','A','2015-01-01','month','elected'),
  ('Sheriff/Coroner/Public Administrator',       -62019005,'John J. Zanoni','John','Zanoni','J','2023-01-02','day','elected'),
  ('Superintendent of Schools',                  -62019006,'Michele Cantwell-Copher','Michele','Cantwell-Copher',NULL,'2023-01-03','day','elected');

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
SELECT 'Fresno County, California, US', 'County', 'CA', '06019'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06019' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019'
   AND g.geo_id='06019' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Fresno County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06019' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal = 'Fresno County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1633 — Fresno County ROV elected-offices roster PDF (updated 2025-01-06), read 2026-08-08',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal = 'Fresno County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019' AND o.title = r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id = r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1633 — Fresno County ROV elected-offices roster PDF (updated 2025-01-06), read 2026-08-08',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_chambers integer;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019';
  IF v_offices <> 6 THEN RAISE EXCEPTION 'Expected 6 Fresno offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 6 THEN RAISE EXCEPTION 'Expected 6 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06019'
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.title
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers
   WHERE name_formal = 'Fresno County Countywide Elected Officials';
  IF v_chambers <> 1 THEN RAISE EXCEPTION 'Expected 1 Fresno chamber, found %', v_chambers; END IF;

  -- No row may still carry the pre-renumber source string.
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE source LIKE 'migration 1632 — Fresno%')
     OR EXISTS (SELECT 1 FROM essentials.office_terms WHERE source LIKE 'migration 1632 — Fresno%') THEN
    RAISE EXCEPTION 'Rows still carry the pre-renumber "migration 1632 — Fresno" source string';
  END IF;
END $$;

COMMIT;
