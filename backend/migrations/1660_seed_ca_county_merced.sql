-- 1660_seed_ca_county_merced.sql
--
-- CA county wave: Merced County. 5 countywide elected officials, 291,920 residents.
-- Wave total: 21 counties, 106 seats, 25.16M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- countyofmerced.com answers plain curl -- no WAF, no client-side rendering. Every fact below is a
-- county document:
--
--   Office set:   the county's FY2025 ACFR "Directory of County Officials, as of June 30, 2025"
--                 (printed p. X = PDF p. 17 of Archive.aspx?ADID=967) and its Organizational Chart
--                 on the facing page; cross-checked against the LIVE org chart PDF
--                 (DocumentCenter/View/1377, "Effective July 24, 2026") and the staff directory.
--   Holders:      the same three documents, all naming the same five people, read 2026-08-09.
--   Ballot names: the certified June 2, 2026 results (results.enr.clarityelections.com/CA/Merced/
--                 126388) and the ROV's "List of Officials" incumbent report, printed 2026-06-05
--                 (DocumentCenter/View/13620).
--   Start dates:  Board of Supervisors Summary Action Minutes -- see the table below.
--
-- 🔴 THE BOARD MINUTES ARE AT A PREDICTABLE URL AND GO BACK TO 2000. Merced publishes every
-- meeting's minutes at web2.co.merced.ca.us/pdfs/bos/sam/<YYYY>/<MMDDYYYY>.pdf (2010 and earlier:
-- .../pdfs/<YYYY>sam/<MMDDYYYY>.pdf), indexed by a "Board Archive <year>" page per year. Four of
-- the five start dates below came out of that channel and nowhere else. It is the same class as
-- Monterey's Legistar (1656) and Placer's DocumentCenter agendas (1658), but complete back to 2000
-- and grep-able -- the cheapest primary source for appointment dates this wave has found.
--
-- ── 🔴🔴 FOUR OF FIVE REACHED OFFICE BY MID-TERM BOARD APPOINTMENT ────────────────────────────
-- The highest appointment rate in the wave (Placer, 1658, was three of six). Only the District
-- Attorney started at a statutory January date. Every one of the four would have been recorded
-- wrongly by the statutory rule, and the error runs in BOTH directions:
--
--   Cardella-Presto  three months EARLY of the January-after-election date I would have assumed;
--   Warnke, May, Adams  each seated in LATE DECEMBER, before the January term they had won.
--
-- 🔴 MERCED SEATS OFFICIALS IN LATE DECEMBER WHEN A PREDECESSOR LEAVES EARLY -- the same habit
-- Monterey showed (1656: Camacho 12-31, Nieto 12-30). Here: Adams 12-14, May 12-21, Warnke 12-27.
-- Each is a specific date in the county's own minutes, so each is DAY precision under the rule
-- adopted in 1656 (county publishes a date -> day; only press reports an oath -> statutory month).
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Adams            2002-12-14  day  appointed. BoS minutes 2002-12-03, item 47: "Appoint Karen D.
--                                     Adams, Treasurer-Tax Collector and M. Stephen Jones,
--                                     Auditor-Controller, Recorder, Clerk **for the unexpired terms
--                                     of Bill W. Smith and James L. Ball** effective December 14,
--                                     2002." Her own county bio gives no date at all; its only
--                                     hint is "MCERA Trustee 2002 through Present" (the Treasurer
--                                     is an ex officio trustee), which is a corroborating year and
--                                     not a source for the day.
--   Cardella-Presto  2008-10-06  day  appointed. BoS minutes 2008-09-02, item 50: the CEO "reviews
--                                     the Staff Report and the process for filling **the unexpired
--                                     term** of the Auditor/Controller/Recorder/Clerk advising the
--                                     recommendation to the Board is Lisa Cardella-Presto" -> "the
--                                     Board appoints Lisa Cardella-Presto as the Auditor-Controller/
--                                     Recorder/Clerk Designee and approves Elected and 'A' Level
--                                     Benefits **effective October 6, 2008**." 🔴 She succeeded
--                                     M. Stephen Jones, the man appointed alongside Adams in 2002.
--                                     A statutory reading (elected June 2008 -> January 5, 2009)
--                                     would be three months late AND wrong about how_started.
--   Warnke           2014-12-27  day  appointed. BoS minutes 2014-12-16, item 26: "(1) Approve the
--                                     appointment of Vernon H. Warnke as the Sheriff/Coroner
--                                     effective December 27, 2014 ... (5) Approve the appointment
--                                     of Thomas Cavallero to return to work" as a retired annuitant
--                                     from 2014-12-29. Warnke had already WON the June 2014
--                                     election; Cavallero (himself appointed when Mark Pazin left
--                                     in 2013) retired, so the Board seated the sheriff-elect nine
--                                     days early. how_started is 'appointed' because the Board's
--                                     action is what put him in the seat on that date.
--   May              2020-12-21  day  appointed. BoS minutes 2020-12-08, item 32: "1) Change the
--                                     classification title only from Assessor/Recorder/Clerk/ROV to
--                                     Assessor/Recorder/Clerk ... 2) Approve the appointment of
--                                     Matthew May as the Assessor/Recorder/Clerk **effective
--                                     December 21, 2020**", succeeding the retiring Barbara J.
--                                     Levey. He was subsequently elected in June 2022.
--                                     🔴 TWO PRESS ACCOUNTS DISAGREE WITH THE COUNTY AND WITH EACH
--                                     OTHER -- one gives December 28, 2020, another (a 2022
--                                     campaign profile) says he succeeded Levey "a year ago in
--                                     January". The minutes settle it. Same lesson as Ventura's
--                                     Nasarenko (1639) and Placer's Woo (1658).
--   Silveira         2023-01-02  day  elected. The only statutory start of the five. The ROV's
--                                     incumbent list prints her term as 1/2/2023 to 1/8/2029, and
--                                     a sweep of every BoS meeting from July 2022 through December
--                                     2022 found no District Attorney appointment, vacancy or
--                                     resignation -- so she was not seated early, unlike her four
--                                     colleagues. She succeeded Kimberly Lewis, who is named in the
--                                     FY2022 ACFR as of 2022-06-30.
--
-- ── 🔴 THE OFFICE SET IS FIVE, AND THREE COUNTY DOCUMENTS SPELL THE TITLES THREE WAYS ─────────
-- The FY2025 ACFR's transmittal letter says the county "has five elected department directors
-- responsible for the offices of the Assessor-Recorder, Auditor-Controller, District Attorney,
-- Sheriff-Coroner, and Treasurer-Tax Collector" -- and then its own Directory calls the first one
-- "Assessor-Recorder-Clerk" while the org chart on the facing page calls it "Assessor/Recorder/
-- County Clerk". The certified ballot and the live staff directory both say **Assessor-Clerk-
-- Recorder**, and that is the title used here, on the San Mateo rule (1642): the certified ballot
-- name wins. Likewise the ACFR calls the DA "District Attorney-Public Administrator" (the Public
-- Administrator duty is folded into the office) while the ballot, the ROV roster and the staff
-- directory all say "District Attorney".
--
-- ── 🔴 AB 759, ELEVENTH COUNTY ────────────────────────────────────────────────────────────────
-- The certified June 2026 contest list is County Superintendent of Schools, County Supervisor
-- District 3, County Supervisor District 5, Assessor-Clerk-Recorder, Auditor-Controller and
-- Treasurer-Tax Collector -- no District Attorney and no Sheriff. The ROV's incumbent list states
-- the same thing from the other side: the DA and the Sheriff-Coroner are the only two county rows
-- whose printed term runs to **1/8/2029**; the other three end 1/4/2027.
--
-- ── 🔴 NO JANUARY 2027 TURNOVER ───────────────────────────────────────────────────────────────
-- All three county contests were won by their own incumbents against write-ins only: May 35,420
-- (98.45%), Cardella-Presto 35,098 (98.26%), Adams 35,948 (98.19%). Merced needs no January 2027
-- re-check -- the fourth such county, after Tulare (1645), Monterey (1656) and Placer (1658).
--
-- ── 🔴 SUPERINTENDENT OF SCHOOLS ON THE BALLOT, NOT SEEDED ────────────────────────────────────
-- County Superintendent of Schools was a four-way contest in June 2026 (Lopez 31.26%, Boyenga
-- 29.54%, Heupel 27.58%, Velarde 11.27% -- no majority, so it advances to November). Excluded, as
-- in Kern (1638), Riverside (1630), Tulare (1645), Solano (1650), Santa Barbara (1652), Monterey
-- (1656) and Placer (1658). Merced gives the strongest form of the discriminator yet: the ACFR's
-- Directory lists five Elected officials and eighteen Appointed ones and no Superintendent in
-- either column, and the county's 100-plus-entry staff directory has no Office of Education. The
-- Registrar of Voters is APPOINTED here (Melvin Levey, under the ACFR's Appointed heading).
--
-- ── 🔴 A HOMONYM SITS ON THE BOARD OF SUPERVISORS ─────────────────────────────────────────────
-- District Attorney **Nicole** Silveira and Supervisor **Scott** Silveira are different people, and
-- the supervisor's name is all over the minutes this migration reads. Same shape as the Stanislaus
-- "District Attorney Peterson" trap (1643): a name-shaped match over a county document finds the
-- wrong Silveira. The per-seat identity gate below compares FULL names, not surnames.
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- Stored "http://www.co.merced.ca.us" 301s to https://www.countyofmerced.com/ -- stale rather than
-- dead, the Ventura shape (1639). Repointed to the live host and guarded on end state.
--
-- 🔴 geo_id 06047 IS SHARED with **Assembly District 47** (district_type STATE_LOWER, state 'CA').
-- Every predicate below is scoped by district_type; an unscoped write would land on the Assembly
-- district and report success.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62047001..5.
-- Pre-flight: 0 external_id collisions; no politician in the corpus matches any of these five on
-- first+last name (only ALLCAPS cal_access_discovery committee rows, e.g. "WARNKE SHERIFF/CORONER
-- 2014, COMMITTEE TO ELECT VERN" and "SILVEIRA FOR DISTRICT ATTORNEY 2022", which are not people).
-- No pre-existing Merced chamber, government row or office.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.
-- Board of Supervisors NOT seeded: CA supervisors are elected by sub-county district and those
-- polygons do not exist, so seating them would manufacture unreachable officeholders.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text, pref text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-Clerk-Recorder', -62047001,'Matt H. May',          'Matt',  'May',            'H', NULL,  '2020-12-21','day','appointed'),
  ('Auditor-Controller',      -62047002,'Lisa Cardella-Presto', 'Lisa',  'Cardella-Presto','E', NULL,  '2008-10-06','day','appointed'),
  ('District Attorney',       -62047003,'Nicole Silveira',      'Nicole','Silveira',       'A', NULL,  '2023-01-02','day','elected'),
  ('Sheriff-Coroner',         -62047004,'Vernon H. Warnke',     'Vernon','Warnke',         'H','Vern', '2014-12-27','day','appointed'),
  ('Treasurer-Tax Collector', -62047005,'Karen D. Adams',       'Karen', 'Adams',          'D', NULL,  '2002-12-14','day','appointed');

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
SELECT 'Merced County, California, US', 'County', 'CA', '06047'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06047' AND g.type='County');

-- Scoped by district_type: geo_id 06047 is also Assembly District 47.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
   AND g.geo_id='06047' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.countyofmerced.com/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
   AND d.official_web_url IS DISTINCT FROM 'https://www.countyofmerced.com/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Merced County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06047' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Merced County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, preferred_name, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid, s.pref,
       'migration 1660 — Merced County FY2025 ACFR Directory of County Officials + county org chart eff. 2026-07-24 + staff directory + certified 2026-06-02 results + BoS minutes 2002-12-03/2008-09-02/2014-12-16/2020-12-08, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Merced County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1660 — Merced County FY2025 ACFR Directory of County Officials + county org chart eff. 2026-07-24 + staff directory + certified 2026-06-02 results + BoS minutes 2002-12-03/2008-09-02/2014-12-16/2020-12-08, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text; v_stale text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Merced offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  -- Counting cannot see WHO is in a seat. Compare FULL names -- a surname match would confuse
  -- District Attorney Nicole Silveira with Supervisor Scott Silveira.
  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Four of five predecessors left mid-term. Fail if a stale roster ever seats one of them here.
  SELECT string_agg(p.full_name, ', ') INTO v_stale
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
     AND (p.last_name ILIKE 'Levey' OR p.last_name ILIKE 'Cavallero'
          OR (p.last_name ILIKE 'Jones'  AND p.first_name ILIKE 'M%Stephen%')
          OR (p.last_name ILIKE 'Lewis'  AND p.first_name ILIKE 'Kimberly%')
          OR (p.last_name ILIKE 'Smith'  AND p.first_name ILIKE 'Bill%'));
  IF v_stale IS NOT NULL THEN
    RAISE EXCEPTION 'A departed Merced officeholder is seated (%) -- see migration 1660 header', v_stale;
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Merced County -- see migration 1660 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047'
     AND g.geo_id='06047' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Merced district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06047';
  IF v_url IS DISTINCT FROM 'https://www.countyofmerced.com/' THEN
    RAISE EXCEPTION 'Merced official_web_url is %, expected https://www.countyofmerced.com/', v_url;
  END IF;
END $$;

COMMIT;
