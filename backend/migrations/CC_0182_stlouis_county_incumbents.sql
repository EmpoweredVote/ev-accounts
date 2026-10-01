-- CC_0182_stlouis_county_incumbents.sql
-- St. Louis MO deep seed, wave 4 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0181, which creates the government, 4 chambers, 7 council districts
-- and 10 offices.
--
-- Seats all 10 of St. Louis County's elected officials. Creates 10 people, reuses 0.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT, AND THIS WAVE HAS A LIVE CASE.
-- WESLEY BELL won Prosecuting Attorney in Nov 2022 with 70.69% and then won a US House seat.
-- Charter § 5.050 fills that vacancy by county executive appointment with council confirmation.
-- The office's own site names PROSECUTOR MELISSA PRICE SMITH, and she went on to win the
-- Aug 2026 Democratic primary with 74.10%. Bell is NOT seated here.
--
-- Every other seat was cross-checked the same way: the certified winner against the county's own
-- published roster, read 2026-09-29. Nine of ten agree.
--   ⚠ THAT CROSS-CHECK IS WHAT CAUGHT A TRUNCATED CSV. A short Nov 2024 file — HTTP 200, curl
--   exit 0 — held only part of District 6 and named KEVIN SCHARTNER the winner at 53.13%. The
--   complete file names G. MICHAEL ARCHER at 52.50%, which is who the council publishes. A
--   certified tally verifies nothing about itself. See CC_0181 and county-results/FETCH.md.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE TWO COUNCIL COHORTS FLOOR AT DIFFERENT DATES, AND THAT IS THE POINT OF THIS FILE.
-- Ruled 2026-09-29 (Cantrell), and it is the same rule wave 2 used for the General Assembly
-- (2023-01-04) and wave 3 for the city wards (2023-04-18): office_terms models OCCUPANCY OF THE
-- SEAT AS CURRENTLY DRAWN, floored at the first day that seat existed in its current shape.
--
-- Charter § 2.035 orders reapportionment within thirty days before June 1 each tenth year, so the
-- current map is the 2021 commission's. § 2.040 staggers the council: even districts elected 1980
-- + 4n, odd districts 1982 + 4n. Therefore:
--
--   districts 1, 3, 5, 7  first elected on the CURRENT map Nov 2022  -> floor 2023-01-10
--   districts 2, 4, 6     last  elected on the OLD     map Nov 2020
--                         first elected on the CURRENT map Nov 2024  -> floor 2025-01-07
--
-- ⚠ SHALONDA WEBB'S ROW UNDERSTATES HER, ON PURPOSE. She has held District 4 since 2021 and
-- chaired the council in 2023-2024 — the 2023-01-10 journal's roll call names her presiding. But
-- District 4 was redrawn under her, so her occupancy of the district AS IT IS NOW DRAWN begins
-- 2025-01-07. Flooring her earlier would make office_holders_as_of() answer with the right person
-- for ground she did not represent.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE DATES COME FROM DOCUMENTS THAT STATE THEM, NOT FROM THE CHARTER'S COMPUTED DAY.
-- §§ 2.040, 3.010, 5.040 and 6.050 all say the officer takes office "on the first Tuesday of
-- January following the election". That is a computed statutory day and CLAUDE.md forbids it as a
-- term start. The JOURNAL OF THE COUNTY COUNCIL is this wave's House Journal: every regular
-- meeting has one, each opens with a ROLL CALL naming the members present, and the January
-- journals report the inauguration as a past fact.
--
--   2023-01-10  Journal of the County Council, Tuesday January 10 2023
--               stlouisco.civicweb.net/document/110433?printPdf=true  (meeting Id 800)
--               County Executive Page: "Today, in Memorial Plaza, we had a moment to celebrate ...
--               the word inauguration means an official beginning."
--               Councilwoman Days: "the inauguration. It was a very nice event this morning."
--               The roll call that night seats all seven members.
--
--   2025-01-07  Journal of the County Council, Tuesday January 7 2025
--               stlouisco.civicweb.net/document/388825?printPdf=true  (meeting Id 25750)
--               Councilman Harder: "We had a great swearing-in ceremony this morning."
--               Councilman Archer: "It was a very special day for getting inaugurated."
--
--   2025-01-03  stlcopa.stlouiscountymo.gov/prosecutor-melissa-price-smith/
--               "Melissa Price Smith was sworn in on Friday, January 3, 2025, as the St. Louis
--               County Prosecuting Attorney."
--
-- ⚠ 2023-01-10 IS THE FIRST DATE A DOCUMENT PLACES THE 2022 COHORT IN THE SEAT. IT IS NOT
-- ASSERTED TO BE THE LEGAL TERM START — the charter's computed first Tuesday was 2023-01-03 and
-- the inauguration came a week later. There was NO council meeting on 2023-01-03 (the meetings API
-- was read for 2022-12-25..2023-01-12; the first council meeting of the term is 2023-01-10). The
-- source string on every such row says so. For the 2024 cohort the two agree, because 2025-01-07
-- was itself the first Tuesday.
--
-- ⚠ SAM PAGE AND JAKE ZIMMERMAN ARE UNDERSTATED, AND THIS WAS A DECISION. Page has been County
-- Executive since 2019 (he also won an off-cycle Nov 2020 contest; § 3.010 puts the office on
-- 1982 + 4n, so 2020 is not on the cycle) and Zimmerman has been Assessor since 2011. A COUNTYWIDE
-- seat carries no map floor, so their occupancy could reach further back — but no document for the
-- earlier dates was read, and the operator ruled on 2026-09-29 not to chase them. Their rows carry
-- the 2022 cohort's date and say that it understates.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 NO NAME COLLIDES. All 10 were swept with the duplicate-name guard's OWN predicate
-- (lower(btrim(first_name)) AND lower(btrim(last_name)), active rows only) — 0 hits. A full_name
-- sweep is a DIFFERENT, WEAKER test and found only 4 of 6 collisions in wave 2.
--   🟢 That zero was CONTROLLED: the same query with ('Rick','Brattin') returns his row
--   (external_id -290502, MO State Senate District 31), so the sweep is not blind.
--   ⚠ Two alternative name splits were swept too, because the split is a judgement:
--   ('Melissa','Smith') and ('Rita','Heard Days'). Both clean.
-- No guard is lifted anywhere in this file.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY INSERT. It defaults to false since CA_0188, and a
-- seated person inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person.
--
-- 🔴🔴 KEYED ON (geo_id, district_type, title), NEVER ON A LABEL. `St. Louis County` exists in
-- production in MINNESOTA with the same label AND the same seven-member board. The gate asserts as
-- an ABSENCE that Minnesota gained no terms.
--
-- 🟢 THE RESERVED external_id BAND IS -2790432 .. -2790423 (10 ids), MEASURED EMPTY 2026-09-29.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Refuse to run without the structure ───────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US';
  IF v_off <> 10 THEN
    RAISE EXCEPTION 'MO-4 pre-flight: expected 10 St. Louis County MO offices, found % — apply CC_0181 first', v_off;
  END IF;
END $$;

-- ─── 1. The 10 people ─────────────────────────────────────────────────────────

CREATE TEMP TABLE stlco_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO stlco_people(external_id, full_name, first_name, last_name) VALUES
  (-2790423::bigint, 'Rita Heard Days',     'Rita',     'Days'),
  (-2790424::bigint, 'Gretchen Bangert',    'Gretchen', 'Bangert'),
  (-2790425::bigint, 'Dennis Hancock',      'Dennis',   'Hancock'),
  (-2790426::bigint, 'Shalonda D. Webb',    'Shalonda', 'Webb'),
  (-2790427::bigint, 'Lisa D. Clancy',      'Lisa',     'Clancy'),
  (-2790428::bigint, 'Michael Archer',      'Michael',  'Archer'),
  (-2790429::bigint, 'Mark Harder',         'Mark',     'Harder'),
  (-2790430::bigint, 'Sam Page',            'Sam',      'Page'),
  (-2790431::bigint, 'Melissa Price Smith', 'Melissa',  'Price Smith'),
  (-2790432::bigint, 'Jake Zimmerman',      'Jake',     'Zimmerman');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
  'St. Louis County, Missouri elected officials, read 2026-09-29. The OFFICE LIST is closed by ' ||
  'charter § 6.010, which enumerates it NEGATIVELY: "There shall be no elective county officers ' ||
  'other than county executive, council members, prosecuting attorney and assessor." Certified ' ||
  'results from the county''s own Board of Elections agree across both four-year cohorts (Nov ' ||
  '2022, Nov 2024, plus the Aug 2026 primary and Nov 2020 as cross-checks). Council occupancy is ' ||
  'floored at the map change, not the term: the 2021 reapportionment (charter § 2.035) means ' ||
  'districts 1/3/5/7 floor at 2023-01-10 and districts 2/4/6 at 2025-01-07. Dates come from the ' ||
  'Journal of the County Council, which records each inauguration as a past fact and names every ' ||
  'member on its roll call. 🔴 The Prosecuting Attorney is NOT the certified winner: Wesley Bell ' ||
  'won in Nov 2022 and then won a US House seat, and charter § 5.050 filled the vacancy by ' ||
  'appointment. (MO-4) (CC_0182, MO-4)',
  true, true
FROM stlco_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 10 terms ──────────────────────────────────────────────────────────

CREATE TEMP TABLE stlco_terms(
  geo_id text, district_type text, title text, external_id bigint,
  term_start date, start_precision text, how_started text, basis text
) ON COMMIT DROP;

INSERT INTO stlco_terms VALUES
  -- (a) council districts 1, 3, 5, 7 — the ODD cohort, first elected on the current map Nov 2022
  ('stlouis-county-mo-council-1', 'COUNTY', 'Council Member', -2790423, '2023-01-10', 'day', 'elected',
   'District 1, won Nov 2022 unopposed (30,492). Floored at the 2021 map''s first day for an odd district: the Journal of 2023-01-10 records the inauguration that morning and its roll call seats her. NOT the charter''s computed first Tuesday (2023-01-03) — no document states that day and there was no council meeting on it. Council Chair for 2025'),
  ('stlouis-county-mo-council-3', 'COUNTY', 'Council Member', -2790425, '2023-01-10', 'day', 'elected',
   'District 3, won Nov 2022 with 51.22% (33,415). Floored at the 2021 map''s first day for an odd district, from the Journal of 2023-01-10; not the charter''s computed 2023-01-03'),
  ('stlouis-county-mo-council-5', 'COUNTY', 'Council Member', -2790427, '2023-01-10', 'day', 'elected',
   'District 5, won Nov 2022 with 63.78% (39,855). Floored at the 2021 map''s first day for an odd district, from the Journal of 2023-01-10; not the charter''s computed 2023-01-03'),
  ('stlouis-county-mo-council-7', 'COUNTY', 'Council Member', -2790429, '2023-01-10', 'day', 'elected',
   'District 7, won Nov 2022 with 58.40% (36,563). Floored at the 2021 map''s first day for an odd district, from the Journal of 2023-01-10; not the charter''s computed 2023-01-03. Council Vice Chair for 2025'),

  -- (b) council districts 2, 4, 6 — the EVEN cohort, first elected on the current map Nov 2024
  ('stlouis-county-mo-council-2', 'COUNTY', 'Council Member', -2790424, '2025-01-07', 'day', 'elected',
   'District 2, won Nov 2024 with 67.13% (41,364). Floored at the 2021 map''s first day for an EVEN district — 2/4/6 were last elected on the OLD map in Nov 2020. The Journal of 2025-01-07 records the swearing-in that morning and its roll call seats her; 2025-01-07 is also the charter''s first Tuesday, so document and statute agree here'),
  ('stlouis-county-mo-council-4', 'COUNTY', 'Council Member', -2790426, '2025-01-07', 'day', 'elected',
   'District 4, won Nov 2024 with 80.29% (45,763). UNDERSTATES HER PERSONAL TENURE ON PURPOSE: she has held District 4 since 2021 and chaired the council in 2023-2024 (the 2023-01-10 Journal names her presiding), but District 4 was REDRAWN under her by the 2021 commission, so occupancy of the district as currently drawn begins with the first term elected on that map'),
  ('stlouis-county-mo-council-6', 'COUNTY', 'Council Member', -2790428, '2025-01-07', 'day', 'elected',
   'District 6, won Nov 2024 with 52.50% (36,820) over Kevin Schartner. 🔴 A TRUNCATED certified CSV reported the OPPOSITE winner at a believable 53/47; the complete file and the council''s own roster both name Archer. Floored at the 2021 map''s first day for an EVEN district, from the Journal of 2025-01-07'),

  -- (c) the three countywide seats, on the county polygon 29189
  ('29189', 'COUNTY', 'County Executive', -2790430, '2023-01-10', 'day', 'elected',
   'Won Nov 2022 with 51.56% (189,405). UNDERSTATES HIS OCCUPANCY: he has been County Executive since 2019 and also won an off-cycle Nov 2020 contest, and charter § 3.010 puts the office on 1982 + 4n so 2020 is not on the cycle. No document for the earlier dates was read and the operator ruled 2026-09-29 not to chase them. The date is the Journal of 2023-01-10, in which he describes that morning''s inauguration; not the charter''s computed 2023-01-03'),
  ('29189', 'COUNTY', 'Prosecuting Attorney', -2790431, '2025-01-03', 'day', 'appointed',
   '🔴 NOT THE CERTIFIED WINNER. Wesley Bell won Nov 2022 with 70.69% and then won a US House seat; charter § 5.050 fills the vacancy by county executive appointment with council confirmation. Her own office states the date: "Melissa Price Smith was sworn in on Friday, January 3, 2025, as the St. Louis County Prosecuting Attorney." She won the Aug 2026 Democratic primary with 74.10%'),
  ('29189', 'COUNTY', 'County Assessor', -2790432, '2023-01-10', 'day', 'elected',
   'Won Nov 2022 with 57.35% (208,643); charter § 6.050 puts the office on 2014 + 4n. UNDERSTATES HIS OCCUPANCY: he has been Assessor since 2011, and the operator ruled 2026-09-29 not to chase the earlier dates. The date is the Journal of 2023-01-10; not the charter''s computed 2023-01-03');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'St. Louis County MO, MO-4 (CC_0182). ' || t.basis
FROM stlco_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mo'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_missing int; v_noninc int;
  v_odd int; v_even int; v_early_odd int; v_early_even int; v_cw int;
  v_dupe int; v_mn int; v_outside int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2790432 AND -2790423;
  IF v_people <> 10 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 10 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US';
  IF v_terms <> 10 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 10 St. Louis County MO terms, found %', v_terms; END IF;

  -- 🔴 count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a seat
  -- with no holder is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'St. Louis County, Missouri, US';
  IF v_seated <> 10 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 10 seated, found %', v_seated; END IF;

  -- 🔴 Every seat must carry a term, or it is invisible to address search and nothing errors.
  SELECT count(*) INTO v_missing
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_missing <> 0 THEN RAISE EXCEPTION 'MO-4 occupancy gate: % seat(s) carry no term row', v_missing; END IF;

  SELECT count(*) INTO v_noninc
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.name = 'St. Louis County, Missouri, US'
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN RAISE EXCEPTION 'MO-4 occupancy gate: % seated official(s) are not is_incumbent/is_active — they would be hidden from address search', v_noninc; END IF;

  -- 🔴🔴 THE RULING, ASSERTED IN BOTH DIRECTIONS AND PER COHORT. The odd districts floor at
  -- 2023-01-10 and the EVEN ones at 2025-01-07, because 2/4/6 were last elected on the old map.
  SELECT count(*) INTO v_odd
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0076'
     AND (right(d.geo_id, 1)::int % 2) = 1
     AND ot.term_start = DATE '2023-01-10';
  IF v_odd <> 4 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 4 odd-district members at 2023-01-10, found %', v_odd; END IF;

  SELECT count(*) INTO v_even
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0076'
     AND (right(d.geo_id, 1)::int % 2) = 0
     AND ot.term_start = DATE '2025-01-07';
  IF v_even <> 3 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 3 even-district members at 2025-01-07, found %', v_even; END IF;

  SELECT count(*) INTO v_early_odd
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0076' AND (right(d.geo_id, 1)::int % 2) = 1 AND ot.term_start < DATE '2023-01-10';
  IF v_early_odd <> 0 THEN
    RAISE EXCEPTION 'MO-4 occupancy gate: % odd-district term(s) start before 2023-01-10 — that district as currently drawn did not exist then', v_early_odd;
  END IF;

  SELECT count(*) INTO v_early_even
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0076' AND (right(d.geo_id, 1)::int % 2) = 0 AND ot.term_start < DATE '2025-01-07';
  IF v_early_even <> 0 THEN
    RAISE EXCEPTION 'MO-4 occupancy gate: % EVEN-district term(s) start before 2025-01-07 — districts 2, 4 and 6 were last elected on the OLD map in Nov 2020, so occupancy of the current shape cannot begin earlier (this is the trap Shalonda Webb''s long tenure sets)', v_early_even;
  END IF;

  -- The three countywide seats sit on 29189 and carry no map floor of their own.
  SELECT count(*) INTO v_cw
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '29189' AND d.district_type::text = 'COUNTY';
  IF v_cw <> 3 THEN RAISE EXCEPTION 'MO-4 occupancy gate: expected 3 countywide terms on 29189, found %', v_cw; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'St. Louis County, Missouri, US'
     GROUP BY 1 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'MO-4 occupancy gate: % person(s) hold more than one St. Louis County seat', v_dupe; END IF;

  -- 🔴🔴 MINNESOTA MUST HAVE GAINED NOTHING. Asserted as an ABSENCE: no person created here may
  -- hold a seat of the Minnesota homonym, and no term of this wave may sit outside Missouri.
  SELECT count(*) INTO v_mn
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.name = 'St. Louis County, Minnesota, US'
     AND p.external_id BETWEEN -2790432 AND -2790423;
  IF v_mn <> 0 THEN
    RAISE EXCEPTION 'MO-4 occupancy gate: % Missouri person(s) landed on a MINNESOTA St. Louis County seat', v_mn;
  END IF;

  SELECT count(*) INTO v_outside
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE p.external_id BETWEEN -2790432 AND -2790423
     AND lower(coalesce(d.state, '')) <> 'mo';
  IF v_outside <> 0 THEN RAISE EXCEPTION 'MO-4 occupancy gate: % term(s) of this wave sit outside Missouri', v_outside; END IF;

  RAISE NOTICE 'MO-4 occupancy gate PASSED: 10 people, 10 terms, 10 seated, 4 odd-district members at 2023-01-10 and none earlier, 3 EVEN-district members at 2025-01-07 and none earlier, 3 countywide on 29189, 0 double-seated, Minnesota untouched.';
END $$;

COMMIT;
