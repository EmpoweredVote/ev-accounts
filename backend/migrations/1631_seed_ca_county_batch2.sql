-- 1631_seed_ca_county_batch2.sql
--
-- CA county wave, batch 2: San Bernardino, Santa Clara, Alameda, Sacramento.
-- 17 seats, 7.28M residents. Follows the pilot (migration 1630); same rules, same shape.
--
-- Roster first, office second: every office below is seated with a verified holder in this same
-- migration. Boards of Supervisors excluded (sub-county districts, polygons do not exist).
-- Sources are each county's own roster, fetched 2026-08-08:
--   San Bernardino  https://elections.sbcounty.gov/elected-officials-candidates/county/
--   Santa Clara     https://www.santaclaracounty.gov/government/elected-officials
--   Alameda         https://www.acgov.org/government/elected.htm
--   Sacramento      https://elections.saccounty.gov/.../list-of-elected-officials--county.html
--
-- Office counts are 5 / 3 / 6 / 3 -- four counties, four different shapes, again. San Bernardino
-- and Alameda elect a Superintendent of Schools; the other two do not. Sacramento elects only
-- three countywide officers (its Director of Finance is APPOINTED, so it is not seeded).
--
-- Web SEARCH returned Anne Marie Schubert as Sacramento DA -- she left office in January 2023.
-- The ROV list of record gives Thien Ho. As in the pilot, only the counties' own pages were used.
--
-- ── 🔴 THE external_id COLLISION THAT WOULD HAVE SEATED A STATE SENATOR ────────────────────────
-- The pilot's band was -(6000000 + <3-digit county FIPS> * 1000 + seq). For Alameda (FIPS 001)
-- that yields -6001001..-6001006, which lands INSIDE the v2.18 state-leader band already occupying
-- -6015201..-6000101. Those six ids are Megan Dahle, Mike McGuire, Christopher Cabaldon,
-- Marie Alvarado-Gil, Jerry McNerney and Roger Niello.
--
-- This would NOT have errored. The "create the politician unless external_id already exists" guard
-- is an IDEMPOTENCY check, not a collision check: it would have silently skipped creating the six
-- Alameda officials, and the seating step -- which looks the politician up BY external_id -- would
-- then have seated Megan Dahle as Alameda County Assessor. Every count-based gate would still have
-- passed, because counting offices and holders cannot see WHO is in the seat.
--
-- Two consequences, both load-bearing:
--   1. Counties whose FIPS lands in the state band (ccc <= 015) use -(6100000 + ccc*1000 + seq)
--      instead. Alameda is therefore -6101001..-6101006. Verified 0 collisions before writing.
--   2. The post-verify gate below asserts the seated person's NAME, per seat -- not just that some
--      holder exists. A count gate cannot catch a misattribution.
--
-- ── TERM STARTS ────────────────────────────────────────────────────────────────────────────────
-- Occupancy start, not current-term start. 5 of 17 did not begin in a statutory January:
--   Dicus         appointed 2021-07-16 when McMahon retired; elected 2022
--   Wynn          appointed 2017-06-25 (interim)
--   Jones Dickson appointed 2025-02-18 after Pamela Price was recalled
--   Gonzales      elected in a NOVEMBER 2024 SPECIAL election for the late Bob Dutton's term;
--                 sworn 2025-01-06 -- a statutory-January guess would have been 2 years wrong
--   Fligor        elected in a 2025-12-30 RUNOFF SPECIAL election after Larry Stone retired;
--                 sworn 2026-01-26 -- she has held the office for six months
-- And two started EARLY, before their elected terms, which a January default also misses:
--   Jonsen        appointed interim 2022-12-08 after Laurie Smith resigned; elected term Jan 2023
--   Cooper        sworn 2022-12-16 when Scott Jones left early
--
-- Precision is 'day' only where a source names the day. 'month' where sources conflict on the day
-- (Alejandre Jan 5 vs Jan 11 2015; Mason and Anderson Jan 1 vs statutory Jan 7 2019; Rosen and Ho).
-- 'year' where the source gives only a year (La, Wilk, Levy). No day is ever guessed.
--
-- Titles are the counties' own. Where the ROV table abbreviates and the department publishes a
-- fuller official title, the fuller one is used: San Bernardino "Assessor-Recorder-County Clerk"
-- (ROV table says "Assessor / Recorder") and Alameda "Auditor-Controller/Clerk-Recorder"
-- (roster says "Auditor/Controller").
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _cty (
  geo_id text, gov_name text, ch_formal text
) ON COMMIT DROP;

INSERT INTO _cty VALUES
  ('06071','San Bernardino County, California, US','San Bernardino County Countywide Elected Officials'),
  ('06085','Santa Clara County, California, US',   'Santa Clara County Countywide Elected Officials'),
  ('06001','Alameda County, California, US',       'Alameda County Countywide Elected Officials'),
  ('06067','Sacramento County, California, US',    'Sacramento County Countywide Elected Officials');

CREATE TEMP TABLE _seed (
  geo_id text, title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  -- San Bernardino -- 5
  ('06071','Assessor-Recorder-County Clerk',            -6071001,'Josie Gonzales','Josie','Gonzales',NULL,'2025-01-06','day','elected'),
  ('06071','Auditor-Controller/Treasurer/Tax Collector',-6071002,'Ensen Mason','Ensen','Mason',NULL,'2019-01-01','month','elected'),
  ('06071','County Superintendent of Schools',          -6071003,'Theodore Alejandre','Theodore','Alejandre',NULL,'2015-01-01','month','elected'),
  ('06071','District Attorney',                         -6071004,'Jason Anderson','Jason','Anderson',NULL,'2019-01-01','month','elected'),
  ('06071','Sheriff/Coroner/Public Administrator',      -6071005,'Shannon D. Dicus','Shannon','Dicus','D','2021-07-16','day','appointed'),
  -- Santa Clara -- 3
  ('06085','County Assessor',                           -6085001,'Neysa Fligor','Neysa','Fligor',NULL,'2026-01-26','day','elected'),
  ('06085','County Sheriff',                            -6085002,'Robert Jonsen','Robert','Jonsen',NULL,'2022-12-08','day','appointed'),
  ('06085','District Attorney',                         -6085003,'Jeffrey Rosen','Jeffrey','Rosen',NULL,'2011-01-01','month','elected'),
  -- Alameda -- 6  (shifted band: county FIPS 001 collides with the state-leader band)
  ('06001','Assessor',                                  -6101001,'Phong La','Phong','La',NULL,'2019-01-01','year','elected'),
  ('06001','Auditor-Controller/Clerk-Recorder',         -6101002,'Melissa Wilk','Melissa','Wilk',NULL,'2019-01-01','year','elected'),
  ('06001','District Attorney',                         -6101003,'Ursula Jones Dickson','Ursula','Jones Dickson',NULL,'2025-02-18','day','appointed'),
  ('06001','Sheriff/Coroner',                           -6101004,'Yesenia Sanchez','Yesenia','Sanchez',NULL,'2023-01-03','day','elected'),
  ('06001','Superintendent of Schools',                 -6101005,'Alysse Castro','Alysse','Castro',NULL,'2023-01-02','day','elected'),
  ('06001','Treasurer/Tax Collector',                   -6101006,'Henry C. Levy','Henry','Levy','C','2017-01-01','year','elected'),
  -- Sacramento -- 3
  ('06067','Assessor',                                  -6067001,'Christina Wynn','Christina','Wynn',NULL,'2017-06-25','day','appointed'),
  ('06067','District Attorney',                         -6067002,'Thien Ho','Thien','Ho',NULL,'2023-01-01','month','elected'),
  ('06067','Sheriff',                                   -6067003,'Jim Cooper','Jim','Cooper',NULL,'2022-12-16','day','elected');

-- 🔴 Pre-flight: refuse to run if any external_id is already taken by somebody else.
-- Without this, a collision is silently converted into a wrong person in a real seat.
DO $$
DECLARE v_bad text;
BEGIN
  SELECT string_agg(p.external_id::text || ' is already ' || p.full_name || ' (wanted ' || s.full_name || ')', '; ')
    INTO v_bad
    FROM _seed s JOIN essentials.politicians p ON p.external_id = s.ext_id
   WHERE p.full_name IS DISTINCT FROM s.full_name;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'external_id collision -- refusing to seed: %', v_bad;
  END IF;
END $$;

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT c.gov_name, 'County', 'CA', c.geo_id FROM _cty c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id = c.geo_id AND g.type = 'County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g, _cty c
 WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'ca' AND d.geo_id = c.geo_id
   AND g.geo_id = c.geo_id AND g.type = 'County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', c.ch_formal, g.id,
       (SELECT count(*) FROM _seed s WHERE s.geo_id = c.geo_id), 'full'
  FROM _cty c JOIN essentials.governments g ON g.geo_id = c.geo_id AND g.type = 'County'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.name_formal = c.ch_formal);

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1631 — ' || c.gov_name || ' official roster, fetched 2026-08-08', true, true
  FROM _seed s JOIN _cty c ON c.geo_id = s.geo_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN _cty c ON c.geo_id = s.geo_id
  JOIN essentials.chambers ch ON ch.name_formal = c.ch_formal
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id = s.geo_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT s.*, c.gov_name FROM _seed s JOIN _cty c ON c.geo_id = s.geo_id LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id = r.geo_id AND o.title = r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for % / %', r.geo_id, r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id = r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for % (%)', r.full_name, r.ext_id; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1631 — ' || r.gov_name || ' official roster, fetched 2026-08-08',
      r.how_started, r.precision);
  END LOOP;
END $$;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices integer; v_seated integer; v_percounty text; v_chambers integer; v_wrong text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id IN ('06071','06085','06001','06067');
  IF v_offices <> 17 THEN RAISE EXCEPTION 'Expected 17 offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id IN ('06071','06085','06001','06067')
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 17 THEN RAISE EXCEPTION 'Expected 17 seated holders, found %', v_seated; END IF;

  -- 🔴 IDENTITY GATE. A count gate cannot see WHO is in the seat; this is what would have caught
  -- Megan Dahle being seated as Alameda County Assessor.
  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT d.label || ' / ' || o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id = s.geo_id
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.title
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN
    RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong;
  END IF;

  SELECT string_agg(y.geo_id || '=' || y.n, ' ' ORDER BY y.geo_id) INTO v_percounty
    FROM (SELECT d.geo_id, count(*) AS n
            FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.district_type='COUNTY' AND lower(d.state)='ca'
             AND d.geo_id IN ('06071','06085','06001','06067')
           GROUP BY d.geo_id) y;
  IF v_percounty <> '06001=6 06067=3 06071=5 06085=3' THEN
    RAISE EXCEPTION 'Per-county counts wrong -- expected "06001=6 06067=3 06071=5 06085=3", got "%"', v_percounty;
  END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers
   WHERE name_formal IN ('San Bernardino County Countywide Elected Officials',
                         'Santa Clara County Countywide Elected Officials',
                         'Alameda County Countywide Elected Officials',
                         'Sacramento County Countywide Elected Officials');
  IF v_chambers <> 4 THEN RAISE EXCEPTION 'Expected 4 chambers, found %', v_chambers; END IF;
END $$;

COMMIT;
