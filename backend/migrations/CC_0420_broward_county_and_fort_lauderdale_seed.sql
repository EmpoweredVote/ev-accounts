-- CC_0420 — Broward County and the City of Fort Lauderdale, Florida: governments, chambers,
--            districts, offices, and the roster with charter-dated terms.
--
-- Greenfield. Measured 2026-11-13: ZERO rows for either jurisdiction in `governments`,
-- `offices`, `districts` and `geo_districts`. Florida itself is not greenfield — the state tier
-- (7 chambers, 165 offices), the counties Leon / Manatee / Miami-Dade / Palm Beach and the
-- cities Bradenton / Miami / Tallahassee are already seeded, and **Miami-Dade County and the
-- City of Miami are the structural template this file copies**.
--
-- ══ 1. 🔴 BROWARD HAS NO ELECTED MAYOR. COPYING MIAMI-DADE WOULD INVENT A SEAT. ═════════════
-- Miami-Dade carries THREE chambers, the third being `Office of the Mayor`, a countywide
-- elected office. Broward has no counterpart. Broward County Charter § 2.03.A (Revised
-- November 5, 2024) reads:
--
--   "The County Commission shall elect one (1) Commissioner to the position of Mayor by a
--    majority vote. The election of the Mayor shall occur on an annual basis, during the County
--    Commission's annual organizational meeting, which shall take place no earlier than the
--    third Tuesday of each November and no later than the third Tuesday of each December."
--
-- A one-year rotation among the nine sitting commissioners — a role, not a seat anyone is
-- elected to. Mark Bogen holds it at the moment and Robert McKinzie is Vice Mayor; neither fact
-- belongs in `offices`. Broward's commission is also PARTISAN where Miami-Dade's is not, so
-- these nine offices carry `partisan_type = 'partisan'` and Miami-Dade's carry nothing.
--
-- ⚠ THE CHARTER IS HARD TO READ CORRECTLY. `broward.org/Charter/Documents/Charter.pdf` is a
-- 404, and the copy mirrored at `miamidade.gov/charter/library/charter_broward_county.pdf` is
-- the **2002** revision — twenty-four years stale, still listing Ilene Lieberman in District 1.
-- The live text (76pp, "Revised November 5, 2024") is served from
-- `browardcdn.org/api/public/content/6dfaca0e109c4bbdb8fcf7e756267531?v=3eb5dc4a`, linked from
-- `broward.org/charter`. Same trap as Gov. Code § 24200 in CC_0412: read the current text.
-- ⚠ `broward.org` answers 403 to curl. A full browser header set (UA + Accept + Accept-Language
-- + Sec-Fetch-*) turns the 403 into a genuine 404, so the block keys on HEADERS, not IP.
-- Playwright also gets through. `browardvotes.gov` answers plain curl.
--
-- ══ 2. THE DATE RULES, EACH FROM ITS OWN ENACTED SOURCE ═════════════════════════════════════
--
-- (a) COUNTY COMMISSIONERS — Broward County Charter § 2.01.B:
--       "Commissioners shall be elected on a partisan basis. The terms of office shall begin on
--        the Tuesday two (2) weeks following the day of the general or special election."
--     2022-11-08 + 14d = 2022-11-22 · 2024-11-05 + 14d = 2024-11-19 ·
--     2026-11-03 + 14d = **2026-11-17** · 2028-11-07 + 14d = 2028-11-21 ·
--     2030-11-05 + 14d = 2030-11-19.
--     § 2.01(3) staggers the board: Districts 1, 3, 5, 7, 9 were elected in 2004 and Districts
--     2, 4, 6, 8 in 2002, so the odd seats run on the 2024/2028 cycle and the even seats on
--     2022/2026/2030. That matches the Supervisor of Elections' "Next Election" column exactly.
--     § 2.02 caps three consecutive four-year terms.
--
-- (b) COUNTY CONSTITUTIONAL OFFICERS — Florida Statutes § 100.041(4):
--       "The term of office of each county and each district officer not otherwise provided by
--        law shall commence on the first Tuesday after the first Monday in January following his
--        or her election."
--     ⚖ "not otherwise provided by law" is doing real work: the charter provides otherwise for
--     COMMISSIONERS (§ 2.01.B above) but says nothing about these five, so the statute controls.
--     Elected 2024-11-05 → 2025-01-07; the terms run to 2029-01-02 on the same rule.
--
-- (c) FORT LAUDERDALE, REGULAR SEATS — City Charter § 7.07:
--       "Beginning in the year 2020, and every fourth year thereafter, a regular municipal
--        election shall be held on the first Tuesday after the first Monday in November for the
--        purpose of electing a mayor and four (4) city commissioners. However, should only one
--        (1) candidate qualify for the office of mayor or city commissioner, then, and in that
--        event, no regular election for that office shall be held and the city clerk shall
--        certify such fact to the city commission and the city commission shall declare such
--        person(s) to be elected to the office of mayor or city commissioner."
--       "The nominee receiving the highest number of votes shall be elected to the office for
--        which he or she was a candidate."
--       "The mayor and the city commissioners elected at such election shall serve for terms of
--        four (4) years each beginning on the first regular meeting day in December following
--        their election and shall serve until their successors are elected and qualified."
--
--     🔑 THREE THINGS FALL OUT OF THAT PARAGRAPH:
--     · **Fort Lauderdale is a PLURALITY city** — "highest number of votes", no runoff. Proven
--       by the record as well as the text: Dean Trantalis took the mayoralty in 2024 on 38.39%
--       and Ben Sorensen District 4 on 39.59%, and both sat. No runoff appears anywhere in the
--       Supervisor of Elections' results archive between then and the 2025 municipal election.
--     · **A sole qualifier is DECLARED elected without an election.** That is the mechanism
--       behind District 3: Pamela Beasley-Pittman appears on no 2024 ballot, because none was
--       held for her seat. Her term is the ordinary 2024 term all the same.
--     · Terms begin on the **first regular meeting day in December**, which for this commission
--       is the first Tuesday. 2024-12-03 (Dec 1 2024 was a Sunday) and 2028-12-05 (Dec 1 2028 is
--       a Friday). The 2028 date is not a derivation — Resolution 26-88 states it outright, see
--       below — and 2024-12-03 follows the identical rule. The 2022 swearing-in was likewise set
--       for Dec 6 2022, the first Tuesday of that December.
--     ⚠ The Municode codification this was read from may not yet carry the charter amendments
--     approved at the 2026-11-03 election (nine of ten city questions passed). Those cannot move
--     a term already running, but re-read § 7.07 before writing the 2028 terms.
--
-- (d) 🔴🔴 FORT LAUDERDALE DISTRICT 1 — THE WEBSITE SENTENCE IS NOT THE TERM.
--     `fortlauderdale.gov/government/city-commission` says, today: "The newly elected
--     commissioner will be sworn in at the Nov. 17, 2026, City Commission meeting." That is the
--     CEREMONY. Charter § 7.10 puts the legal date somewhere else entirely:
--
--       "A special municipal election ... shall be held in the same manner as provided herein
--        for a regular quadrennial election. The city commission may call the special municipal
--        election by resolution. **Such resolution shall specify the length of the unexpired
--        term or terms to be filled, and the time of taking office** of the elected mayor, city
--        commissioner or commissioners; which ... shall hold office until their successors,
--        elected in regular quadrennial municipal elections, shall take office."
--
--     The resolution is **No. 26-88**, a scanned document with no text layer, read page by page
--     as images. SECTION 3, verbatim:
--
--       "That a special municipal election of the City of Fort Lauderdale shall be held on
--        November 3, 2026, for the purpose of electing a City Commissioner from Commission
--        District 1, such Commissioner so elected to serve a term that shall begin at 12:00 a.m.
--        on Tuesday, **December 1, 2026**, and end at 11:00 a.m. on Tuesday, **December 5,
--        2028**, or until a successor is elected and qualified."
--
--     So Heather Moraitis' term starts **2026-12-01**, a fortnight after the swearing-in the
--     city's own page advertises. Taking that page at face value would have dated this row two
--     weeks early and shown her holding a seat she does not yet hold.
--     🔑 It also hands us the 2028 boundary for free: the regular terms END at 2028-12-05,
--     because that is when their successors take office.
--
-- ══ 3. THE VACANCY, AND WHY NO ROW COVERS IT ════════════════════════════════════════════════
-- Resolution 26-88's recitals: "District 1 Commissioner John C. Herbst has submitted his
-- resignation effective 11:59 p.m. on Monday, November 2, 2026, thereby creating a vacancy on
-- the City Commission", and § 7.08 required a special election because more than eighteen months
-- remained before the next quadrennial election.
-- Herbst's term is seated here CLOSED at 2026-11-02 with `how_ended = 'resigned'`. Nothing
-- covers 2026-11-03 → 2026-11-30, so `essentials.current_office_holders` resolves District 1 to
-- NOBODY for those 28 days — which is the truth, and the post-conditions assert it.
--
-- ══ 4. THE RESULTS, FROM OFFICIAL CANVASSES ═════════════════════════════════════════════════
-- Broward Supervisor of Elections, `results.browardvotes.gov/ENR/browardflenr/<id>/...`:
-- 240 = Nov 3 2026 general · 239 = Aug 18 2026 primary · 236 = Nov 5 2024 general. Each page
-- states "OFFICIAL ELECTION RESULTS" in its header and carries a "Website Updated" stamp; the
-- Nov 2026 page read 100% of 346 precincts at 11/13/2026 2:42 PM.
--
-- · Fort Lauderdale, Commissioner, District 1 (special, 2026-11-03):
--     Heather Moraitis     8,553   49.04%
--     John E. Rodstrom     8,142   46.68%
--     Garry Smyth            746    4.28%
--                         ──────
--                         17,441   (8,553 + 8,142 + 746 = 17,441 — reconciles exactly)
--   A plurality, which § 7.07 makes sufficient.
--   ⚠ Axios called the runner-up "John Rodstrom III". The certified canvass says
--   "John E. Rodstrom". The canvass wins.
--
-- · County Commissioner, District 6 **Universal Primary Contest** (2026-08-18):
--     Caryl Shuham        8,337   41.89%
--     Eugen Bold          5,516   27.72%
--     A. J. Ryan          4,218   21.19%
--     Jeffery Jones       1,830    9.20%
--                        ──────
--                        19,901   (sums exactly)
--   🔑 **BROWARD'S COUNTY SEATS FINISH IN AUGUST, NOT NOVEMBER.** The November general carried
--   no county commission contest at all — only three Broward questions. In a county this
--   lopsided a partisan race with one party's candidates only becomes a universal primary open
--   to every voter, and it decides the seat. Looking for these contests on the general-election
--   page finds nothing and proves nothing.
--   District 6 was open because Beam Furr is TERM-LIMITED under § 2.02, so his term closes
--   `term_expired`, not `defeated` — he was not on any ballot to lose.
--
-- · Districts 2, 4 and 8 appear on NEITHER 2026 ballot and in NEITHER qualified-candidate list.
--   They were unopposed: Florida Politics reported at the close of qualifying that Mark Bogen
--   (D2), Lamar Fisher (D4) and Robert McKinzie (D8) were the only candidates to qualify and
--   so return without facing voters. Their 2022 terms are seated closed at 2026-11-16 and their
--   new terms open 2026-11-17 — two rows each, because they are two terms.
--
-- ══ 5. IDENTITY ════════════════════════════════════════════════════════════════════════════
-- All 21 people are new. Checked 2026-11-13 against `politicians` by surname and by full-name
-- substring; every hit was somebody else:
--   · **George Moraitis** EXISTS and is NOT Heather Moraitis — a former Florida House member
--     from Fort Lauderdale, a different person who happens to share the surname. Guard on the
--     full name, never on `Moraitis`.
--   · Rodney Glassman (AZ) ≠ Steven Glassman · Eric Sorensen (IL, U.S. House) ≠ Ben Sorensen ·
--     Janice / Melissa / Olivia Rich ≠ Nan H. Rich · Joe Davis (IN) ≠ Alexandra P. Davis ·
--     "FORMAN, FRIENDS OF ALEX" and friends are California campaign committees.
-- Every row this migration creates carries `source LIKE 'CC_0420 %'`, and the inserts are
-- guarded on that, so a re-run is a no-op rather than a duplicate roster.
--
-- @incumbency-decision: gated — this file opens 24 `office_terms` rows on 19 brand-new offices
-- that no `race_candidates` row can possibly reference yet, because both governments are being
-- created here. The guard below measures that rather than asserting it.
--
-- Pure DML, so applied over DATABASE_URL (`ev_api` holds BYPASSRLS) after a COMMIT→ROLLBACK dry
-- run, and verified on row counts and on occupancy at four named dates, never on the absence of
-- an error.
--
-- ⚠ HONEST NOTE ON BLOCKS A AND B BELOW. They were pasted in AFTER the apply: the first draft
-- carried a hand-rolled guard, and `check-office-terms-incumbency-guards.mjs` correctly refused
-- it for missing both halves of the delta and the multi-seat chamber rule. The blocks are pure
-- measurement — they read, assert and write nothing — so the rows in production are exactly what
-- this file produces. The guard was then run standalone against production inside a
-- BEGIN/ROLLBACK, and passed: 21 planned, 0 with a race row in the last year, 0 newly drifted.

BEGIN;

-- ── Pre-condition: this really is greenfield. ──────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.governments
   WHERE state = 'FL' AND geo_id IN ('12011', '1224000');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0420 pre: a government already exists for Broward (12011) or Fort Lauderdale (1224000) — % row(s). Stop and reconcile.', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CC_0420 %';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0420 pre: % politician row(s) already carry this migration''s source — it has run before.', v_n;
  END IF;
END $$;

-- ══ GOVERNMENTS ════════════════════════════════════════════════════════════════════════════
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
VALUES ('Broward County, Florida, US',        'County', 'FL', NULL,              '12011',   'G4020'),
       ('City of Fort Lauderdale, Florida, US','City',   'FL', 'Fort Lauderdale', '1224000', 'G4110');

-- ══ CHAMBERS ═══════════════════════════════════════════════════════════════════════════════
-- Broward: two chambers, NOT Miami-Dade's three. See the note on § 2.03.A above.
-- ⚠ `chambers.slug` is a GENERATED ALWAYS column — slugified `name_formal`, not `name`. Writing
-- it directly fails with "cannot insert a non-DEFAULT value into column slug". So the slugs the
-- rest of this file joins on are produced by setting `name_formal`, exactly as Miami's
-- `miami-city-commission` and `city-of-miami-office-of-the-mayor` were.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length,
                                 term_limit, staggered_term, website_url, election_rules)
SELECT g.id, v.name, v.name_formal, v.cnt, 4, 3, v.staggered, v.url, v.rules
  FROM essentials.governments g
  JOIN (VALUES
    ('12011', 'Board of County Commissioners', 'Broward Board of County Commissioners', 9, true,
     'https://www.broward.org/Commission',
     'Charter s. 2.01: nine members elected by district on a PARTISAN basis; terms begin on the Tuesday two weeks following the general or special election. Districts 1/3/5/7/9 and 2/4/6/8 alternate. s. 2.02: three consecutive four-year terms. s. 2.03: the Mayor and Vice-Mayor are elected ANNUALLY BY THE COMMISSION, so neither is an office here.'),
    ('12011', 'Elected Officials', 'Broward County Elected Officials', 5, false,
     'https://browardvotes.gov/candidates/elected-officials',
     'Countywide constitutional officers under Art. VIII s. 1(d), Fla. Const. Terms commence per Fla. Stat. s. 100.041(4), the first Tuesday after the first Monday in January following election. Broward elects a Tax Collector following Amendment 10 (2018).'),
    ('1224000', 'City Commission', 'Fort Lauderdale City Commission', 4, false,
     'https://www.fortlauderdale.gov/government/city-commission',
     'Charter s. 7.07: four commissioners elected by district, every fourth year from 2020, on the first Tuesday after the first Monday in November; the nominee receiving the highest number of votes is elected (PLURALITY, no runoff); a sole qualifier is declared elected without an election; terms begin on the first regular meeting day in December. s. 7.01: nonpartisan. Terms run CONCURRENTLY, all four plus the mayor at once.'),
    ('1224000', 'Office of the Mayor', 'City of Fort Lauderdale Office of the Mayor', 1, false,
     'https://www.fortlauderdale.gov/government/city-commission',
     'Charter s. 7.07: the mayor is elected AT LARGE on the same quadrennial cycle and the same plurality rule as the four district commissioners.')
  ) AS v(geo, name, name_formal, cnt, staggered, url, rules) ON v.geo = g.geo_id
 WHERE g.state = 'FL';

-- ══ DISTRICTS ══════════════════════════════════════════════════════════════════════════════
-- ⚠ NO GEOMETRY. `essentials.geo_districts` holds ZERO rows for Miami-Dade and the City of
-- Miami too — the Florida precedent in this database is structure and roster without district
-- polygons. Boundaries are their own phase, and they carry their own live-DB vintage gate.
-- Leads for that phase: the city's ArcGIS at `gis.fortlauderdale.gov/arcgis/rest/services`
-- (the `Election` folder holds only polling places; `GeneralPurpose/gisdata` layer 55 is the
-- citywide "Fort Lauderdale Mayoral District" and has no commission-district layer under an
-- obvious name), and Broward's open-data portal at `geohub-broward.opendata.arcgis.com`.
INSERT INTO essentials.districts (label, district_type, district_id, state, city, mtfcc, geo_id,
                                  ocd_id, num_officials, government_id)
SELECT v.label, v.dtype, v.dnum, 'FL', v.city, v.mtfcc, v.geo, v.ocd, 1, g.id
  FROM essentials.governments g
  JOIN (VALUES
    -- Broward: nine commission districts plus the countywide division.
    ('12011', 'Broward County Commission District 1', 'COUNTY', '1', NULL, 'X0040', 'broward-fl-commissioner-district-1', NULL),
    ('12011', 'Broward County Commission District 2', 'COUNTY', '2', NULL, 'X0040', 'broward-fl-commissioner-district-2', NULL),
    ('12011', 'Broward County Commission District 3', 'COUNTY', '3', NULL, 'X0040', 'broward-fl-commissioner-district-3', NULL),
    ('12011', 'Broward County Commission District 4', 'COUNTY', '4', NULL, 'X0040', 'broward-fl-commissioner-district-4', NULL),
    ('12011', 'Broward County Commission District 5', 'COUNTY', '5', NULL, 'X0040', 'broward-fl-commissioner-district-5', NULL),
    ('12011', 'Broward County Commission District 6', 'COUNTY', '6', NULL, 'X0040', 'broward-fl-commissioner-district-6', NULL),
    ('12011', 'Broward County Commission District 7', 'COUNTY', '7', NULL, 'X0040', 'broward-fl-commissioner-district-7', NULL),
    ('12011', 'Broward County Commission District 8', 'COUNTY', '8', NULL, 'X0040', 'broward-fl-commissioner-district-8', NULL),
    ('12011', 'Broward County Commission District 9', 'COUNTY', '9', NULL, 'X0040', 'broward-fl-commissioner-district-9', NULL),
    ('12011', 'Broward County', 'COUNTY', NULL, NULL, 'G4020', '12011',
     'ocd-division/country:us/state:fl/county:broward'),
    -- Fort Lauderdale: four commission districts plus the citywide division.
    ('1224000', 'Fort Lauderdale City Commission District 1', 'LOCAL', '1', 'Fort Lauderdale', 'X0041', 'fort-lauderdale-fl-commission-district-1', NULL),
    ('1224000', 'Fort Lauderdale City Commission District 2', 'LOCAL', '2', 'Fort Lauderdale', 'X0041', 'fort-lauderdale-fl-commission-district-2', NULL),
    ('1224000', 'Fort Lauderdale City Commission District 3', 'LOCAL', '3', 'Fort Lauderdale', 'X0041', 'fort-lauderdale-fl-commission-district-3', NULL),
    ('1224000', 'Fort Lauderdale City Commission District 4', 'LOCAL', '4', 'Fort Lauderdale', 'X0041', 'fort-lauderdale-fl-commission-district-4', NULL),
    ('1224000', 'Fort Lauderdale Citywide', 'LOCAL', NULL, 'Fort Lauderdale', 'G4110', '1224000', NULL)
  ) AS v(gov, label, dtype, dnum, city, mtfcc, geo, ocd) ON v.gov = g.geo_id
 WHERE g.state = 'FL';

-- ══ OFFICES ════════════════════════════════════════════════════════════════════════════════
-- ⚖ Titles follow the ballot-truth rule: the seat AS THE BALLOT ELECTS IT. Broward's ballot
-- says "County Commissioner, District 6", so that is the title here — which differs from
-- Miami-Dade's existing "Commissioner, District N" rows. The ballot wins; the divergence is
-- deliberate. Fort Lauderdale's ballot prefixes the municipality ("Fort Lauderdale,
-- Commissioner, District 1") only because the Supervisor of Elections runs 31 municipalities on
-- one sheet; the seat itself is "Commissioner, District 1".
INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state,
                                representing_city, partisan_type, seats)
SELECT v.title, c.id, d.id, 'FL', v.city, v.partisan, 1
  FROM (VALUES
    ('broward-board-of-county-commissioners', 'County Commissioner, District 1', 'broward-fl-commissioner-district-1', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 2', 'broward-fl-commissioner-district-2', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 3', 'broward-fl-commissioner-district-3', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 4', 'broward-fl-commissioner-district-4', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 5', 'broward-fl-commissioner-district-5', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 6', 'broward-fl-commissioner-district-6', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 7', 'broward-fl-commissioner-district-7', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 8', 'broward-fl-commissioner-district-8', NULL, 'partisan'),
    ('broward-board-of-county-commissioners', 'County Commissioner, District 9', 'broward-fl-commissioner-district-9', NULL, 'partisan'),
    ('broward-county-elected-officials', 'Sheriff',                      '12011', NULL, 'partisan'),
    ('broward-county-elected-officials', 'Property Appraiser',           '12011', NULL, 'partisan'),
    ('broward-county-elected-officials', 'Supervisor of Elections',      '12011', NULL, 'partisan'),
    ('broward-county-elected-officials', 'Clerk of the Circuit Court',   '12011', NULL, 'partisan'),
    ('broward-county-elected-officials', 'Tax Collector',                '12011', NULL, 'partisan'),
    ('fort-lauderdale-city-commission', 'Commissioner, District 1', 'fort-lauderdale-fl-commission-district-1', 'Fort Lauderdale', 'nonpartisan'),
    ('fort-lauderdale-city-commission', 'Commissioner, District 2', 'fort-lauderdale-fl-commission-district-2', 'Fort Lauderdale', 'nonpartisan'),
    ('fort-lauderdale-city-commission', 'Commissioner, District 3', 'fort-lauderdale-fl-commission-district-3', 'Fort Lauderdale', 'nonpartisan'),
    ('fort-lauderdale-city-commission', 'Commissioner, District 4', 'fort-lauderdale-fl-commission-district-4', 'Fort Lauderdale', 'nonpartisan'),
    ('city-of-fort-lauderdale-office-of-the-mayor', 'Mayor', '1224000', 'Fort Lauderdale', 'nonpartisan')
  ) AS v(chamber_slug, title, district_geo, city, partisan)
  JOIN essentials.chambers c ON c.slug = v.chamber_slug
  JOIN essentials.districts d ON d.geo_id = v.district_geo AND d.state = 'FL';

-- ══ PEOPLE AND TERMS ═══════════════════════════════════════════════════════════════════════
CREATE TEMP TABLE ftl_seed (
  chamber_slug text, office_title text,
  full_name text, first_name text, last_name text, party text, party_short text,
  term_start date, term_end date, how_started text, how_ended text, note text
) ON COMMIT DROP;

INSERT INTO ftl_seed VALUES
-- ── Broward commission, odd districts: elected 2024-11-05, seated 2024-11-19 → 2028-11-21 ──
('broward-board-of-county-commissioners','County Commissioner, District 1','Nan H. Rich','Nan','Rich','Democratic','D','2024-11-19','2028-11-21','elected',NULL,'odd-district cycle'),
('broward-board-of-county-commissioners','County Commissioner, District 3','Michael I. Udine','Michael','Udine','Democratic','D','2024-11-19','2028-11-21','elected',NULL,'odd-district cycle'),
('broward-board-of-county-commissioners','County Commissioner, District 5','Steven Anthony Geller','Steven','Geller','Democratic','D','2024-11-19','2028-11-21','elected',NULL,'odd-district cycle'),
('broward-board-of-county-commissioners','County Commissioner, District 7','Alexandra P. Davis','Alexandra','Davis','Democratic','D','2024-11-19','2028-11-21','elected',NULL,'odd-district cycle'),
('broward-board-of-county-commissioners','County Commissioner, District 9','Hazelle Rogers','Hazelle','Rogers','Democratic','D','2024-11-19','2028-11-21','elected',NULL,'odd-district cycle'),
-- ── Broward commission, even districts: 2022 term closing 2026-11-16, new term from 2026-11-17 ──
('broward-board-of-county-commissioners','County Commissioner, District 2','Mark D. Bogen','Mark','Bogen','Democratic','D','2022-11-22','2026-11-16','elected','term_expired','2022 term'),
('broward-board-of-county-commissioners','County Commissioner, District 2','Mark D. Bogen','Mark','Bogen','Democratic','D','2026-11-17','2030-11-19','elected',NULL,'re-elected UNOPPOSED 2026'),
('broward-board-of-county-commissioners','County Commissioner, District 4','Lamar Fisher','Lamar','Fisher','Democratic','D','2022-11-22','2026-11-16','elected','term_expired','2022 term'),
('broward-board-of-county-commissioners','County Commissioner, District 4','Lamar Fisher','Lamar','Fisher','Democratic','D','2026-11-17','2030-11-19','elected',NULL,'re-elected UNOPPOSED 2026'),
('broward-board-of-county-commissioners','County Commissioner, District 8','Robert McKinzie','Robert','McKinzie','Democratic','D','2022-11-22','2026-11-16','elected','term_expired','2022 term'),
('broward-board-of-county-commissioners','County Commissioner, District 8','Robert McKinzie','Robert','McKinzie','Democratic','D','2026-11-17','2030-11-19','elected',NULL,'re-elected UNOPPOSED 2026'),
-- ── District 6: Furr term-limited out, Shuham in on the August universal primary ──
('broward-board-of-county-commissioners','County Commissioner, District 6','Quentin "Beam" Furr','Quentin','Furr','Democratic','D','2022-11-22','2026-11-16','elected','term_expired','TERM-LIMITED under Charter s. 2.02; not on any 2026 ballot'),
('broward-board-of-county-commissioners','County Commissioner, District 6','Caryl Shuham','Caryl','Shuham','Democratic','D','2026-11-17','2030-11-19','elected',NULL,'won the 2026-08-18 Universal Primary Contest, 8,337 of 19,901 (41.89%)'),
-- ── Broward constitutional officers: elected 2024-11-05, seated 2025-01-07 → 2029-01-02 ──
('broward-county-elected-officials','Sheriff','Gregory Tony','Gregory','Tony','Democratic','D','2025-01-07','2029-01-02','elected',NULL,'Fla. Stat. s. 100.041(4)'),
('broward-county-elected-officials','Property Appraiser','Martin "Marty" Kiar','Martin','Kiar','Democratic','D','2025-01-07','2029-01-02','elected',NULL,'Fla. Stat. s. 100.041(4)'),
('broward-county-elected-officials','Supervisor of Elections','Joe Scott','Joe','Scott','Democratic','D','2025-01-07','2029-01-02','elected',NULL,'Fla. Stat. s. 100.041(4)'),
('broward-county-elected-officials','Clerk of the Circuit Court','Brenda D. Forman','Brenda','Forman','Democratic','D','2025-01-07','2029-01-02','elected',NULL,'Fla. Stat. s. 100.041(4)'),
('broward-county-elected-officials','Tax Collector','Abbey Ajayi','Abbey','Ajayi','Democratic','D','2025-01-07','2029-01-02','elected',NULL,'Fla. Stat. s. 100.041(4); Broward elects one after Amendment 10'),
-- ── Fort Lauderdale regular seats: 2024-12-03 → 2028-12-05 ──
('city-of-fort-lauderdale-office-of-the-mayor','Mayor','Dean Trantalis','Dean','Trantalis','Nonpartisan','NP','2024-12-03','2028-12-05','elected',NULL,'2024 plurality, 30,077 of 78,347 (38.39%)'),
('fort-lauderdale-city-commission','Commissioner, District 2','Steven Glassman','Steven','Glassman','Nonpartisan','NP','2024-12-03','2028-12-05','elected',NULL,'2024 majority, 10,628 (53.34%)'),
('fort-lauderdale-city-commission','Commissioner, District 3','Pamela Beasley-Pittman','Pamela','Beasley-Pittman','Nonpartisan','NP','2024-12-03','2028-12-05','elected',NULL,'sole qualifier: DECLARED elected under Charter s. 7.07, no election held'),
('fort-lauderdale-city-commission','Commissioner, District 4','Ben Sorensen','Ben','Sorensen','Nonpartisan','NP','2024-12-03','2028-12-05','elected',NULL,'2024 plurality, 8,101 of 20,460 (39.59%)'),
-- ── Fort Lauderdale District 1: resignation, 28 vacant days, then the special-election winner ──
('fort-lauderdale-city-commission','Commissioner, District 1','John C. Herbst','John','Herbst','Nonpartisan','NP','2024-12-03','2026-11-02','elected','resigned','resignation effective 11:59 p.m. 2026-11-02, Resolution 26-88'),
('fort-lauderdale-city-commission','Commissioner, District 1','Heather Moraitis','Heather','Moraitis','Nonpartisan','NP','2026-12-01','2028-12-05','elected',NULL,'special election 2026-11-03, 8,553 of 17,441 (49.04%); term set by Resolution 26-88 s. 3');

INSERT INTO essentials.politicians (full_name, first_name, last_name, party, party_short_name,
                                    is_active, source)
SELECT DISTINCT s.full_name, s.first_name, s.last_name, s.party, s.party_short, true,
       'CC_0420 Broward County + City of Fort Lauderdale seed, read 2026-11-13 from browardvotes.gov elected-officials roster, the OFFICIAL Broward canvasses, the Broward County Charter (rev. 2024-11-05) and the Fort Lauderdale Charter'
  FROM ftl_seed s;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK A — incumbency guard, snapshot BEFORE the write ▼▼
-- Pasted verbatim from backend/migrations/_templates/office_terms_incumbency_guard.sql, with the
-- plan table pointed at `ftl_plan`. The `expected` expression and its three WHERE clauses are
-- character-identical to reconcile-incumbency.mjs's computeIncumbencyDrift, multi-seat chamber
-- rule included.
CREATE TEMP TABLE ftl_plan ON COMMIT DROP AS
SELECT p.id AS politician_id FROM essentials.politicians p WHERE p.source LIKE 'CC_0420 %';

CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM ftl_plan);
-- ▲▲ END BLOCK A ▲▲

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,
                                     start_precision, how_started, how_ended, source)
SELECT o.id, p.id, s.term_start, s.term_end, 'day', s.how_started, s.how_ended,
       'CC_0420 ' || s.note
  FROM ftl_seed s
  JOIN essentials.chambers c ON c.slug = s.chamber_slug
  JOIN essentials.offices o  ON o.chamber_id = c.id AND o.title = s.office_title
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source LIKE 'CC_0420 %';

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK B — incumbency guard, the delta ▼▼
-- Expected reading here: "21 person/people planned, 0 with a race row in the last year". That is
-- the template's FIRST case — nobody touched has run recently — and it is distinguishable from a
-- mis-pointed plan only because the PLAN count is 21 rather than 0. Both governments are created
-- by this very file, so no `race_candidates` row can reference these offices yet.
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM ftl_plan;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;
-- ▲▲ END BLOCK B ▲▲

-- ══ POST-CONDITIONS ════════════════════════════════════════════════════════════════════════
DO $$
DECLARE v_n int; v_who text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.governments WHERE geo_id IN ('12011','1224000') AND state='FL';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0420 post: expected 2 governments, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('12011','1224000');
  IF v_n <> 4 THEN RAISE EXCEPTION 'CC_0420 post: expected 4 chambers, got % (Broward must have TWO — it has no elected mayor)', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts d
    JOIN essentials.governments g ON g.id = d.government_id
   WHERE g.geo_id IN ('12011','1224000');
  IF v_n <> 15 THEN RAISE EXCEPTION 'CC_0420 post: expected 15 districts (9+1 county, 4+1 city), got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('12011','1224000');
  IF v_n <> 19 THEN RAISE EXCEPTION 'CC_0420 post: expected 19 offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CC_0420 %';
  IF v_n <> 21 THEN RAISE EXCEPTION 'CC_0420 post: expected 21 people, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE source LIKE 'CC_0420 %';
  IF v_n <> 24 THEN RAISE EXCEPTION 'CC_0420 post: expected 24 term rows, got %', v_n; END IF;

  -- No office may resolve to two people on any of the dates this migration straddles.
  SELECT count(*) INTO v_n FROM (
    SELECT t.office_id, d.day
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
      CROSS JOIN (VALUES (DATE '2026-11-13'), (DATE '2026-11-16'), (DATE '2026-11-17'),
                         (DATE '2026-11-30'), (DATE '2026-12-01')) AS d(day)
     WHERE g.geo_id IN ('12011','1224000')
       AND (t.term_start IS NULL OR t.term_start <= d.day)
       AND (t.term_end   IS NULL OR t.term_end   >= d.day)
     GROUP BY t.office_id, d.day HAVING count(*) > 1) x;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CC_0420 post: % office/date pair(s) resolve to more than one person', v_n; END IF;

  -- Broward District 6 flips at the charter date and not before.
  SELECT p.full_name INTO v_who FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE o.title = 'County Commissioner, District 6'
     AND t.term_start <= DATE '2026-11-16' AND t.term_end >= DATE '2026-11-16';
  IF v_who IS DISTINCT FROM 'Quentin "Beam" Furr' THEN
    RAISE EXCEPTION 'CC_0420 post: on 2026-11-16 Broward D6 should still be Furr, got %', coalesce(v_who,'(nobody)');
  END IF;

  SELECT p.full_name INTO v_who FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE o.title = 'County Commissioner, District 6'
     AND t.term_start <= DATE '2026-11-17' AND t.term_end >= DATE '2026-11-17';
  IF v_who IS DISTINCT FROM 'Caryl Shuham' THEN
    RAISE EXCEPTION 'CC_0420 post: on 2026-11-17 Broward D6 should be Shuham, got %', coalesce(v_who,'(nobody)');
  END IF;

  -- Fort Lauderdale District 1 is VACANT today and fills on 2026-12-01, not on the 17th.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.slug = 'fort-lauderdale-city-commission' AND o.title = 'Commissioner, District 1'
     AND t.term_start <= DATE '2026-11-17' AND t.term_end >= DATE '2026-11-17';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0420 post: Fort Lauderdale D1 must be VACANT on 2026-11-17 (Res. 26-88 starts the term 12-01, the 17th is only the ceremony) — found % holder(s)', v_n;
  END IF;

  SELECT p.full_name INTO v_who FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE c.slug = 'fort-lauderdale-city-commission' AND o.title = 'Commissioner, District 1'
     AND t.term_start <= DATE '2026-12-01' AND t.term_end >= DATE '2026-12-01';
  IF v_who IS DISTINCT FROM 'Heather Moraitis' THEN
    RAISE EXCEPTION 'CC_0420 post: on 2026-12-01 Fort Lauderdale D1 should be Moraitis, got %', coalesce(v_who,'(nobody)');
  END IF;

  -- Today: 18 of the 19 seats are filled, D1 being the one that is not.
  SELECT count(*) INTO v_n FROM essentials.current_office_holders ch
    JOIN essentials.offices o ON o.id = ch.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('12011','1224000');
  IF v_n <> 18 THEN
    RAISE EXCEPTION 'CC_0420 post: expected 18 of 19 seats filled today (Fort Lauderdale D1 vacant), got %', v_n;
  END IF;

  -- Heather Moraitis must not have been fused with George Moraitis, who is a different person.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE last_name = 'Moraitis' AND is_active;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0420 post: expected exactly 2 active Moraitis rows (George, pre-existing, and Heather, new), got %', v_n;
  END IF;

  RAISE NOTICE 'CC_0420 ok: Broward County + Fort Lauderdale seeded — 2 governments, 4 chambers, 15 districts, 19 offices, 21 people, 24 terms; 18 seats filled today.';
END $$;

COMMIT;
