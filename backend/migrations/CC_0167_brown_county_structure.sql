-- CC_0167_brown_county_structure.sql
-- Knight Foundation program, wave SD-4 (structure half). Slot RESERVED from the allocator.
--
-- Brown County holds NO government row, NO chamber and NO office today. Measured 2026-09-28:
-- production knows Brown County only as a districts row (COUNTY / G4020 / 46013, 0 offices,
-- government_id NULL), its TIGER county polygon, and 8 treasury budgets, 2016-2024. This
-- migration creates:
--
--   1. one government, 'Brown County, South Dakota, US';
--   2. two chambers -- the County Commission and the countywide elected officials;
--   3. NO district -- every office hangs on the EXISTING county district row;
--   4. ten offices -- 5 at-large Commissioners + Auditor + Treasurer + Register of Deeds
--      + Sheriff + State's Attorney.
--
-- Creates NO people and NO terms -- CC_0168 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 BIND ON (mtfcc, geo_id), NEVER ON geo_id ALONE. Measured in production 2026-09-28,
-- geo_id '46013' returns THREE rows:
--
--     c1c642b8-...  Brown County              COUNTY        G4020   <- this migration's district
--     936f262a-...  State House District 13   STATE_LOWER   G5220
--     ac247f14-...  State Senate District 13  STATE_UPPER   G5210
--
-- SD's county GEOIDs run 46003..46137 odd and 17 of the 66 collide with a Senate district number.
-- Every district lookup below carries mtfcc AND district_type. "Brown County" is worse still as a
-- NAME: it resolves NINE ways across the database (IL, IN, KS, MN, NE, OH, SD, TX, WI).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS TEN, AND THREE INDEPENDENT SOURCES AGREE.
--
--   1. THE STATUTE. SDCL 7-7-1.1 elects, in each organized county, a sheriff, county auditor and
--      register of deeds (1974 + every fourth year) and a treasurer, state's attorney and coroner
--      (1976 + every fourth year). SDCL 7-8-1 adds a board of "not less than three nor more than
--      seven" commissioners.
--   2. THE COUNTY'S OWN BALLOT. The Brown County sample ballot for the 4 June 2024 primary,
--      published by the county auditor, carries "For County Commissioner At Large -- You may vote
--      for up to two or leave it blank."
--   3. THE STATE'S AUDITOR. The South Dakota Department of Legislative Audit prints a "COUNTY
--      OFFICIALS" page in every Brown County audit report. As of December 31 in 2021, 2023 and
--      2024 it lists exactly: five commissioners, Auditor, Treasurer, State's Attorney, Register
--      of Deeds, Sheriff. Nothing else, in three consecutive reports.
--
-- 🔴 THE CORONER IS NOT SEATED, AND THAT IS THE COUNTY'S OWN DECISION, NOT AN ABSENCE.
-- Brown County Commission RESOLUTION #08-24, adopted 16 January 2024, "does hereby adopt the
-- option to appoint the Brown County Coroner in lieu of an election pursuant to SDCL 7-7-1.4", and
-- appoints the Sheriff "to serve as coroner at the pleasure of the board". 7-7-1.4 requires that
-- election to be made "not later than the April first preceding the election for coroner"; the
-- coroner's cycle year is 2024, and the resolution predates it. ▶ This is the ND-4 shape proved
-- POSITIVELY -- a named instrument, not three ballots with nothing on them.
--
-- 🔴 THE DIRECTOR OF EQUALIZATION IS NOT SEATED EITHER. SDCL 10-3-3: "The county director of
-- equalization shall be APPOINTED by the board of county commissioners." The county's own
-- department list shows Equalization beside the six elected offices with nothing marking which is
-- which -- the Sedgwick County trap of CC_0161, and the statute is what separates them.
--
-- ⚠ THE CHARTER QUESTION, STATED HONESTLY. SDCL 7-7-1.1 opens "Unless otherwise provided by county
-- charter". Brown County's published ordinance code is 20 titles and contains no charter, and the
-- office set observed is exactly the statutory default with the one statutory opt-out (the
-- coroner) exercised by a resolution that cites the statute by number. SDCL 6-12-11 makes the
-- Secretary of State the keeper of adopted charters; that registry is NOT published online and
-- was not read. ▶ So the negative is not proved directly -- but a charter, if one exists, has not
-- changed the office set, because the set matches the statute it would have had to override.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE COMMISSION IS ELECTED AT LARGE. THIS MIGRATION LOADS NO GEOMETRY AND INVENTS NO
-- COMMISSION DISTRICT. Four independent sources say so:
--
--   1. the county's own sample ballot names the contest "County Commissioner At Large", and the
--      SAME contest with the SAME candidates appears on the ballots of legislative districts 01,
--      03 and 23 -- every voter in the county votes on every seat;
--   2. the Secretary of State's candidate lists name the contest "County Commissioner At Large"
--      in 2016, 2018, 2020, 2022 and 2024 -- five consecutive cycles;
--   3. the Secretary of State's own result pages name it "County Commissioner At Large - Brown";
--   4. the county's Commission page has listed five members with NO district since at least
--      2014-05-27, the earliest archived copy.
--
-- SDCL 7-8-10 is what permits this: at the decennial revision the board "may, at that time, choose
-- to have commissioners elected at large", or from single-member, multi-member or hybrid
-- districts. ▶ So the STATUTE CANNOT SETTLE THE STRUCTURE -- only the county's own record can. Do
-- not read SDCL 7-8-2 ("nomination and election ... by a vote of the voters of the district") as a
-- requirement of districts here; 7-8-10 is the later and more specific grant.
--
-- ⚠ ONE STATUTORY LOOSE END, RECORDED RATHER THAN HIDDEN. SDCL 7-8-1 says a commissioner of an
-- "odd-numbered or unnumbered district" runs in the gubernatorial year. Brown County's seats are
-- unnumbered, yet two of the five are filled in presidential years (Sutton and Dinger, 2024) and
-- three in gubernatorial years (Wiese, Gage, Dennert, 2022). The staggering is real and the county
-- states it -- "5 Commissioners who are elected to staggered terms of 4 years" -- and it survived
-- the move to at-large election, which SDCL 7-8-8 and 7-8-11 expressly provide for. The BALLOT is
-- the fact; the parity rule is not.
--
-- 🔴 FIVE IDENTICAL COMMISSIONER ROWS ON ONE DISTRICT. The guard below is a COUNT, not a
-- NOT EXISTS: a NOT EXISTS guard can only ever create ONE and would silently seat a fifth of the
-- board. Same reason as the Aberdeen council in CC_0165 and the SD House in CC_0163.
-- ▶ Any gate reading "one office per district" is WRONG here. This is the THIRD multi-member body
-- in this slice.
--
-- ⚠ NO SEAT NUMBERS ON THE TITLE. The ballot names one contest, "County Commissioner At Large",
-- and numbers nothing. Writing "(Seat 1)" would put a distinction on a voter-facing title that no
-- Brown County ballot makes.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on an office or a person.
--
-- ⚠ THE COUNTY DISTRICT ROW ALREADY EXISTS AND IS REUSED, NOT DUPLICATED. It carries geometry
-- (G4020 / 46013, valid, SRID 4326, 1,731 sq mi) and today has government_id NULL and 0 offices.
-- This migration attaches it to the new government.
--
-- Idempotent: every INSERT is NOT EXISTS/count-guarded and the one UPDATE is guarded. Ends with a
-- post-verify gate that asserts the END STATE, so a re-run that writes nothing still passes.

BEGIN;

-- ─── 0. Pre-flight: the county district must exist and must carry geometry ───

DO $$
DECLARE v_d int;
BEGIN
  SELECT count(*) INTO v_d
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
   WHERE lower(d.state) = 'sd' AND d.geo_id = '46013' AND d.mtfcc = 'G4020'
     AND d.district_type::text = 'COUNTY';
  IF v_d <> 1 THEN
    RAISE EXCEPTION 'SD-4 pre-flight: expected exactly 1 Brown County district (G4020/46013) WITH geometry, found %. An office on a district with no polygon is unreachable by any address and nothing errors.', v_d;
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Brown County, South Dakota, US', 'County', 'SD', NULL, '46013'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Brown County, South Dakota, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- Both carry four-year terms: SDCL 7-8-1 for the commission, 7-7-1.1 for the five countywide
-- officers. The commission is staggered (3 seats in gubernatorial years, 2 in presidential); the
-- countywide officers are not staggered with one another but sit on two different cycles --
-- sheriff, auditor and register of deeds in 1974 + every fourth year, treasurer and state's
-- attorney in 1976 + every fourth year (SDCL 7-7-1.1).

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Brown County Commission',        5),
  ('Brown County Elected Officials', 5)
) AS v(name, official_count) ON true
WHERE g.name = 'Brown County, South Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Attach the EXISTING county district to the new government ────────────

UPDATE essentials.districts d
   SET government_id = (SELECT id FROM essentials.governments WHERE name = 'Brown County, South Dakota, US'),
       num_officials = 10
 WHERE lower(d.state) = 'sd' AND d.geo_id = '46013' AND d.mtfcc = 'G4020'
   AND d.district_type::text = 'COUNTY'
   AND (d.government_id IS DISTINCT FROM
        (SELECT id FROM essentials.governments WHERE name = 'Brown County, South Dakota, US')
        OR d.num_officials IS DISTINCT FROM 10);

-- ─── 4. The five countywide single-member offices ────────────────────────────
-- Descriptions state the real powers from the statute that creates each duty, never a generic
-- template. ⚠ The AUDITOR's term start is unique in the county -- see CC_0168.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers, description)
SELECT c.id, d.id, v.title, 'SD', 1, false, 'full', v.description
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Brown County Elected Officials'
JOIN essentials.districts d
  ON lower(d.state) = 'sd' AND d.geo_id = '46013' AND d.mtfcc = 'G4020' AND d.district_type::text = 'COUNTY'
JOIN (VALUES
  ('County Auditor',
   'Clerk of the Board of County Commissioners: SDCL 7-10-1 makes the auditor keeper of the board''s official proceedings and of the documents, books, records and maps deposited in the office, and SDCL 7-10-3 requires a monthly verification of the treasurer''s accounts reported to the commission. The auditor is also the county''s election officer -- SDCL 7-10-5 puts on this office the notices of every special and general election, the abstract and canvass of the votes, the certificates of election issued to legislators and to county and precinct officers, and the return of the abstracts to the Secretary of State. Elected countywide for four years. ⚠ Uniquely among Brown County''s elected officers the auditor''s term does NOT begin in January: SDCL 7-7-1 starts it on the FIRST MONDAY OF MARCH after the election.'),
  ('County Treasurer',
   'The county''s collector of taxes. SDCL 7-11-1: the treasurer "is the collector of taxes", must maintain an office at the county seat, and "shall receive all money belonging to the county from whatever source derived". SDCL 7-11-6 bars any disbursement except on a warrant of the county auditor, so the two offices check one another. The treasurer also handles motor-vehicle titling and registration and administers property-tax relief for low-income and elderly owners. Elected countywide for four years, term beginning the first Monday in January (SDCL 7-7-1).'),
  ('Register of Deeds',
   'Keeper of the county''s land record. SDCL 7-9-1 requires the register to "keep full and true records in proper books, of all deeds, mortgages, and other instruments authorized by law to be recorded", together with the chattel mortgages, bills of sale and conditional sale contracts filed in the office. The office also issues South Dakota birth, marriage and death certificates and marriage licences, and records military discharges. Brown County''s records reach back to the 1870s. Elected countywide for four years, term beginning the first Monday in January (SDCL 7-7-1).'),
  ('Sheriff',
   'The county''s chief law-enforcement officer. SDCL 7-12-1: the sheriff "shall keep and preserve the peace within the county", may call to that purpose "such persons or power of his county as he may deem necessary", "must pursue and apprehend all felons", and must execute all writs, warrants and other process directed to the office by legal authority. In Brown County the sheriff also runs the jail, the juvenile detention centre, the communications centre, home detention and the 24/7 sobriety programme. ⚠ The sheriff ALSO serves as county coroner -- not by election but by appointment, under Commission Resolution #08-24 of 16 January 2024 and SDCL 7-7-1.4. Elected countywide for four years, term beginning the first Monday in January (SDCL 7-7-1).'),
  ('State''s Attorney',
   'The county''s prosecutor and its lawyer. SDCL 7-16-9: the state''s attorney "shall appear in all courts of his county and prosecute and defend on behalf of the state or his county all actions or proceedings, civil or criminal, in which the state or county is interested or a party". SDCL 7-16-1 requires the holder to be a licensed attorney. The office also advises the Board of County Commissioners and the other county officers, and carries the county''s child-protection work. Elected countywide for four years, term beginning the first Monday in January (SDCL 7-7-1).')
) AS v(title, description) ON true
WHERE g.name = 'Brown County, South Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title);

-- ─── 5. The five at-large commissioner offices ───────────────────────────────
-- 🔴 A COUNT guard, not a NOT EXISTS: five identical rows on one district. The subquery is
-- evaluated against the statement-start snapshot, so a first run inserts 5 and a re-run inserts 0.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers, description)
SELECT c.id, d.id, 'County Commissioner', 'SD', 1, false, 'full',
       'One of the five members of the Brown County Commission, elected AT LARGE by the voters of the whole county -- the county''s own ballot names the contest "County Commissioner At Large". SDCL 7-8-20 gives the board power to sue on the county''s behalf, to levy taxes within the statutory limit and liquidate debt, to audit the accounts of every officer who handles county money, to build and repair bridges and to open, vacate and change highways, to establish election precincts and appoint the judges of election, to sit as the county board of equalization, to regulate the transaction of business in alcoholic beverages, and "to superintend the fiscal concerns of the county and secure their management in the best possible manner". The board also appoints the county''s Director of Equalization (SDCL 10-3-3) and, since Resolution #08-24, the county coroner (SDCL 7-7-1.4). Four-year term beginning the FIRST TUESDAY of January after the election (SDCL 7-8-1) -- a different day from every other Brown County office, which begin on the first Monday. Terms are staggered: three seats are filled in gubernatorial years and two in presidential years.'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Brown County Commission'
JOIN essentials.districts d
  ON lower(d.state) = 'sd' AND d.geo_id = '46013' AND d.mtfcc = 'G4020' AND d.district_type::text = 'COUNTY'
CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS seat(n)
WHERE g.name = 'Brown County, South Dakota, US'
  AND (SELECT count(*) FROM essentials.offices o
        WHERE o.chamber_id = c.id AND o.district_id = d.id) < seat.n;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_off int; v_comm int; v_wide int;
  v_nogeom int; v_vacant int; v_invented int; v_titles int; v_offdist int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Brown County, South Dakota, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'SD-4 gate: expected 1 Brown County government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_ch <> 2 THEN RAISE EXCEPTION 'SD-4 gate: expected 2 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_off <> 10 THEN RAISE EXCEPTION 'SD-4 gate: expected 10 Brown County offices, found %', v_off; END IF;

  SELECT count(*) FILTER (WHERE c.name = 'Brown County Commission'),
         count(*) FILTER (WHERE c.name = 'Brown County Elected Officials')
    INTO v_comm, v_wide
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_comm <> 5 THEN
    RAISE EXCEPTION 'SD-4 gate: expected 5 at-large County Commissioner offices, found %. The county''s own ballot reads "For County Commissioner At Large -- vote for up to two" and the board is five (SDCL 7-8-1, 7-8-3).', v_comm;
  END IF;
  IF v_wide <> 5 THEN
    RAISE EXCEPTION 'SD-4 gate: expected 5 countywide elected officers (Auditor, Treasurer, Register of Deeds, Sheriff, State''s Attorney), found %', v_wide;
  END IF;

  -- 🔴 THE DEFECT THIS WAVE IS MOST LIKELY TO PRODUCE: inventing commission districts.
  SELECT count(*) INTO v_invented FROM essentials.districts d
   WHERE lower(d.state) = 'sd'
     AND (d.geo_id ILIKE 'brown%commission%' OR d.label ILIKE 'Brown County Commission District%');
  IF v_invented <> 0 THEN
    RAISE EXCEPTION 'SD-4 gate: % Brown County commission district row(s) exist. The commission is elected AT LARGE -- inventing a district is the defect this wave was most likely to produce.', v_invented;
  END IF;

  -- Every office sits on the ONE county district, bound on (mtfcc, geo_id).
  SELECT count(DISTINCT o.district_id) INTO v_offdist
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_offdist <> 1 THEN
    RAISE EXCEPTION 'SD-4 gate: Brown County offices sit on % distinct districts, expected exactly 1 (the county polygon)', v_offdist;
  END IF;

  -- The one failure mode CI cannot catch.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Brown County, South Dakota, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'SD-4 gate: % Brown County office(s) sit on a district with no matching boundary', v_nogeom;
  END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US' AND o.is_vacant;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'SD-4 gate: % Brown County office(s) flagged vacant', v_vacant; END IF;

  -- ⚠ SIX distinct titles, not ten: the five commissioner rows share one title BY DESIGN.
  SELECT count(DISTINCT o.title) INTO v_titles FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_titles <> 6 THEN
    RAISE EXCEPTION 'SD-4 gate: expected 6 distinct office titles (1 shared by the 5 at-large commissioners + 5 countywide), found %', v_titles;
  END IF;

  -- No elected coroner, and no elected director of equalization.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.chambers c ON c.id = o.chamber_id
               JOIN essentials.governments g ON g.id = c.government_id
              WHERE g.name = 'Brown County, South Dakota, US'
                AND (o.title ILIKE '%coroner%' OR o.title ILIKE '%equalization%')) THEN
    RAISE EXCEPTION 'SD-4 gate: a Coroner or Director of Equalization office exists. Both are APPOINTED in Brown County -- Resolution #08-24 of 2024-01-16 under SDCL 7-7-1.4, and SDCL 10-3-3.';
  END IF;

  RAISE NOTICE 'SD-4 structure gate PASSED: 1 government, 2 chambers, 10 offices (5 at-large County Commissioners + Auditor, Treasurer, Register of Deeds, Sheriff, State''s Attorney) all on county district G4020/46013, 0 commission districts invented, 0 vacant.';
END $$;

COMMIT;
