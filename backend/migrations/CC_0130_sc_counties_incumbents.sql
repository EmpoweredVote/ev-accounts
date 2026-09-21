-- CC_0130_sc_counties_incumbents.sql
-- Knight Foundation program, wave SC-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0129, which creates the governments, chambers, districts and the
-- 41 offices.
--
-- Seats 40 of the 41 Richland and Horry county offices:
--    40 people created here, external_id band -2745500 .. -2745401
--     1 person reused — none: every roster name is new to production
--     1 office deliberately left unseated: the VACANT Richland soil-and-water commissioner
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE DIFFERENT STATUTORY COMMENCEMENT DATES APPLY TO THESE 40 SEATS. A wave that used one
-- date for all of them would be wrong by up to six months on four of them:
--    · COUNTY COUNCIL — S.C. Code § 4-9-90: terms commence "on the SECOND of January next
--      following their election". Not the first. ⚠ Richland County's own council page says
--      "January 1"; the statute governs and the disagreement is recorded, not silently resolved.
--    · SHERIFF, CLERK OF COURT, CORONER, PROBATE JUDGE — § 4-11-10: the FIRST TUESDAY IN JANUARY.
--    · AUDITOR AND TREASURER — § 4-11-10, same sentence: "except that the terms of the county
--      auditors and county treasurers shall commence the FIRST DAY OF JULY next following their
--      election" (1987 Act No. 21). Brawley is seated 2007-07-01, Dove 2023-07-01 and Horry's
--      Tina Hardee 2025-07-01 for that reason alone.
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY. Every date below is the first election of the
-- person's CURRENT CONTINUOUS tenure, not their most recent win. Lott is seated from 1997, not
-- from 2025; McCulloch from 1999; Brawley from 2007.
--
-- 🔴🔴 AND 24 OF THE 40 CARRY NO DATE AT ALL, FOR A REASON THAT WAS MEASURED. The South Carolina
-- Election Commission's candidate record (vrems.scvotes.sc.gov) is the authority for who won what,
-- and IT BEGINS AT 2020: election 20620, the 2018 statewide general, holds ZERO candidate rows for
-- any county, office or status. That was confirmed with a positive control — the identical query
-- returns hundreds of rows for 2020, 2022, 2024 and 2026 — so the empty 2018 answer is a true "no
-- data", not a broken query. Where a person's tenure demonstrably reaches back past 2020 and no
-- county page states when it began, the term is OPEN-ENDED at 'unknown'. A start date is never
-- guessed.
--
-- 🔴 THE DATED ROWS EACH REST ON A PUBLISHED SENTENCE, not on an inference:
--     Pugh      "Pugh was elected to office Nov. 3, 2020."                  -> 2021-01-02
--     Mackey    council bulletin: "elected in 2020 and re-elected in 2024"  -> 2021-01-02
--     Little    SEC: the 2020 D3 winner was Yvonne L. McBride               -> 2025-01-02
--     Alleyne   SEC: the 2020 D8 winner was Overture Walker                 -> 2025-01-02
--     Branham   SEC 2022 + bio: BZA then Planning Commission "prior to
--               being elected to Council", so no earlier council service    -> 2023-01-02
--     Newton    not standing again "after serving two terms" (2026-03)      -> 2019-01-02
--     Brawley   "Since his election ... in November 2006"                   -> 2007-07-01
--     McBride   "Prior to being elected Clerk of Court in 2008"             -> 2009-01-06
--     Rutherford "Coroner since 2020"                                       -> 2021-01-05
--     McCulloch "her election as the Probate Judge ... in November of 1998" -> 1999-01-05
--     Lott      "In 1996, he made a successful run for Sheriff"             -> 1997-01-07
--     Dove      "elected Richland County Treasurer in November 2022"        -> 2023-07-01
--     Gardner   "entered electoral politics in 2018 and was re-elected in
--               2022 ... serving his eighth year as Chairman"               -> 2019-01-02
--     Allen     "Al has been a County Council member since 2007"            -> 2007-01-02
--     T. Hardee SEC: the 2020 Auditor was Beth Calhoun, beaten in the 2024
--               primary — so Hardee's tenure starts at the July handover    -> 2025-07-01
--     Beverly   "In November 2022, Judge Beverly was elected Horry County
--               Probate Judge" (he was CHIEF ASSOCIATE judge from 2019 —
--               an associate judgeship is NOT this office)                  -> 2023-01-03
--
-- 🔴 THE VACANT SEAT IS A FACT, NOT AN OMISSION. The SC DNR board record lists one Richland soil
-- and water commissioner seat as "Vacant ... 01/31/27 (E)". CC_0129 set offices.is_vacant on it.
-- NO vacancy SPAN is written, because the date it fell vacant is not published and CLAUDE.md
-- forbids writing a span whose start is a guess. The gate asserts 41 offices and 40 holders.
--
-- ⚠ AND TWO PEOPLE ON THAT BOARD ARE DELIBERATELY NOT SEATED. J. Kenneth Mullis Jr. and James W.
-- Rhodes sit on the Richland board marked (A), appointed by DNR. Rhodes is the trap: the SEC
-- records him WINNING the elected seat in 2022, and he now holds an appointed one. A roster built
-- from the ballot alone would seat him in a seat he no longer has. The ballot says how somebody
-- once arrived; the board record says where they sit now.
--
-- 🔴 ONE ROSTER NAME MATCHES AN EXISTING ROW, AND IT IS A DIFFERENT PERSON:
--     Tom Anderson — the existing Tom Anderson (external_id -4173652) is a COUNCILOR FOR THE CITY
--     OF TIGARD, OREGON. The roster Tom Anderson is Horry County Council's District 7 member and
--     its vice chairman. Different state, different government, different person.
--     A surname pass over every row holding an open term in South Carolina found thirteen more
--     near-misses — Karl B. Allen, Carl L. Anderson, Heather Ammons Crawford, Kevin Hardee, Leon
--     Howard, three Johnsons, Wendell K. Jones, two Newtons, J. Todd Rutherford and Sam P. Johnson
--     — every one a different first name and a different person.
-- ⚠ THE GUARD IS LIFTED FOR 1 ROW, NOT FOR THE MIGRATION. The other 39 are inserted with
-- essentials.politicians' duplicate-name trigger ARMED, so a namesake nobody anticipated still
-- stops this migration.
-- ⚠ AND THE WAVE WAS CHECKED AGAINST ITSELF, which is the SC-2 lesson: Danny Hardee (Council
-- District 10) and Tina Hardee (Auditor) are two sitting Horry officials sharing a surname, and
-- a pre-flight that only asks production would not have looked.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party; the soil-and-water seats are
-- nonpartisan in any case.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

-- ─── 39 people with no active namesake — guard ARMED ──────────────────────────
CREATE TEMP TABLE sc4_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc4_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745401, 'Jason Branham',              'Jason',    'Branham',    '{}'::text[]),
  (-2745402, 'Derrek Levar Pugh',          'Derrek',   'Pugh',       '{"Derrek Pugh"}'::text[]),
  (-2745403, 'Tyra Little',                'Tyra',     'Little',     '{}'::text[]),
  (-2745404, 'Paul Livingston',            'Paul',     'Livingston', '{}'::text[]),
  (-2745405, 'Allison Terracio',           'Allison',  'Terracio',   '{}'::text[]),
  (-2745406, 'Don Weaver',                 'Don',      'Weaver',     '{}'::text[]),
  (-2745407, 'Gretchen D. Cooper',         'Gretchen', 'Cooper',     '{"Gretchen D. Barron","Gretchen Barron"}'::text[]),
  (-2745408, 'Tish Dozier Alleyne',        'Tish',     'Alleyne',    '{"Tish Alleyne"}'::text[]),
  (-2745409, 'Jesica Mackey',              'Jesica',   'Mackey',     '{}'::text[]),
  (-2745410, 'Cheryl D. English',          'Cheryl',   'English',    '{"Cheryl English"}'::text[]),
  (-2745411, 'Chakisse Newton',            'Chakisse', 'Newton',     '{}'::text[]),
  (-2745412, 'Paul Brawley',               'Paul',     'Brawley',    '{}'::text[]),
  (-2745413, 'Jeanette W. McBride',        'Jeanette', 'McBride',    '{"Jeanette McBride"}'::text[]),
  (-2745414, 'Naida Rutherford',           'Naida',    'Rutherford', '{}'::text[]),
  (-2745415, 'Amy McCulloch',              'Amy',      'McCulloch',  '{}'::text[]),
  (-2745416, 'Leon Lott',                  'Leon',     'Lott',       '{}'::text[]),
  (-2745417, 'Kendra L. Dove',             'Kendra',   'Dove',       '{"Kendra Dove"}'::text[]),
  (-2745418, 'Mary Burts',                 'Mary',     'Burts',      '{"Mary S. Burts"}'::text[]),
  (-2745419, 'Timothy McSwain',            'Timothy',  'McSwain',    '{"Tim McSwain"}'::text[]),
  (-2745420, 'Johnny Gardner',             'Johnny',   'Gardner',    '{}'::text[]),
  (-2745421, 'Jenna L. Dukes',             'Jenna',    'Dukes',      '{"Jenna Dukes"}'::text[]),
  (-2745422, 'Bill Howard',                'Bill',     'Howard',     '{}'::text[]),
  (-2745423, 'Dennis DiSabato',            'Dennis',   'DiSabato',   '{}'::text[]),
  (-2745424, 'Gary Loftus',                'Gary',     'Loftus',     '{"Gary M. Loftus"}'::text[]),
  (-2745425, 'Tyler Servant',              'Tyler',    'Servant',    '{}'::text[]),
  (-2745426, 'Cam Crawford',               'Cam',      'Crawford',   '{}'::text[]),
  (-2745428, 'Michael "Mash" Masciarelli', 'Michael',  'Masciarelli','{"Mikey Mash Masciarelli","Michael Masciarelli"}'::text[]),
  (-2745429, 'R. Mark Causey',             'Mark',     'Causey',     '{"Mark Causey"}'::text[]),
  (-2745430, 'Danny Hardee',               'Danny',    'Hardee',     '{"Danny J. Hardee"}'::text[]),
  (-2745431, 'Al Allen',                   'Al',       'Allen',      '{}'::text[]),
  (-2745432, 'Tina Hardee',                'Tina',     'Hardee',     '{}'::text[]),
  (-2745433, 'Renee N. Elvis',             'Renee',    'Elvis',      '{"Renee Elvis"}'::text[]),
  (-2745434, 'Robert L. Edge, Jr.',        'Robert',   'Edge',       '{"Robert Edge"}'::text[]),
  (-2745435, 'R. Allen Beverly, Jr.',      'Allen',    'Beverly',    '{"Allen Beverly"}'::text[]),
  (-2745436, 'Phillip E. Thompson',        'Phillip',  'Thompson',   '{"Phillip Thompson"}'::text[]),
  (-2745437, 'Angie Jones',                'Angie',    'Jones',      '{}'::text[]),
  (-2745438, 'Barry Shane Willoughby',     'Barry',    'Willoughby', '{"Shane Willoughby"}'::text[]),
  (-2745439, 'Glenn Winburn',              'Glenn',    'Winburn',    '{}'::text[]),
  (-2745440, 'Matthew Gene Johnson',       'Matthew',  'Johnson',    '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Richland and Horry county rosters (richlandcountysc.gov/Government/Elected-Offices; horrycountysc.gov/county-council), cross-checked against the SC Association of Counties directory (sccounties.org); office inventory and winners from the SC Election Commission candidate record (vrems.scvotes.sc.gov) for the 2020, 2022, 2024 and 2026 statewide generals; soil-and-water boards from SC DNR (dnr.sc.gov/conservation/districtsdnr); read 2026-09-20 (CC_0130, SC-4)',
       n.alternate_names
FROM sc4_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 1 person who shares a name with a DIFFERENT person — guard lifted ────────
SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sc4_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc4_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
  (-2745427, 'Tom Anderson', 'Tom', 'Anderson', '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Horry County Council roster (horrycountysc.gov/county-council), cross-checked against the SC Association of Counties directory (sccounties.org); distinct from the Tigard, Oregon councilor of the same name (external_id -4173652); read 2026-09-20 (CC_0130, SC-4)',
       n.alternate_names
FROM sc4_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 40 terms, one per SEATED office ──────────────────────────────────────────
-- ⚠ The soil-and-water seats are UNNUMBERED: three offices per county share one title on the
-- county polygon. They are matched by ROW NUMBER within the group, and the match is restricted to
-- offices that are NOT flagged vacant — which is how the vacant Richland seat stays empty without
-- depending on any ordering of uuids.
CREATE TEMP TABLE sc4_terms(gov_geo_id text, district_geo_id text, district_mtfcc text, title text,
                            external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO sc4_terms(gov_geo_id, district_geo_id, district_mtfcc, title, external_id, term_start, start_precision, how_started) VALUES
  -- Richland County Council — § 4-9-90, the second of January
  ('45079','richland-sc-council-district-1', 'X0060','Council Member, District 1', -2745401::bigint,'2023-01-02'::date,'day','elected'),
  ('45079','richland-sc-council-district-2', 'X0060','Council Member, District 2', -2745402::bigint,'2021-01-02'::date,'day','elected'),
  ('45079','richland-sc-council-district-3', 'X0060','Council Member, District 3', -2745403::bigint,'2025-01-02'::date,'day','elected'),
  ('45079','richland-sc-council-district-4', 'X0060','Council Member, District 4', -2745404::bigint,NULL::date,'unknown','unknown'),
  ('45079','richland-sc-council-district-5', 'X0060','Council Member, District 5', -2745405::bigint,NULL::date,'unknown','unknown'),
  ('45079','richland-sc-council-district-6', 'X0060','Council Member, District 6', -2745406::bigint,NULL::date,'unknown','unknown'),
  ('45079','richland-sc-council-district-7', 'X0060','Council Member, District 7', -2745407::bigint,NULL::date,'unknown','unknown'),
  ('45079','richland-sc-council-district-8', 'X0060','Council Member, District 8', -2745408::bigint,'2025-01-02'::date,'day','elected'),
  ('45079','richland-sc-council-district-9', 'X0060','Council Member, District 9', -2745409::bigint,'2021-01-02'::date,'day','elected'),
  ('45079','richland-sc-council-district-10','X0060','Council Member, District 10',-2745410::bigint,NULL::date,'unknown','unknown'),
  ('45079','richland-sc-council-district-11','X0060','Council Member, District 11',-2745411::bigint,'2019-01-02'::date,'day','elected'),
  -- Richland countywide officers — § 4-11-10: July for auditor and treasurer, first Tuesday in
  -- January for the rest
  ('45079','45079','G4020','Auditor',        -2745412::bigint,'2007-07-01'::date,'day','elected'),
  ('45079','45079','G4020','Clerk of Court', -2745413::bigint,'2009-01-06'::date,'day','elected'),
  ('45079','45079','G4020','Coroner',        -2745414::bigint,'2021-01-05'::date,'day','elected'),
  ('45079','45079','G4020','Probate Judge',  -2745415::bigint,'1999-01-05'::date,'day','elected'),
  ('45079','45079','G4020','Sheriff',        -2745416::bigint,'1997-01-07'::date,'day','elected'),
  ('45079','45079','G4020','Treasurer',      -2745417::bigint,'2023-07-01'::date,'day','elected'),
  -- Richland soil and water — two of the three elected seats; the third is vacant
  ('45079','45079','G4020','Soil and Water Conservation District Commissioner',-2745418::bigint,NULL::date,'unknown','unknown'),
  ('45079','45079','G4020','Soil and Water Conservation District Commissioner',-2745419::bigint,NULL::date,'unknown','unknown'),
  -- Horry County Council — the at-large chairman sits on the county polygon
  ('45051','45051','G4020','Chairman',                   -2745420::bigint,'2019-01-02'::date,'day','elected'),
  ('45051','horry-sc-council-district-1', 'X0061','Council Member, District 1', -2745421::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-2', 'X0061','Council Member, District 2', -2745422::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-3', 'X0061','Council Member, District 3', -2745423::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-4', 'X0061','Council Member, District 4', -2745424::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-5', 'X0061','Council Member, District 5', -2745425::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-6', 'X0061','Council Member, District 6', -2745426::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-7', 'X0061','Council Member, District 7', -2745427::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-8', 'X0061','Council Member, District 8', -2745428::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-9', 'X0061','Council Member, District 9', -2745429::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-10','X0061','Council Member, District 10',-2745430::bigint,NULL::date,'unknown','unknown'),
  ('45051','horry-sc-council-district-11','X0061','Council Member, District 11',-2745431::bigint,'2007-01-02'::date,'day','elected'),
  -- Horry countywide officers
  ('45051','45051','G4020','Auditor',        -2745432::bigint,'2025-07-01'::date,'day','elected'),
  ('45051','45051','G4020','Clerk of Court', -2745433::bigint,NULL::date,'unknown','unknown'),
  ('45051','45051','G4020','Coroner',        -2745434::bigint,NULL::date,'unknown','unknown'),
  ('45051','45051','G4020','Probate Judge',  -2745435::bigint,'2023-01-03'::date,'day','elected'),
  ('45051','45051','G4020','Sheriff',        -2745436::bigint,NULL::date,'unknown','unknown'),
  ('45051','45051','G4020','Treasurer',      -2745437::bigint,NULL::date,'unknown','unknown'),
  -- Horry soil and water — all three elected seats are filled
  ('45051','45051','G4020','Soil and Water Conservation District Commissioner',-2745438::bigint,NULL::date,'unknown','unknown'),
  ('45051','45051','G4020','Soil and Water Conservation District Commissioner',-2745439::bigint,NULL::date,'unknown','unknown'),
  ('45051','45051','G4020','Soil and Water Conservation District Commissioner',-2745440::bigint,NULL::date,'unknown','unknown');

WITH office_slot AS (
  SELECT o.id AS office_id, g.geo_id AS gov_geo_id, d.geo_id AS district_geo_id,
         d.mtfcc AS district_mtfcc, o.title,
         row_number() OVER (PARTITION BY g.geo_id, d.geo_id, d.mtfcc, o.title ORDER BY o.id) AS slot
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051')
     AND o.is_vacant = false        -- the vacant Richland soil-and-water seat is never matched
), term_slot AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.district_geo_id, t.district_mtfcc, t.title
                                 ORDER BY t.external_id DESC) AS slot
    FROM sc4_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ts.term_start, NULL, ts.start_precision, ts.how_started,
       'Richland and Horry county rosters (richlandcountysc.gov; horrycountysc.gov), cross-checked against the SC Association of Counties directory (sccounties.org); winners from the SC Election Commission candidate record (vrems.scvotes.sc.gov), 2020/2022/2024/2026; commencement dates from S.C. Code § 4-9-90 (council, second of January) and § 4-11-10 (first Tuesday in January; 1 July for auditor and treasurer); soil-and-water boards from SC DNR; read 2026-09-20 (CC_0130, SC-4)'
FROM term_slot ts
JOIN office_slot os
  ON os.gov_geo_id = ts.gov_geo_id AND os.district_geo_id = ts.district_geo_id
 AND os.district_mtfcc = ts.district_mtfcc AND os.title = ts.title AND os.slot = ts.slot
JOIN essentials.politicians p ON p.external_id = ts.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_offices int; v_terms int; v_seated int; v_dated int; v_ended int;
  v_unseated int; v_double int; v_multi int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2745500 AND -2745401;
  IF v_people <> 40 THEN
    RAISE EXCEPTION 'SC-4 occupancy: expected 40 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');
  IF v_offices <> 41 THEN RAISE EXCEPTION 'SC-4 occupancy: expected 41 county offices, got % — run CC_0129 first', v_offices; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');
  IF v_terms <> 40 THEN RAISE EXCEPTION 'SC-4 occupancy: expected 40 terms, got %', v_terms; END IF;

  -- 🔴 count och.politician_id, never count(*) — office_current_holder LEFT JOINs from offices,
  -- so a vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');
  IF v_seated <> 40 THEN RAISE EXCEPTION 'SC-4 occupancy: expected 40 seated offices, got %', v_seated; END IF;

  -- exactly one office holds no term, and it is the one flagged vacant
  SELECT count(*) INTO v_unseated FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 1 THEN RAISE EXCEPTION 'SC-4 occupancy: expected exactly 1 office with no term, got %', v_unseated; END IF;
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051')
       AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id)
       AND o.is_vacant = false
  ) THEN
    RAISE EXCEPTION 'SC-4 occupancy: an office with no term is NOT flagged vacant — an invisible office';
  END IF;

  SELECT count(*) INTO v_dated FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051') AND ot.term_start IS NOT NULL;
  IF v_dated <> 16 THEN RAISE EXCEPTION 'SC-4 occupancy: expected 16 dated term(s), got %', v_dated; END IF;

  -- The four dates that each carry a rule.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Paul Brawley' AND ot.term_start = DATE '2007-07-01' AND ot.start_precision = 'day')
  THEN RAISE EXCEPTION 'SC-4 occupancy: Brawley is not seated from 2007-07-01 — § 4-11-10 starts an auditor in JULY, not January'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Tina Hardee' AND ot.term_start = DATE '2025-07-01' AND ot.start_precision = 'day')
  THEN RAISE EXCEPTION 'SC-4 occupancy: Tina Hardee is not seated from 2025-07-01 — Beth Calhoun held the Horry auditorship until the July handover'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Leon Lott' AND ot.term_start = DATE '1997-01-07' AND ot.start_precision = 'day')
  THEN RAISE EXCEPTION 'SC-4 occupancy: Lott is not seated from 1997-01-07 — a re-election does not restart an occupancy'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Johnny Gardner' AND ot.term_start = DATE '2019-01-02' AND ot.start_precision = 'day')
  THEN RAISE EXCEPTION 'SC-4 occupancy: Gardner is not seated from 2019-01-02 — § 4-9-90 starts a council term on the SECOND of January'; END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051') AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'SC-4 occupancy: % term(s) carry a term_end — a future end date self-vacates a seat', v_ended; END IF;

  -- no office holds two people, and nobody in this wave holds two offices
  SELECT count(*) INTO v_double FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051') AND ot.term_end IS NULL
     GROUP BY ot.office_id HAVING count(*) > 1) x;
  IF v_double <> 0 THEN RAISE EXCEPTION 'SC-4 occupancy: % office(s) hold more than one open term', v_double; END IF;

  SELECT count(*) INTO v_multi FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.external_id BETWEEN -2745500 AND -2745401 AND ot.term_end IS NULL
     GROUP BY ot.politician_id HAVING count(*) > 1) y;
  IF v_multi <> 0 THEN RAISE EXCEPTION 'SC-4 occupancy: % person(s) from this wave hold more than one seat', v_multi; END IF;

  RAISE NOTICE 'SC-4 occupancy OK: 40 people, 41 offices, 40 terms, 40 seated, 1 flagged vacant and unseated, 16 dated, 0 term_end, 0 double-seated';
END $$;

COMMIT;
