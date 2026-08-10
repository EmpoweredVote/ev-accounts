-- 1652_seed_ca_county_santa_barbara.sql
--
-- CA county wave: Santa Barbara County. 5 countywide elected officials, 441,257 residents.
-- Wave total: 18 counties, 90 seats, 24.01M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- countyofsb.org is not bot-walled, but it is a CivicPlus site that renders department pages
-- CLIENT-SIDE: plain curl returns the shell with no officeholder names in it. Every countyofsb.org
-- page below was read in Playwright. da.countyofsb.org and sbsheriff.org are ordinary sites and
-- curl works on them.
--
--   Office set + winners: the certified Statement of Vote for 2026-06-02, published as HTML at
--     https://sbcvote.com/elections/results/2026june02/results-1.htm
--     (linked from /acr-elections-election-results as "Certified Election Results Summary").
--   Holders: each office's own department page, read 2026-08-10 --
--     /ac-auditor-controller · /acr-clerk-recorder-assessor-elections ·
--     /tt-treasurer-tax-collector-public-administrator · da.countyofsb.org/meet-your-da ·
--     sbsheriff.org/command-and-divisions/sheriff-bill-brown
--
-- 🔴 THE ACFR TRICK FAILS HERE -- CHECK THE TABLE OF CONTENTS BEFORE PLANNING AROUND IT. Santa
-- Barbara publishes a full 17 MB ACFR (FY ended 2025-06-30) whose Introductory Section contains
-- ONLY a letter of transmittal: no "Listing of Principal Officials", no organizational chart. That
-- is the San Joaquin shape (migration 1641), not the Kern/Ventura/Tulare/Solano shape. The
-- substitute is the Registrar of Voters, as it was for San Joaquin.
--
-- ── 🔴🔴 THREE OF THE FIVE SEATS TURN OVER IN JANUARY 2027, AND TWO SITTING OFFICERS WERE ───────
-- ── DEFEATED AT THE POLLS. THIS IS THE FIRST COUNTY IN THE WAVE WHERE THAT HAPPENED. ───────────
-- Certified 2026-06-02 results:
--   Auditor-Controller            KYLE SLATTERY   48,094 (51.72%)  def. BETSY M. SCHAFFER 44,569 (47.93%)
--   Clerk, Recorder and Assessor  MELINDA GREENE  57,706 (60.22%)  def. JOSEPH E. HOLLAND 37,829 (39.48%)
--   Treasurer-Tax Collector-
--     Public Administrator        KIMBERLY A. TESORO 74,644 (98.49%), sole candidate
-- **The people seeded here are the CURRENT holders, who serve through December 2026** -- Schaffer,
-- Holland and Hagen. Slattery, Greene and Tesoro are NOT seeded; three named guards below fail if
-- any of them is seated early. **Re-check this county in January 2027 -- it needs the largest
-- single correction of any county in this wave.**
--   Every earlier county's turnover was a retirement or an unopposed succession. Here two
--   incumbents ran and LOST, which means the losing incumbent is still the correct holder today.
--   A roster scraped after the election and read carelessly would seed the WINNERS eight months
--   early; a roster read before it would miss nothing. Verified the other way round: Schaffer and
--   Holland are still named on their own department pages today.
--   Tesoro is the fourth "deputy succeeds a departing incumbent" case in the wave (Contra Costa
--   1637, Sonoma 1644, Solano 1650): she has been Assistant Treasurer-Tax Collector for 13 years
--   and Hagen, who did not run, retires at the end of 2026.
--
-- 🔴 AB 759, EIGHTH COUNTY: no District Attorney and no Sheriff contest on the certified 2026
-- ballot. Both are on the presidential cycle, next elected 2028.
--
-- 🔴 THE SUPERINTENDENT OF SCHOOLS IS ON THE COUNTY BALLOT AND IS NOT SEEDED (Susan C. Salcido,
-- 96.01%). Same rule as Kern (1638), Riverside (1630), Tulare (1645) and Solano (1650): the county
-- ballot is not the discriminator, the county's own government roster is. Here that roster is the
-- department directory at /cosb-departments, which lists 28 departments and NO office of education
-- -- the Santa Barbara County Education Office is a separate entity (sbceo.org). Note this county
-- gives no ACFR officials list to cross-check against, so the department directory carries it
-- alone. A guard below fails if a Superintendent office is ever created here.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Brown     2007-01-09  day    "Bill Brown has served as Santa Barbara County's Sheriff-Coroner
--                                since January 9, 2007. He was first elected to that constitutional
--                                office on November 7, 2006, and re-elected ... to his present
--                                fifth term in June, 2022" -- his own office's bio page.
--   Savrnoch  2023-01-02  day    "John Savrnoch was elected District Attorney of Santa Barbara
--                                County in June 2022 and assumed office on January 2nd, 2023" --
--                                his own office's bio page.
--   Schaffer  2019-01-01  month  elected June 2018 to succeed the retiring Theo Fallati; took
--                                office January 2019. No county document names the day.
--   Hagen     2011-01-01  year   "Hagen was first elected to the position in 2010 from a field of
--                                four and ran unopposed for three more terms" and is retiring "at
--                                the end of the year ... after nearly 16 years in the role"
--                                (Noozhawk, 2026-03-31). January 2011 to December 2026 is 15 years
--                                11 months, which is what "nearly 16 years" measures; a mid-2010
--                                start would make it more than 16. Year precision -- no county
--                                document read.
--   Holland   2003-01-01  year   🔴 THE WEAKEST ROW IN THIS MIGRATION, AND DELIBERATELY COARSE.
--                                Two accounts agree he was "first elected in March 2002", but one
--                                says he "has served since 2002" while the term arithmetic in the
--                                same article ("seeking his sixth term") implies a 2007 start, and
--                                neither is reconcilable with the other. A county officer elected
--                                at a regular March 2002 primary takes office in January 2003, so
--                                that is what is recorded, at YEAR precision. If a county primary
--                                document ever shows he filled an unexpired term in 2002, correct
--                                this row. Do not sharpen it on the strength of the news accounts.
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- The stored value "http://www.countyofsb.org" was classified OK in the 2026-08-09 sweep -- it
-- resolves to the county on the same host. Normalised to https, guarded on end state.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62083001..5.
-- Pre-flight: 0 external_id collisions, and no politician anywhere in the corpus matches any of
-- these five on first+last name. The surname sweep surfaced only unrelated people (Byron Holland,
-- Brent Hagenbuch, Jennifer White Holland) and several cal_access_discovery COMMITTEE rows, which
-- are not people -- including "HOLLAND FOR CLERK-RECORDER-ASSESSOR 2014, JOE", this officeholder's
-- own campaign committee. Nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Auditor-Controller',                           -62083001,'Betsy M. Schaffer','Betsy','Schaffer','M','2019-01-01','month','elected'),
  ('Clerk, Recorder and Assessor',                 -62083002,'Joseph E. Holland','Joseph','Holland','E','2003-01-01','year','elected'),
  ('District Attorney',                            -62083003,'John T. Savrnoch','John','Savrnoch','T','2023-01-02','day','elected'),
  ('Sheriff-Coroner',                              -62083004,'Bill Brown','Bill','Brown',NULL,'2007-01-09','day','elected'),
  ('Treasurer-Tax Collector-Public Administrator', -62083005,'Harry E. Hagen','Harry','Hagen','E','2011-01-01','year','elected');

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
SELECT 'Santa Barbara County, California, US', 'County', 'CA', '06083'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06083' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
   AND g.geo_id='06083' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.countyofsb.org/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
   AND d.official_web_url IS DISTINCT FROM 'https://www.countyofsb.org/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Santa Barbara County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06083' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Santa Barbara County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1652 — Santa Barbara County certified 2026-06-02 Statement of Vote + department pages, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Santa Barbara County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1652 — Santa Barbara County certified 2026-06-02 Statement of Vote + department pages, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text; v_early text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Santa Barbara offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- The three 2026 winners do not take office until January 2027. Two of them BEAT the incumbent
  -- who is correctly seated here, so this is the guard that matters most in this county.
  SELECT string_agg(p.full_name, ', ') INTO v_early
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
     AND (p.last_name ILIKE 'Slattery' OR p.last_name ILIKE 'Greene' OR p.last_name ILIKE 'Tesoro');
  IF v_early IS NOT NULL THEN
    RAISE EXCEPTION '2026 winner(s) seated in Santa Barbara before January 2027: %', v_early;
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Santa Barbara County -- see migration 1652 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083'
     AND g.geo_id='06083' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Santa Barbara district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06083';
  IF v_url IS DISTINCT FROM 'https://www.countyofsb.org/' THEN
    RAISE EXCEPTION 'Santa Barbara official_web_url is %, expected https://www.countyofsb.org/', v_url;
  END IF;
END $$;

COMMIT;
