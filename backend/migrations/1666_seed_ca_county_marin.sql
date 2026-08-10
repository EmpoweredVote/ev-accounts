-- 1666_seed_ca_county_marin.sql
--
-- CA county wave: Marin County. 3 countywide elected officials, 254,407 residents.
-- The final county in the wave -- wave total: 24 counties, 119 seats, 25,967,746 residents
-- (verified post-apply; corpus-wide that is 25 CA county districts / 122 offices / 122 seated, the
-- extra one being LA, seeded before this wave and only repaired by it in 1635).
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- 🔴 marincounty.gov, marinsheriff.gov and assets.marincounty.gov are behind CLOUDFLARE and answer
-- plain curl with 403 -- including a full browser header set, because the block is on the TLS
-- fingerprint, not the User-Agent. Playwright renders them and a same-origin fetch() reaches every
-- path. marincountyda.org is NOT walled. The stored "http://www.co.marin.ca.us" is NXDOMAIN -- a
-- genuinely dead host (the San Luis Obispo shape, 1662, not the stale-301 shape of Merced/Santa
-- Cruz). Everything below is a county document, read 2026-08-10:
--
--   Office set:   the FY2025 ACFR "ELECTED AND APPOINTED PUBLIC OFFICIALS / JUNE 30, 2025",
--                 printed p. xxiv = PDF p. 33, and the "MARIN COUNTY ORGANIZATION CHART" facing it
--                 on p. xxv = PDF p. 34, of assets.marincounty.gov/marincounty-prod/public/
--                 2026-06/County of Marin FY25 ACFR (unsecured)-accessible.pdf (17.4 MB).
--   Titles:       the ACFR elected-officials list, the department's own site, and the Elections
--                 Department's "When offices are up for election - county offices" page.
--   Holders:      each office's own site, all three confirmed current today (see below).
--   Start dates:  a county news release and Board of Supervisors minutes -- see TERM STARTS.
--
-- ── 🔴🔴 THREE ELECTED COUNTYWIDE SEATS -- THE SMALLEST OFFICE SET IN THE WAVE ─────────────────
-- Marin elects an Assessor-Recorder-County Clerk, a District Attorney and a Sheriff-Coroner, and
-- nothing else countywide. There is NO elected Auditor, Controller, Treasurer, Tax Collector or
-- Public Administrator anywhere in this county: all five functions sit in an APPOINTED Department
-- of Finance, whose own page says "Our department serves as the County's auditor, controller, tax
-- collector, treasurer, and public administrator." The ACFR lists its Director (Mina L.
-- Martinovich, CPA) under "APPOINTED OFFICIALS (by the Board of Supervisors)", and the Registrar of
-- Voters (Natalie Adona) under "APPOINTED OFFICIALS (by the County Administrator)".
-- Sonoma (1644) held the previous minimum at four. **Eleventh distinct office set in the wave, and
-- the first where the finance/tax side of the county is entirely unelected** -- a template built
-- from any other county would have invented two or three empty seats here, and an office with no
-- office_terms row is invisible everywhere while nothing errors.
--
-- ── 🔴🔴 THE ACFR's OFFICIALS PAGE MISPAIRED 9 OF ITS 15 APPOINTED ROWS UNDER `pdftotext` ──────
-- The page is two columns -- titles left, names right -- and the extracted text does NOT align them
-- consistently: the name column drifts by one row and then corrects itself, so the layout pass read
-- "Director of Finance" against an empty cell and handed Mina Martinovich to "Director of U.C.
-- Cooperative Extension", Jason Weber to "Fire Chief"'s neighbour, and so on down the block. The
-- elected block drifted too. **This is the Fresno off-by-one (1633) in a document I would otherwise
-- have trusted, and no gate can catch it** -- the identity gate compares the seated name to what I
-- INTENDED, and I would have intended the wrong thing. Both pages were therefore RENDERED
-- (`pdftoppm -f 33 -l 33 -r 160 -png`) and read as images. Only the rendered page is authority here.
--
-- ── 🔴 THE ORG CHART CONFIRMS THE ELECTED SET GRAPHICALLY, AND INDEPENDENTLY ───────────────────
-- Page xxv marks elected departments with a dashed blue border keyed "(EO) Elected Official".
-- Exactly three boxes carry it: ASSESSOR-RECORDER-COUNTY CLERK, DISTRICT ATTORNEY and MARIN COUNTY
-- SHERIFF'S OFFICE. DEPARTMENT OF FINANCE and ELECTIONS sit in the same column as plain
-- Departments with no marker. That is a second confirmation of the negative finding above, in a
-- different notation on a different page, and it does not depend on the two-column pairing that
-- the extraction got wrong.
--
-- ── TERM STARTS (occupancy, not current term) ──────────────────────────────────────────────────
--   Scott     2019-01-07  day    elected. County news release "Frugoli, Scott Sworn In to Lead
--                                County Departments", dated 2019-01-07: "Shelly Scott was sworn in
--                                as Assessor-Recorder-County Clerk on January 7." She was elected
--                                at the June 2018 primary and replaced the retiring Richard N.
--                                Benson, "who has been Assessor-Recorder-County Clerk since 2010".
--                                🔴 Day precision is taken here for the SLO/Parkinson reason (1662)
--                                and only that reason: 2019-01-07 was ALSO the statutory
--                                commencement -- Gov. Code 24200, noon on the first Monday after
--                                January 1 -- so the county's oath date and the statute name the
--                                same day. Two independent facts agreeing is what earns the day.
--   Frugoli   2019-01-01  month  elected. Same release: "Lori Frugoli took the oath as District
--                                Attorney on January 4." 🔴 THAT DATE IS THREE DAYS BEFORE HER TERM
--                                COULD BEGIN. The statutory commencement was 2019-01-07, and an
--                                officer may take the oath before the term starts (Gov. Code 1360).
--                                So the county publishes a specific day that is NOT the start day,
--                                and no county document names the day she actually took over.
--                                Sweeps of every BoS meeting from November 2018 through January
--                                2019 found no appointment item and no mention of Frugoli or of her
--                                predecessor Edward Berberian, and there is no retirement release
--                                for Berberian -- so unlike Merced (1660) and SLO (1662) the
--                                officer-elect was NOT seated early, and the seat never fell vacant.
--                                Month precision is the honest encoding when two candidate days
--                                conflict; this is the Placer oath rule (1658).
--   Scardina  2022-07-19  day    appointed. BoS MINUTES of 2022-07-19, item 7: "REQUEST TO APPOINT
--                                UNDERSHERIFF JAMIE SCARDINA AS MARIN COUNTY SHERIFF EFFECTIVE JULY
--                                19, 2022" -- "M/s Supervisor Connolly - Supervisor Arnold to
--                                appoint Undersheriff Jamie Scardina as Marin County Sheriff
--                                effective July 19, 2022. Vote: Motion carried 4-0". Item 1 of the
--                                SAME meeting adopted a resolution honouring the retiring Sheriff
--                                Robert Doyle.
--
-- ── 🔴🔴 THE SHERIFF'S SEAT HAS THREE PLAUSIBLE START DATES AND THE COUNTY DISTINGUISHES ALL 3 ──
-- The news release "Jamie Scardina Appointed Marin County Sheriff" (2022-07-28) lays them out:
-- Doyle "retired June 30" and Scardina "became Acting Sheriff"; the Board's 2022-07-19 action "had
-- the 'acting' taken off his title"; and "Scardina took the oath of office, administered by Doyle,
-- at a public swearing-in ceremony on July 28."
--   * 2022-07-01 is when he began ACTING. Acting in a seat is not holding it.
--   * 2022-07-19 is when he became Sheriff. This is what is seeded.
--   * 2022-07-28 is a ceremony NINE DAYS AFTER the effective date.
-- Placer (1658) and SLO (1662) each caught a ceremony date standing in front of a start date; this
-- is the first time in the wave a ceremony falls BEHIND one. Either way the ceremony is not it.
-- 🔴 And note this is a THIRD county where "the winner takes office in January" fails: the release
-- says Scardina "was elected as Sheriff in the June Primary Election, running unopposed, and was to
-- be sworn in when Doyle's term ended January 2, 2023" -- the incumbent retired early, so the
-- officer-elect was seated five months ahead. Merced (1660) and SLO (1662) did the same thing.
-- 🔴 His own county bio DOES record the appointment ("Jamie was appointed to Sheriff in July 2022"),
-- which is the opposite of Placer's Woo, whose bio omitted his and said only "elected in 2022".
--
-- ── 🔴 THE SHERIFF'S HOME PAGE NAMES NO SHERIFF -- THE SAN MATEO SHAPE AGAIN ───────────────────
-- marinsheriff.gov's front page mentions no officeholder at all; the holder is only on
-- /about-us/executive-staff. San Mateo (1642) had exactly this, and there it concealed a sheriff who
-- had been REMOVED. Checked here for the same thing and it is benign -- Scardina is current.
-- 🔴 A SURNAME HOMONYM SITS ON THAT SAME EXECUTIVE TEAM: Captain **Craig** Scardina, Field Services
-- Commander, alongside Sheriff **Jamie** Scardina. The Stanislaus (1643) and Merced (1660) shape.
-- The identity gate below compares FULL names, and a named guard rejects any other Scardina.
--
-- ── 🔴 ALL THREE HOLDERS RE-CONFIRMED TODAY, BECAUSE THE ACFR IS AS-OF JUNE 2025 ───────────────
-- The FY2025 ACFR is captioned "JUNE 30, 2025" and was published 2026-06 -- the Solano shape (1650),
-- where a fourteen-month-old caption hid a retired sheriff. So each holder was checked against a
-- live source: arcc.marincounty.gov ("Shelly Scott, the elected Assessor-Recorder-Clerk"),
-- marincountyda.org (names Frugoli, carrying a 2026-07-14 news item) and
-- marinsheriff.gov/about-us/executive-staff ("Sheriff Jamie Scardina").
--
-- ── 🔴 NO JANUARY 2027 TURNOVER, AND THE COUNTY PUBLISHES THE CYCLE RATHER THAN LEAVING IT TO ──
--    INFERENCE
-- The Elections Department's "When offices are up for election - county offices" page (updated
-- 2026-02-12) prints the schedule as data: Assessor-Recorder-County Clerk in the "Primary Election
-- of Any Year Not Evenly Divisible by Four", District Attorney and Sheriff-Coroner in the "Primary
-- Election of Any Year Evenly Divisible by Four". So 2026 is the Assessor's year and the DA's and
-- Sheriff's next is 2028 -- the presidential primary, which is what AB 759 (Ch. 743, 2022) moved
-- them to. Every earlier county in the wave had to infer this from a contest MISSING off a ballot;
-- Marin states the cycle positively. Fourteenth county consistent with AB 759.
-- Confirmed from both ends: the certified June 2026 results (Clarity, ver 376467) contain
-- Assessor-Recorder-Clerk (Shelly Scott 68,582, sole candidate, write-ins 0), County Superintendent
-- of Schools, two County Supervisor contests and no DA and no Sheriff; and the November 3, 2026
-- candidate-status list contains NO countywide county office at all, so there is no runoff either.
-- Scott is re-elected and continues. **Seventh county in the wave needing no post-turnover
-- re-check**, after Tulare, Monterey, Placer, Merced, San Luis Obispo and Santa Cruz.
--
-- ── 🔴 SUPERINTENDENT OF SCHOOLS -- NOT SEEDED ────────────────────────────────────────────────
-- John A. Carroll won it unopposed in June 2026 (70,127). Excluded on the usual discriminator, which
-- is unusually strong here: the ACFR's ELECTED OFFICIALS list names three countywide officers and no
-- Superintendent, the org chart has no Office of Education box, and the county's 25-department
-- directory has none either (the Marin County Office of Education is marinschools.org). Same as
-- Kern (1638), Riverside (1630), Tulare (1645), Solano (1650), Santa Barbara (1652), Monterey
-- (1656), Placer (1658), Merced (1660), San Luis Obispo (1662) and Santa Cruz (1663).
--
-- ── 🔴🔴 geo_id 06041 IS A LIVE COLLISION IN THIS CORPUS -- NOT A THEORETICAL ONE ──────────────
-- Two districts carry geo_id '06041': this county row (district_type COUNTY, state 'ca') and
-- **Assembly District 41** (STATE_LOWER, state 'CA'), whose geo_id is synthesized as
-- <state FIPS>||<3-digit district number>. The pre-flight query proved it: an unscoped
-- `districts.geo_id = '06041'` join returned AD-41's Assembly Member office. Every predicate below
-- is therefore scoped by district_type AND lower(state). This is one of the 1,159 known collisions.
--
-- ── SOURCE CHANNEL WORTH KEEPING: THE BOARD RECORD IS A HYLAND PublicAccess PORTAL ─────────────
-- pav.marincounty.org/publicaccessbosrecords/ is an OnBase PublicAccess app, and its API is usable
-- directly from inside the page:
--   * POST /publicaccessbosrecords/api/CustomQuery/KeywordSearch with
--     {"QueryID":213,"Keywords":[{"ID":428,"Value":"BOS MINUTES"},...,{"ID":598,"Value":"<MM>"},
--     {"ID":599,"Value":"<YYYY>"},...],"QueryLimit":0}  -- 428 = doc type (BOS MINUTES, BOS AGENDAS,
--     RESOLUTIONS, ORDINANCES, ...), 598 = month, 599 = year -- returns one opaque ID per document.
--   * GET /publicaccessbosrecords/api/Document/<urlencoded id>  -- returns the PDF. (A POST to the
--     same URL returns only metadata, which is what the app itself does first.)
-- 🔴 Its "PAV_BOS_Records_Text_Search" search type is offered in the UI but the endpoint answers
-- **403 for the public**, so full-text search is not available and months must be swept.
-- 🔴 TWO OF THE FIVE JULY 2022 MINUTES PDFs EXTRACT TO 2 CHARACTERS -- image scans with no text
-- layer. A grep over them returns a clean-looking negative, the Santa Cruz GovStream mode (1663).
-- Print the extracted byte count before believing an empty result.
--
-- ── official_web_url ──────────────────────────────────────────────────────────────────────────
-- Stored "http://www.co.marin.ca.us" does not resolve (NXDOMAIN). Repointed to
-- https://www.marincounty.gov/, verified to be the county's own site (marincounty.org 301s to it).
-- Guarded on end state.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62041001..3.
-- Pre-flight: 0 external_id collisions; no politician in the corpus matches any of these three on
-- first+last name. No pre-existing Marin government row, chamber or office. 🔴 A pre-flight
-- `name_formal ILIKE '%Marin%'` matched only **San Marino** City Council and San Marino Unified --
-- substring matching on a place name, the same class of defect migration 1664 is cleaning up for
-- surnames. Nothing named Marin existed.
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
  ('Assessor-Recorder-County Clerk', -62041001,'Shelly Scott',     'Shelly','Scott',    NULL,NULL,'2019-01-07','day',  'elected'),
  ('District Attorney',              -62041002,'Lori E. Frugoli',  'Lori',  'Frugoli',  'E', NULL,'2019-01-01','month','elected'),
  ('Sheriff-Coroner',                -62041003,'Jamie Scardina',   'Jamie', 'Scardina', NULL,NULL,'2022-07-19','day',  'appointed');

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
SELECT 'Marin County, California, US', 'County', 'CA', '06041'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06041' AND g.type='County');

UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
   AND g.geo_id='06041' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

UPDATE essentials.districts d
   SET official_web_url = 'https://www.marincounty.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
   AND d.official_web_url IS DISTINCT FROM 'https://www.marincounty.gov/';

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Marin County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06041' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Marin County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, preferred_name, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid, s.pref,
       'migration 1666 — Marin County FY2025 ACFR elected-officials list + org chart (PDF pp. 33-34, read as rendered images) + department sites + county news releases 2019-01-07 and 2022-07-28 + BoS minutes 2022-07-19 + certified 2026-06-02 results, read 2026-08-10',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='Marin County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1666 — Marin County FY2025 ACFR elected-officials list + org chart (PDF pp. 33-34, read as rendered images) + department sites + county news releases 2019-01-07 and 2022-07-28 + BoS minutes 2022-07-19 + certified 2026-06-02 results, read 2026-08-10',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer; v_url text; v_stale text; v_extra text;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041';
  IF v_offices <> 3 THEN RAISE EXCEPTION 'Expected 3 Marin offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 3 THEN RAISE EXCEPTION 'Expected 3 seated holders, found %', v_seated; END IF;

  -- Counting cannot see WHO is in a seat.
  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  -- All three predecessors left, and a surname homonym sits on the Sheriff's own executive team.
  -- Fail if a stale roster ever seats one of them here. See header.
  SELECT string_agg(p.full_name, ', ') INTO v_stale
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    JOIN essentials.politicians p ON p.id=och.politician_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
     AND ((p.last_name ILIKE 'Benson'    AND p.first_name ILIKE 'Richard%')
       OR (p.last_name ILIKE 'Berberian')
       OR (p.last_name ILIKE 'Doyle'     AND p.first_name ILIKE 'Robert%')
       OR (p.last_name ILIKE 'Scardina'  AND p.first_name NOT ILIKE 'Jamie%'));
  IF v_stale IS NOT NULL THEN
    RAISE EXCEPTION 'A departed Marin officeholder or a Scardina homonym is seated (%) -- see migration 1666 header', v_stale;
  END IF;

  -- 🔴 Marin elects NO finance officer. Every one of these functions is in the APPOINTED Department
  -- of Finance, and the Superintendent of Schools heads a separate entity. See header.
  SELECT string_agg(o.title, ', ') INTO v_extra
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
     AND (o.title ILIKE '%Auditor%'   OR o.title ILIKE '%Controller%'
       OR o.title ILIKE '%Treasurer%' OR o.title ILIKE '%Tax Collector%'
       OR o.title ILIKE '%Public Administrator%' OR o.title ILIKE '%Director of Finance%'
       OR o.title ILIKE '%Superintendent%' OR o.title ILIKE '%Registrar%');
  IF v_extra IS NOT NULL THEN
    RAISE EXCEPTION 'Marin has no elected finance officer, registrar or superintendent, but found: % -- see migration 1666 header', v_extra;
  END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041'
     AND g.geo_id='06041' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Marin district not linked to its government row (%)', v_gov; END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06041';
  IF v_url IS DISTINCT FROM 'https://www.marincounty.gov/' THEN
    RAISE EXCEPTION 'Marin official_web_url is %, expected https://www.marincounty.gov/', v_url;
  END IF;

  -- geo_id 06041 is shared with Assembly District 41 -- prove this migration did not touch it.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.districts d ON d.id=o.district_id
               JOIN essentials.chambers ch ON ch.id=o.chamber_id
              WHERE d.geo_id='06041' AND d.district_type <> 'COUNTY'
                AND ch.name_formal='Marin County Countywide Elected Officials') THEN
    RAISE EXCEPTION 'A non-COUNTY district with geo_id 06041 (Assembly District 41) was attached to the Marin chamber -- see migration 1666 header';
  END IF;
END $$;

COMMIT;
