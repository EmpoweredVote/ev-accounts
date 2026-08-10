-- 1663_seed_ca_county_santa_cruz.sql
--
-- CA county wave: Santa Cruz County. 5 countywide elected officials, 261,547 residents.
-- Wave total: 23 counties, 116 seats, 25.70M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- santacruzcountyca.gov answers plain curl. Everything below is a county document, read 2026-08-10:
--
--   Office set:   the FY2024-25 ACFR "Directory of Public Officials", printed p. ix = PDF p. 17 of
--                 /Portals/0/County/auditor/acfr_2025/SCC_ACFR_FINAL_FY25.pdf -- five county
--                 Elected Officers and fifteen Appointed Officers.
--   Titles:       the certified June 2026 "Official Results" (updated 6/26/2026) for the three
--                 seats on that ballot, and the certified June 2022 results for the DA and the
--                 Sheriff. Both agree with the ACFR line for line.
--   Holders:      each office's own department site, all five current today.
--   Start dates:  Board of Supervisors minutes and agenda-item memos -- see below.
--
-- ── 🔴 THREE MINUTES PORTALS, AND ALL THREE WERE NEEDED ───────────────────────────────────────
-- Santa Cruz has moved systems twice, so the Board record is split three ways. Every one of the
-- four appointment dates below came from a different era, so the whole chain had to be walked:
--   * 2025 -> present: PrimeGov. `santacruzcountyca.primegov.com/api/v2/PublicPortal/
--     ListArchivedMeetings?year=YYYY` returns JSON with a documentList per meeting; fetch the
--     document with `/Public/CompiledDocument?compiledMeetingDocumentFileId=<id>` (NOT
--     `meetingTemplateId`, which answers "Document Not Found", and NOT `/Portal/viewer`, which is
--     an Accusoft JS shell with no text).
--   * Feb 2016 - Dec 2024: IQM2/MinuteTraq. `santacruzcountyca.iqm2.com/Citizens/
--     Calendar.aspx?From=1/1/YYYY&To=12/31/YYYY` lists meetings; `Detail_Meeting.aspx?ID=<n>` shows
--     every item with its vote result; item memos are `FileOpen.aspx?Type=30&ID=<n>&MeetingID=<n>`.
--   * 1997 - Jan 2016: GovStream at sccounty01.co.santa-cruz.ca.us/bds/Govstream2/. 🔴 The agenda
--     PDFs there are IMAGE SCANS with no text layer -- but `ASP/Display/
--     SCCB_MinutesDisplayWeb.asp?MeetingID=<n>` serves the same meeting's minutes as real HTML.
--     Grepping the PDFs finds nothing and looks like a clean negative; that is where Rosell was.
--
-- ── 🔴🔴 FOUR OF FIVE ARE BOARD APPOINTEES, AND THE COUNTY DATES THEM TO THE MINUTE ───────────
-- Santa Cruz fills vacancies under Gov. Code 25304 and writes the effective moment into the
-- recommended action -- "effective 5:00 pm on July 3, 2025", "effective 5:00 pm on December 6,
-- 2024", "effective 5:00 p.m. on December 30, 2020". That is the most precise start-date convention
-- the wave has met, and it makes the DEFERRED effective date explicit: in each case the Board acted
-- weeks or months BEFORE the date the person actually took office. Clark's appointment was approved
-- 2024-08-27 and took effect 2024-12-06 -- more than three months apart. **Seeding from the Board
-- action date would be wrong for three of the four.**
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Rosell   2014-11-18  day    appointed. BoS minutes 2014-11-18, item 67: "CONSIDERED nominations
--                               for Santa Cruz County District Attorney; APPROVED recommendations
--                               of Supervisors Friend and McPherson, and appointed Jeff Rosell to
--                               the position of District Attorney until the results of the election
--                               in 2016 are declared." He succeeded Bob Lee, who died in office;
--                               the same meeting's consent agenda still says "as recommended by the
--                               **Acting** District Attorney". 🔴 Unlike the county's other three
--                               appointments this record names NO deferred effective date, and this
--                               county demonstrably writes one when it means one -- so the action
--                               date is the start. His own office's page says only "He was
--                               appointed District Attorney in 2014."
--   Webber   2020-12-30  day    appointed. Board memo for the 2020-12-08 meeting: "Appoint Tricia
--                               Webber to serve as County Clerk effective 5:00 p.m. on December 30,
--                               2020", Gail Pellerin having resigned effective the same day.
--                               🔴 THE COUNTY'S OWN HISTORICAL ROSTER IS WRONG BY TWO DAYS AND A
--                               YEAR: the Clerk's "Santa Cruz County Clerks from 1850 to Present"
--                               table prints "Tricia Webber 2021 -". A dated Board action beats a
--                               list that merely prints a year (the Monterey rule, 1656).
--   Thomas   2023-01-01  month  elected. Won the certified June 2022 primary outright (52,302,
--                               98.17%, write-ins only). Sean Saldavia served out his term -- the
--                               Board issued a retirement proclamation for him on 2022-12-06 -- and
--                               sweeps of every 2022 and 2023 meeting found no early appointment,
--                               so she started at the statutory January date. No county document
--                               names the day, hence month precision.
--   Clark    2024-12-06  day    appointed. Board memo, meeting 2024-08-27: "Approve appointment of
--                               Chris Clark as Santa Cruz County Sheriff effective 5:00 pm on
--                               December 6, 2024", Sheriff Jim Hart having submitted his
--                               resignation effective that day. Clark was the Undersheriff. His own
--                               bio says he "was sworn in as the 27th Sheriff-Coroner of Santa Cruz
--                               County in December 2024".
--   Bowers   2025-07-03  day    appointed. BoS minutes 2025-05-06, item 14: "Approved the
--                               appointment of Laura Bowers to the position of Santa Cruz County
--                               Auditor-Controller-Treasurer-Tax Collector effective 5:00pm on
--                               July 3, 2025." Edith Driscoll retired (Board proclamation
--                               2025-06-24). Bowers was then elected in her own right in June 2026.
--
-- ── 🔴🔴 THIS COUNTY'S ACFR DIRECTORY IS AS-OF-PUBLICATION, NOT AS-OF-FISCAL-YEAR-END ─────────
-- The FY2024-25 ACFR covers the year ended 2025-06-30 and its Directory of Public Officials lists
-- **Laura Bowers**, who did not take office until 2025-07-03, and **Christopher Clark**, seated
-- 2024-12-06. So it reports who holds the seat when the book was printed. That is the exact OPPOSITE
-- of Solano (1650), whose FY2025 org chart was captioned "June 30, 2025", was published in February
-- 2026, and still pictured a sheriff who had retired months earlier. **The rule is not "an ACFR is
-- stale" or "an ACFR is current" -- it is: find out what the document says it is as of, and where it
-- says nothing, trust it for neither.** Here Santa Cruz's directory carries no as-of date at all;
-- it was checked against the department sites and the Board record rather than believed.
--
-- ── 🔴 AB 759, THIRTEENTH COUNTY -- AND HERE THE COUNTY REASONS FROM IT IN A BOARD MEMO ───────
-- The 2024-08-27 memo appointing Clark: "A recent change to State law reflected in Elections Code
-- Section 1300 establishes that Sheriff Hart's current term lasts until January 8, 2029." The Board
-- had to work out how long its appointee would serve, and wrote the answer down. The certified June
-- 2026 ballot agrees from the other side -- Assessor-Recorder, Auditor-Controller-Treasurer-Tax
-- Collector and County Clerk, plus two supervisors and the Superintendent, and no DA, no Sheriff.
-- Note the ACFR run records the county learning this: FY2023 and FY2024 both print the
-- Sheriff-Coroner term as ending January 2027; FY2025 prints January 2029.
--
-- ── 🔴 NO JANUARY 2027 TURNOVER ───────────────────────────────────────────────────────────────
-- Certified June 2026, all three unopposed against write-ins: Thomas 58,528 (98.61%), Bowers 58,907
-- (98.61%), Webber 60,144 (98.81%). Sixth county in the wave needing no re-check, after Tulare
-- (1645), Monterey (1656), Placer (1658), Merced (1660) and San Luis Obispo (1662).
--
-- ── 🔴 SUPERINTENDENT OF SCHOOLS -- NOT SEEDED ────────────────────────────────────────────────
-- Faris M. Sabbah won it unopposed in June 2026 (58,709, 97.81%). Excluded on the usual
-- discriminator: the ACFR's Directory lists five county Elected Officers and no Superintendent, and
-- there is no Office of Education among the county's departments. Same as Kern (1638), Riverside
-- (1630), Tulare (1645), Solano (1650), Santa Barbara (1652), Monterey (1656), Placer (1658),
-- Merced (1660) and San Luis Obispo (1662).
--
-- ── 🔴 THE OFFICE SET: A SEPARATE COUNTY CLERK, WITH THE RECORDER ON THE ASSESSOR ─────────────
-- Assessor+Recorder are one seat; Auditor+Controller+Treasurer+Tax Collector are another; the
-- County Clerk (who is also Registrar of Voters) stands alone. Sonoma (1644) folds the Clerk in
-- with the Assessor and Recorder; San Luis Obispo (1662) folds the Public Administrator into the
-- ACTTC and keeps a Clerk-Recorder. Tenth distinct office set in the wave. The Clerk's own page
-- records why: its footnotes say the County Clerk was combined with the Recorder in 1961, combined
-- again with Treasurer-Tax Collector in 1994, and "Separate County Clerk Office created again in
-- July 2004".
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- Stored "http://www.co.santa-cruz.ca.us" 301s to https://www.santacruzcountyca.gov/ -- stale
-- rather than dead (the Merced/Ventura shape, not the SLO NXDOMAIN shape). Repointed, guarded on
-- end state.
--
-- geo_id 06087 has no district_type collision in the corpus today, but every predicate below is
-- still scoped by district_type -- 1,159 such collisions exist and Assembly seats are synthesized
-- as <state FIPS>||<district number>.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62087001..5.
-- Pre-flight: 0 external_id collisions; no politician in the corpus matches any of these five on
-- first+last name. No pre-existing Santa Cruz chamber, government row or office.
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
  ('Assessor-Recorder',                          -62087001,'Sheri Thomas',        'Sheri',      'Thomas', NULL,NULL,   '2023-01-01','month','elected'),
  ('Auditor-Controller-Treasurer-Tax Collector', -62087002,'Laura Bowers',        'Laura',      'Bowers', NULL,NULL,   '2025-07-03','day',  'appointed'),
  ('County Clerk',                               -62087003,'Tricia Webber',       'Tricia',     'Webber', NULL,NULL,   '2020-12-30','day',  'appointed'),
  ('District Attorney-Public Administrator',     -62087004,'Jeffrey S. Rosell',   'Jeffrey',    'Rosell', 'S','Jeff',  '2014-11-18','day',  'appointed'),
  ('Sheriff-Coroner',                            -62087005,'Christopher Clark',   'Christopher','Clark',  NULL,'Chris','2024-12-06','day',  'appointed');

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
SELECT 'Santa Cruz County, California, US', 'County', 'CA', '06087'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06087' AND g.type='County');

UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
   AND g.geo_id='06087' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.santacruzcountyca.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
   AND d.official_web_url IS DISTINCT FROM 'https://www.santacruzcountyca.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Santa Cruz County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06087' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Santa Cruz County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, preferred_name, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid, s.pref,
       'migration 1663 — Santa Cruz County FY2024-25 ACFR Directory of Public Officials + certified 2026-06-02 and 2022-06-07 official results + department sites + BoS minutes 2014-11-18/2025-05-06 and memos 2020-12-08/2024-08-27, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Santa Cruz County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1663 — Santa Cruz County FY2024-25 ACFR Directory of Public Officials + certified 2026-06-02 and 2022-06-07 official results + department sites + BoS minutes 2014-11-18/2025-05-06 and memos 2020-12-08/2024-08-27, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text; v_stale text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 Santa Cruz offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  -- Counting cannot see WHO is in a seat.
  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- Four of five predecessors left mid-term. Fail if a stale roster ever seats one of them here.
  -- Pellerin in particular is a live politician in this corpus, as the Assembly member for AD-28.
  SELECT string_agg(p.full_name, ', ') INTO v_stale
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
     AND ((p.last_name ILIKE 'Driscoll' AND p.first_name ILIKE 'Edith%')
       OR (p.last_name ILIKE 'Hart'     AND p.first_name ILIKE 'Jim%')
       OR (p.last_name ILIKE 'Saldavia')
       OR (p.last_name ILIKE 'Pellerin')
       OR (p.last_name ILIKE 'Lee'      AND p.first_name ILIKE 'Bob%'));
  IF v_stale IS NOT NULL THEN
    RAISE EXCEPTION 'A departed Santa Cruz officeholder is seated (%) -- see migration 1663 header', v_stale;
  END IF;

  -- The Superintendent of Schools heads a separate entity here -- see header.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
                AND o.title ILIKE '%Superintendent%') THEN
    RAISE EXCEPTION 'A Superintendent of Schools office exists in Santa Cruz County -- see migration 1663 header';
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087'
     AND g.geo_id='06087' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Santa Cruz district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06087';
  IF v_url IS DISTINCT FROM 'https://www.santacruzcountyca.gov/' THEN
    RAISE EXCEPTION 'Santa Cruz official_web_url is %, expected https://www.santacruzcountyca.gov/', v_url;
  END IF;
END $$;

COMMIT;
