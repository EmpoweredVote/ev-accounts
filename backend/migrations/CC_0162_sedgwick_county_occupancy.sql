-- CC_0162 — KS-4 occupancy: seat Sedgwick County's ten elected officers.
--
-- TEN INSERTS, ZERO REUSES. The duplicate-name check was run with the guard's OWN predicate —
-- `is_active`, and the lower(btrim(first_name)) / lower(btrim(last_name)) PAIR — and all ten return
-- zero active matches. 🟢 The predicate was proved able to find people BEFORE the zeros were
-- believed: `Lily Wu`, `Maggie Ballard` and `Dalton Glasscock`, all seated by CC_0160 in this same
-- slice, return 1 each. A uniform answer is a broken detector until a positive control passes.
-- ⚠ `Kelly Arnold`, `Jeff Easter`, `Marc Bennett`, `Ryan Baty` and `Jim Howell` are ordinary names
-- and were checked, not assumed new. Production holds six other Arnolds, eleven Bennetts and four
-- Howells — including `Leah Howell`, a sitting Kansas Representative seated by CC_0157 — and none is
-- one of these people. `Brandi Baily` was also checked against the spelling `Bailey`, which
-- production holds sixteen of; the guard lowercases and trims but does not normalise spelling.
-- ⚠ `Jeff Blubaugh` and `Pete Meitzner` are FORMER Wichita council members, and CC_0159/CC_0160
-- seated Wichita in this same slice. They are absent because those migrations created only the
-- seven CURRENT holders.
--
-- 🔴 EVERY TERM START IS THE START OF CONTINUOUS OCCUPANCY, WHICH IS NOT THE LAST ELECTION.
-- The county election office's own register (/ElectedOffice/Officials/) carries an ElectionYear
-- column giving the election that seated the CURRENT TERM. Taken as a start date it is wrong for
-- three of these ten, by 3 to 15 years: it reads 2022 for Meitzner (D1 since January 2019), 2022 for
-- Howell (D5 since January 2015) and 2024 for Arnold (clerk since January 2009). Each tenure was
-- walked back through the county's own general-election canvasses — 2000, 2004, 2008, 2012, 2014,
-- 2016 and 2018 as result tables, 2020/2022/2024 as official canvass PDFs.
--
-- 🔴🔴 THE COUNTY TREASURER TAKES OFFICE IN OCTOBER OF THE YEAR AFTER THE ELECTION.
-- KSA 25-313(a) puts every county officer's term at the second Monday of January "except as
-- otherwise provided by law", and KSA 19-501 is that exception: the treasurer's four-year term
-- commences "on the second Tuesday in October following the election". Brandi Baily won in November
-- 2020 and took office 2021-10-12, ELEVEN MONTHS LATER. This was measured, not assumed: the
-- county's own treasurer page named Linda Kizzire on 2021-01-29, 2021-08-01 and 2021-10-09 — three
-- days before the statutory date — and Brandi Baily on 2021-12-03. A January assumption would have
-- put this start 21 months early and asserted Kizzire had left when she had not.
--
-- 🔴🔴 THE REGISTER OF DEEDS WAS APPOINTED, A YEAR BEFORE THE ELECTION THE REGISTER CREDITS.
-- Bill Meek, elected in 2012, DIED IN OFFICE on Sunday 2016-01-10. KSA 19-1203 fills the vacancy
-- "in the manner provided by law for filling vacancies in the office of member of the house of
-- representatives", which KSA 25-3903 makes a party convention followed by appointment by the
-- Governor. Sedgwick County Communications, news release of 2016-01-29: "The new Sedgwick County
-- Register of Deeds will take the oath of office at 4 p.m. TODAY at 525 N. Main, Suite 227 ...
-- She was elected last week to fill the vacancy by the Sedgwick County Republican Party precinct
-- committee. The election was then approved by Governor Brownback on January 22nd."
-- ▶ THREE DATES AND ONLY ONE IS THE TERM START. The precinct vote and the Governor's approval are
-- both quotable and both wrong — this is KS-3's Tuttle trap in its appointment form.
--
-- 🔴 THE CLERK'S START CAME FROM THE MINUTES THE CLERK SIGNS. Web captures left a seven-month
-- window around Arnold's arrival, which did not exclude an early appointment. The BOCC minutes
-- closed it: 2009-01-07 records "Mr. Don Brace, County Clerk" present and marks "the retirement of
-- Don Brace after serving eight years as the County Clerk"; 2009-01-14 is signed "Kelly B. Arnold,
-- County Clerk". Brace served his full term, so Arnold arrived by election.
--
-- ✅ NO EARLY APPOINTMENT FOR THE OTHER EIGHT. Each handover was tested by reading the PREDECESSOR
-- off the county's own page rather than assuming the loser left on time: Hinshaw was still sheriff
-- on 2012-11-27, Foulston still DA on 2013-01-04, Skelton still D5 on 2014-07-01, Cruse still D4 on
-- 2022-11-30, Lopez and Dennis still D2 and D3 on 2024-08-03. 🟢 D5 also has an independent negative
-- control: KSA 19-205 makes a person holding any STATE office ineligible for county commissioner,
-- and Jim Howell sat as Representative for District 81 through the 2013-14 biennium, so he could not
-- lawfully have been seated before January 2015.
--
-- PARTY IS LEFT NULL, DELIBERATELY. Every one of these ten is recorded by the county as a
-- Republican. This repo is antipartisan by design — party lives on races.primary_party, which ballot
-- a voter requests, never on a person.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY INSERT. It defaults to false, and a seated person
-- inserted without it is HIDDEN from address search while nothing errors. check:occupancy fails an
-- INSERT that omits it.
--
-- Idempotent: the inserts are guarded by NOT EXISTS and essentials.seat_officeholder is idempotent
-- by contract, so a second run writes nothing.

BEGIN;

-- ── Guard: the offices must exist ──────────────────────────────────────────────────────────────
DO $$
DECLARE v_offices int;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US';
  IF v_offices <> 10 THEN
    RAISE EXCEPTION 'CC_0162: expected 10 Sedgwick County offices, found %. Apply CC_0161 first.', v_offices;
  END IF;
END $$;

CREATE TEMP TABLE _ks4_roster (
  office_title    text PRIMARY KEY,
  first_name      text NOT NULL,
  last_name       text NOT NULL,
  term_start      date NOT NULL,
  how_started     text NOT NULL,
  source          text NOT NULL
) ON COMMIT DROP;

INSERT INTO _ks4_roster VALUES
 ('County Commissioner, District 1', 'Pete', 'Meitzner', DATE '2019-01-14', 'elected',
  'Sedgwick County official general election results, 2018: Pete Meitzner 20,067 (52.8%) def. Renee Duxler 17,905, 54/54 precincts. Term commenced the second Monday of January following (KSA 19-202(d)). Re-elected 2022 (18,772 v Kelli Grant 16,761) — continuous since 2019. Predecessor Dave Unruh served his full term; the county''s own bio says Meitzner "began his first term ... in January 2019". Read 2026-09-27 (KS-4)'),
 ('County Commissioner, District 2', 'Jeff', 'Blubaugh', DATE '2025-01-13', 'elected',
  'Sedgwick County 2024 General Election Official Results (539/539 precincts): County Commission District 2, Jeff Blubaugh 18,271 def. Sarah Lopez 14,446. Term commenced the second Monday of January following (KSA 19-202(d)). The election office register named Lopez on 2024-08-03 and Blubaugh on 2025-02-14. Read 2026-09-27 (KS-4)'),
 ('County Commissioner, District 3', 'Stephanie', 'Wise', DATE '2025-01-13', 'elected',
  'Sedgwick County 2024 General Election Official Results: County Commission District 3, Stephanie Wise 33,339 def. Celeste Racette 16,288. Term commenced the second Monday of January following (KSA 19-202(d)). The election office register named David Dennis on 2024-08-03 and Wise on 2025-02-14. Read 2026-09-27 (KS-4)'),
 ('County Commissioner, District 4', 'Ryan', 'Baty', DATE '2023-01-09', 'elected',
  'Sedgwick County GN2022 Canvass Official (Nov 8 2022): County Commission 4th District, Ryan Baty 14,025 def. Lacey Cruse 12,525 — confirmed against the county''s own COUNTY TOTALS row in official-2022-general-election_export.csv, because the PDF prints totals above names. Term commenced the second Monday of January following (KSA 19-202(d)). Cruse was still in the register on 2022-11-30, Baty by 2023-03-27. Read 2026-09-27 (KS-4)'),
 ('County Commissioner, District 5', 'Jim', 'Howell', DATE '2015-01-12', 'elected',
  'Sedgwick County official general election results, 2014: County Commissioner DISTRICT 5, Jim Howell 14,696 (63.4%) def. Richard Young 8,458, 51/51 precincts. Term commenced the second Monday of January following (KSA 19-202(d)). Re-elected 2018 and 2022 — continuous since 2015. He sat as Kansas Representative for District 81 through the 2013-14 biennium, and KSA 19-205 bars a state officeholder from the office of county commissioner, so no earlier seating was lawful. Read 2026-09-27 (KS-4)'),
 ('County Clerk', 'Kelly', 'Arnold', DATE '2009-01-12', 'elected',
  'Sedgwick County official general election results, 2008: County Clerk, Kelly Arnold 98,766 (59.3%) def. Genine Ware 67,674, 251/251 precincts. Term commenced the second Monday of January following (KSA 25-313(a)). Bounded by the BOCC minutes the clerk signs: 2009-01-07 records "Mr. Don Brace, County Clerk" present and marks his retirement "after serving eight years"; 2009-01-14 is signed "Kelly B. Arnold, County Clerk". Re-elected 2012, 2016, 2020 and 2024 — continuous since 2009. Read 2026-09-27 (KS-4)'),
 ('County Treasurer', 'Brandi', 'Baily', DATE '2021-10-12', 'elected',
  'Sedgwick County 2020 general election official results: County Treasurer, REP Brandi Baily 122,815 def. DEM Charity Kennedy 85,298. KSA 19-501 commences the treasurer''s term "on the second Tuesday in October following the election" — 2021-10-12, eleven months after the vote and the one county office KSA 25-313(a) does not govern. Measured: the county treasurer page named Linda Kizzire on 2021-10-09 and Brandi Baily on 2021-12-03. Re-elected 2024. Read 2026-09-27 (KS-4)'),
 ('Register of Deeds', 'Tonya', 'Buckingham', DATE '2016-01-29', 'appointed',
  'Sedgwick County Communications news release, January 29 2016: "The new Sedgwick County Register of Deeds will take the oath of office at 4 p.m. today at 525 N. Main, Suite 227. Tonya Buckingham will fill the remainder of Bill Meek''s term. Meek passed away on January 10 ... She was elected last week to fill the vacancy by the Sedgwick County Republican Party precinct committee. The election was then approved by Governor Brownback on January 22nd." Vacancy filled under KSA 19-1203 via 25-3903. The oath date is the term start; the precinct vote and the Governor''s approval are not. Corroborated by the county''s register-of-deeds page, which named Bill Meek on 2015-12-06 and Tonya Buckingham on 2016-02-04. Elected in her own right 2016, 2020 and 2024 — continuous since the appointment. Read 2026-09-27 (KS-4)'),
 ('Sheriff', 'Jeff', 'Easter', DATE '2013-01-14', 'elected',
  'Sedgwick County official general election results, 2012: Sheriff, Jeff Easter 119,617 (71.8%) def. Jefrey Weinman 46,788, 289/289 precincts. Term commenced the second Monday of January following (KSA 25-313(a)). Predecessor Bob Hinshaw, elected 2008, was still named on the county sheriff page on 2012-11-27; Easter by 2013-01-27. Re-elected 2016, 2020 and 2024 — continuous since 2013. Read 2026-09-27 (KS-4)'),
 ('District Attorney, 18th Judicial District', 'Marc', 'Bennett', DATE '2013-01-14', 'elected',
  'Sedgwick County official general election results, 2012: District Attorney 18th District, Marc A. Bennett 112,393 (99.0%), 289/289 precincts. KSA 22a-101(a) commences the term "on the second Monday in January next following his election". Predecessor Nola Foulston, elected 2008, was still named on the county DA page on 2013-01-04; Bennett by 2013-04-03. Re-elected 2016, 2020 and 2024 — continuous since 2013. Read 2026-09-27 (KS-4)');

-- ── The ten people ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, is_incumbent)
SELECT gen_random_uuid(), r.first_name || ' ' || r.last_name, r.first_name, r.last_name,
       true,   -- is_active
       true    -- 🔴 is_incumbent, explicit: they hold the seat
  FROM _ks4_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

-- ── Seat them ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_office uuid; v_pol uuid;
BEGIN
  FOR r IN SELECT * FROM _ks4_roster LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Sedgwick County, Kansas, US' AND o.title = r.office_title;
    IF v_office IS NULL THEN RAISE EXCEPTION 'CC_0162: office "%" not found', r.office_title; END IF;

    SELECT p.id INTO v_pol FROM essentials.politicians p
     WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
       AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
       AND p.is_active;
    IF v_pol IS NULL THEN RAISE EXCEPTION 'CC_0162: politician % % not found', r.first_name, r.last_name; END IF;

    PERFORM essentials.seat_officeholder(v_office, v_pol, r.term_start, r.source, r.how_started, 'day');
  END LOOP;
END $$;

-- ── Post-verify. Asserts the END STATE, so a re-run that writes nothing still passes. ──────────
DO $$
DECLARE v_terms int; v_seated int; v_inc int; v_prec int; v_multi int; v_party int; v_treas date;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US';
  IF v_terms <> 10 THEN RAISE EXCEPTION 'CC_0162: expected 10 office_terms, found %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US';
  IF v_seated <> 10 THEN RAISE EXCEPTION 'CC_0162: expected 10 seated, found %', v_seated; END IF;

  SELECT count(*) INTO v_inc
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND (NOT p.is_incumbent OR NOT p.is_active);
  IF v_inc <> 0 THEN
    RAISE EXCEPTION 'CC_0162: % seated Sedgwick official(s) are not is_incumbent/is_active — they '
                    'would be hidden from address search', v_inc;
  END IF;

  SELECT count(*) INTO v_prec
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND t.start_precision <> 'day';
  IF v_prec <> 0 THEN RAISE EXCEPTION 'CC_0162: % term(s) are not day precision', v_prec; END IF;

  SELECT count(*) INTO v_multi FROM (
    SELECT och.politician_id
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Sedgwick County, Kansas, US' AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) t;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0162: % person(s) hold more than one Sedgwick County seat', v_multi;
  END IF;

  -- Antipartisan by design: party lives on races.primary_party, never on a person.
  SELECT count(*) INTO v_party
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND p.party IS NOT NULL;
  IF v_party <> 0 THEN RAISE EXCEPTION 'CC_0162: % Sedgwick official(s) carry a party', v_party; END IF;

  -- 🔴 The October trap, asserted rather than trusted to the roster literal above. If a later edit
  -- "corrects" the treasurer to a January date, this fails.
  SELECT t.term_start INTO v_treas
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND o.title = 'County Treasurer'
     AND t.term_end IS NULL;
  IF v_treas IS NULL OR extract(month from v_treas) <> 10 THEN
    RAISE EXCEPTION 'CC_0162: the County Treasurer term starts %, not in October. KSA 19-501 '
                    'commences it on the second Tuesday in October of the year AFTER the election, '
                    'and the county page named the predecessor three days before that date.', v_treas;
  END IF;

  RAISE NOTICE 'CC_0162 OK — 10 Sedgwick County officials seated, 10 terms, all day precision, '
               'none holding two seats, treasurer in October.';
END $$;

COMMIT;
