-- 1656_seed_ca_county_monterey.sql
--
-- CA county wave: Monterey County. 5 countywide elected officials, 430,723 residents.
-- Wave total: 19 counties, 95 seats, 24.44M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- countyofmonterey.gov answers plain curl with a 403 (WAF) but renders fully in Playwright, and a
-- same-origin fetch() from inside the page reaches every countyofmonterey.gov path. mcso.
-- countyofmonterey.gov redirects to the same host, so the Sheriff's pages are same-origin too.
--
--   Office set: the Elections division's "Elected Officials List" -> **County Offices** page,
--     /government/departments-a-h/elections/candidates/election-calendar/elected-officials-county-offices/
--     which prints, per office, the holder, TERM LENGTH and NEXT ELECTION date.
--   Results:   the certified "County of Monterey Final Official Report" for 2026-06-02
--     (published 2026-06-26), /government/departments-a-h/elections/election-results
--   Holders:   each office's own department page, read 2026-08-10.
--
-- ── 🔴🔴 THE JUNE 2026 WINNER ALREADY HOLDS THE AUDITOR-CONTROLLER SEAT. ────────────────────────
-- ── THIS IS THE EXACT INVERSE OF THE TRAP GUARDED AGAINST IN SANTA BARBARA (migration 1652). ────
-- The county's own elected-officials roster still names RUPA SHAH as Auditor/Controller. She is
-- gone. The Auditor-Controller's bios page says, in the county's words:
--   "Enedina was appointed Auditor-Controller on July 7, 2026, by the County of Monterey Board of
--    Supervisors, following the June 2026 election in which she was elected to begin her first
--    four year term in January 2027."
-- So ENEDINA GARCIA is the correct holder TODAY -- she won in June AND was separately appointed in
-- July to finish Shah's term after Shah retired early. Seeding Shah from the roster would have been
-- wrong; but so would mechanically applying migration 1652's rule that a 2026 winner does not take
-- office until January. **"The winner is not yet in office" is a DEFAULT, not a rule.** It is the
-- same election-or-removal question as San Mateo (1642) and Solano (1650), asked in the opposite
-- direction: did the seat fall vacant early? Note also that the two county sources DISAGREE, and
-- the winner is the newer, more specific one -- a bios page stating a dated Board action beats a
-- roster page that merely lists a name.
--
-- 🔴 AND IT IS NOT THE ONLY ONE: JAKE STROUD IS ALSO A BOARD APPOINTEE. His department's page says
-- he "was unanimously appointed by the Monterey County Board of Supervisors and began serving on
-- December 30, 2025." He then won the June 2026 election unopposed, so he continues. **Two of
-- Monterey's five countywide officers reached office by mid-term appointment within the last eight
-- months** -- this county turns over far faster than any other in the wave, and its own roster page
-- had not caught up with either change.
--
-- ── 🔴 AB 759, NINTH COUNTY -- AND THE CLEAREST STATEMENT OF THE MECHANISM YET ──────────────────
-- The County Offices roster prints, as data, for both the District Attorney and the Sheriff/Coroner:
--   **Term Length: 6    Next Election: 03/07/2028**
-- -- both the six-year term AND the presidential-primary date, in the same table where every other
-- county office shows "Term Length: 4". Stanislaus (1643) showed the term-expiry column, Solano
-- (1650) cited the bill by name; Monterey prints the whole mechanism. The certified June 2026
-- results contain no DA and no Sheriff contest, as expected.
--
-- ── 🔴 THE SUPERINTENDENT OF SCHOOLS IS EXCLUDED, ON THE STRONGEST FORM OF THE DISCRIMINATOR YET ─
-- Monterey County Superintendent of Schools WAS on the June 2026 county ballot (Dan Burns 56.05%
-- def. Ralph Gómez Porras 43.95%). It is still not seeded, and here the county's own elections
-- directory makes the distinction for us: its top-level sections are County Offices / School
-- Districts / **Superintendents & Board of Education Members** / Community Colleges / Cities /
-- Special Districts. The Superintendent is filed OUTSIDE "County Offices" by the county itself.
-- Same outcome as Kern (1638), Riverside (1630), Tulare (1645), Solano (1650), Santa Barbara (1652).
--
-- ── ONE SEAT'S 2027 SUCCESSION, AND WHY NOTHING NEEDS A "DO NOT SEAT EARLY" GUARD HERE ─────────
-- Certified 2026-06-02: Assessor-County Clerk/Recorder MARINA CAMACHO 60,084 (100.00%, unopposed)
-- and Treasurer/Tax Collector JAKE STROUD 61,399 (100.00%, unopposed) -- both incumbents, both
-- continue. Auditor/Controller ENEDINA GARCIA 38,270 (54.99%) def. BURCU MOUSA 31,326 (45.01%) --
-- and Garcia already holds the seat, as above. So every June 2026 winner in this county is already
-- the seated holder, and **Monterey needs no January 2027 re-check.**
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Garcia   2026-07-07  day    county's Auditor-Controller bios page, quoted above.
--   Camacho  2022-12-31  day    Board of Supervisors File **APP 22-234**, meeting 2022-12-07:
--                               "Consider the appointment of Xochitl Marina Camacho as interim
--                               Assessor-Clerk-Recorder effective December 31, 2022, at 12:01a.m."
--                               -- bridging Stephen Vagnini's retirement to her formal swearing-in
--                               on 2023-01-03. Occupancy runs from the INTERIM appointment, not
--                               from the elected term. (monterey.legistar.com, File APP 22-234.)
--   Stroud   2025-12-30  day    his department's own about-us page, quoted above.
--   Nieto    2022-12-30  day    "the first Latina Sheriff in the history of the State of California
--                               sworn in on December 30, 2022" -- her own office's executive-team
--                               page.
--   Pacioni  2019-01-01  month  elected 2018 unopposed to succeed the retiring Dean Flippo and
--                               sworn in as the county's first woman DA in January 2019. No county
--                               document names the day.
--
-- 🔴 A NOTE ON DAY-vs-MONTH PRECISION FOR END-OF-DECEMBER STARTS. Monterey seats officials in the
-- last days of December when a predecessor retires early -- Camacho 12-31 and Nieto 12-30, both in
-- 2022 -- rather than at the statutory start (first Monday after January 1). Contrast Solano's
-- Zook (migration 1650), whose 2022-12-30 oath is reported only by a NEWSPAPER and is therefore
-- recorded at month precision against the statutory January start. The rule this wave now follows:
-- **when the officeholder's own county publishes a specific date, record it at day precision; when
-- only press reports it, fall back to the statutory month.**
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- The stored value "http://www.co.monterey.ca.us" was classified 403-maybe-WAF in the 2026-08-09
-- sweep. It is neither dead nor wrong: it 301s to countyofmonterey.gov, which answers 403 to curl
-- and renders fine in a browser -- exactly the class that file warns not to bulk-replace. Repointed
-- to the live host https://www.countyofmonterey.gov/.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62053001..5.
-- Pre-flight: 0 external_id collisions, and no politician in the corpus matches any of these five
-- on first+last name. (The only chamber matching 'Monterey%' is **Monterey Park City Council** --
-- a different city, in Los Angeles County. This migration keys on the full name_formal, so it
-- cannot collide with it.)
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-County Clerk/Recorder', -62053001,'Xochitl Marina Camacho','Xochitl','Camacho',NULL,'2022-12-31','day','appointed'),
  ('Auditor/Controller',             -62053002,'Enedina Garcia','Enedina','Garcia',NULL,'2026-07-07','day','appointed'),
  ('District Attorney',              -62053003,'Jeannine M. Pacioni','Jeannine','Pacioni','M','2019-01-01','month','elected'),
  ('Sheriff/Coroner',                -62053004,'Tina M. Nieto','Tina','Nieto','M','2022-12-30','day','elected'),
  ('Treasurer/Tax Collector',        -62053005,'Jake Stroud','Jake','Stroud',NULL,'2025-12-30','day','appointed');

-- 🔴 RENUMBER REPAIR (third time this wave -- 1641, 1650, and now this). Written, dry-run and
-- APPLIED as 1655, then renumbered when a parallel session in this shared worktree landed
-- 1655_retire_phantom_districtless_us_house_offices.sql. The number is only a filename label to a
-- human, but it is also embedded in `source` text ALREADY WRITTEN TO PROD, so repoint those rows.
-- Guarded and idempotent; a no-op on a fresh database. **Both collisions this week came from local
-- files that were not yet on origin/master**, which is why `check:migrations` has to be re-run
-- immediately before committing, not only when the file is written.
UPDATE essentials.politicians
   SET source = replace(source, 'migration 1655 — Monterey', 'migration 1656 — Monterey')
 WHERE source LIKE 'migration 1655 — Monterey%';

UPDATE essentials.office_terms
   SET source = replace(source, 'migration 1655 — Monterey', 'migration 1656 — Monterey')
 WHERE source LIKE 'migration 1655 — Monterey%';

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
SELECT 'Monterey County, California, US', 'County', 'CA', '06053'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06053' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
   AND g.geo_id='06053' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.countyofmonterey.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
   AND d.official_web_url IS DISTINCT FROM 'https://www.countyofmonterey.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Monterey County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06053' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Monterey County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1656 — Monterey County Elections "Elected Officials List / County Offices" + certified 2026-06-02 Final Official Report + department pages + BoS File APP 22-234, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Monterey County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1656 — Monterey County Elections "Elected Officials List / County Offices" + certified 2026-06-02 Final Official Report + department pages + BoS File APP 22-234, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Monterey offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Rupa Shah retired and Enedina Garcia was appointed to the seat on 2026-07-07. The county's own
  -- elected-officials roster still lists Shah; fail if that stale value is ever seeded here.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.office_current_holder och ON och.office_id=o.id
               JOIN essentials.politicians p ON p.id=och.politician_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
                AND p.last_name ILIKE 'Shah') THEN
    RAISE EXCEPTION 'Rupa Shah is seated as Monterey Auditor/Controller -- she retired; see migration 1656 header';
  END IF;

  -- The Superintendent of Schools is filed outside "County Offices" by the county -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Monterey County -- see migration 1656 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053'
     AND g.geo_id='06053' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Monterey district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06053';
  IF v_url IS DISTINCT FROM 'https://www.countyofmonterey.gov/' THEN
    RAISE EXCEPTION 'Monterey official_web_url is %, expected https://www.countyofmonterey.gov/', v_url;
  END IF;
END $$;

COMMIT;
