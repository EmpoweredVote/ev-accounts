-- CC_0248_atlanta_wave_occupancy_dates_from_county_returns.sql
--
-- Atlanta / Fulton County / DeKalb County wave — dates 13 of the 20 occupancies that
-- CC_0241, CC_0243, CC_0244 and CC_0245 deliberately left at 'unknown' precision.
--
-- 🔴 WHY THOSE ROWS WERE RIGHT TO BE BLANK, AND WHAT CHANGED.
-- `term_start` in this schema is the start of CONTINUOUS OCCUPANCY of the seat, not the start
-- of the current statutory term. Measured on production before writing this migration:
--   same (office_id, politician_id) pairs holding more than one office_terms row = 0,
--   across 10,556 terms on 10,173 offices.
-- A re-election never opens a new row. So an "(I)" incumbency marker in a certified return
-- proves only that the person already held the seat; it can never date the occupancy. Every
-- row CC_0241/CC_0243 left blank carried "(I)" in 2024, and every county row they DID date
-- (Fulton Surveyor, DeKalb CEO, DeKalb District 4) carried none. That was correct.
--
-- What changed is the SOURCE, not the standard. Three routes were opened:
--   1. DeKalb County publishes its own official results as per-year ZIP archives, 2003-2025,
--      at dekalbcountyga.gov/departments/voter-registration-and-elections/election-results.
--   2. Fulton County's own archive is a Sitecore documents API holding 460 certified
--      Election Summary / SOVC reports back to 1969.
--   3. 🔴 The Secretary of State's per-county payloads carry FEDERAL AND STATE CONTESTS ONLY
--      for 2016, 2018, 2020 and 2022 — its county-office coverage begins with 2024NovGen.
--      Fulton 2022 returns 49 contests and not one county office; Fulton 2024 returns the
--      Clerk, Sheriff, Tax Commissioner, Surveyor and three commission seats. Same parser
--      both times, which is the differential control. Earlier passes read that absence as
--      "no certified chain exists". The chain exists; it is at the COUNTY.
--
-- Every date below is read off a return that says "Official and Complete" (or, for 2024,
-- carries isOfficialResults: true), and rests on the FIRST election the person won WITHOUT an
-- incumbency marker. Each document was controlled: the "(I)" marker was confirmed present in
-- that same document before its absence on a name was read as meaning anything.
--
-- 🔴 PRECISION IS 'month' THROUGHOUT, NEVER 'day'. A certified return fixes the ELECTION.
-- Georgia county terms begin the following January and special-election winners are seated on
-- certification, but no document in this wave states the oath day for any of these 13 people.
-- Claiming a day would invent one. This matches the rule CC_0244 used for the Atlanta council.
--
-- 🔴 THE `| unverified <slot>` TAG IS REMOVED ON EVERY ROW THIS MIGRATION DATES.
-- Per CA_0171, essentials.office_holders_as_of(date) SKIPS terms whose source carries that
-- tag, because an undated open-ended term would otherwise answer every past date. These 13
-- terms now have a start, so they must become visible to historical queries. Leaving the tag
-- would silently keep them out of "who represented me in 2019" for ever.
--
-- 7 of the 20 are NOT dated here and keep their tag. They are listed at the foot of this file.
--
-- Idempotent: re-running changes nothing (each UPDATE is guarded on term_start IS NULL).

BEGIN;

CREATE TEMP TABLE _atl_dates (
  term_id         uuid PRIMARY KEY,
  who             text NOT NULL,
  term_start      date NOT NULL,
  start_precision text NOT NULL,
  source          text NOT NULL
) ON COMMIT DROP;

INSERT INTO _atl_dates (term_id, who, term_start, start_precision, source) VALUES

-- ── City of Atlanta ────────────────────────────────────────────────────────────────────────
('9f40ecdf-80ac-4d09-9d5e-5e90514bc4b9'::uuid,
 'Eshé Collins — Council Member, Post 3 (At Large)',
 DATE '2024-12-01', 'month',
 'Won the certified special-election runoff of 2024-12-03. The seat was filled by SPECIAL election: the Secretary of State''s certified Fulton return for 2024-11-05 lists "Atlanta City Council Post 3 - At Large (SE)" with five candidates and no majority — Nicole "Nikki" Evans Jones 71,824 (40.03%), Collins 43,910 (24.47%) — so a runoff was required. Post 3 is a CITYWIDE seat and Atlanta spans two counties; DeKalb County''s own Election Summary Report for December 03, 2024, marked "Official and Complete", reports the DeKalb share of that runoff as Collins 1,415 (65.75%) to Evans Jones 737 (34.25%), reversing the first round. The SOS certified 2025 municipal general then returns "Eshé Collins (I)", unopposed, 79,306 — confirming she held the seat before November 2025. Month precision: the runoff fixes the election, and no source in this wave states the oath day. This closes ROSTERS.md open item 3, which recorded the start as bounded between January 2022 and November 2025. (CC_0248)'),

-- ── Fulton County ──────────────────────────────────────────────────────────────────────────
('b8908d78-f531-4f9b-bfb7-ca6c60bc992a'::uuid,
 'Patrick "Pat" Labat — Sheriff',
 DATE '2021-01-01', 'month',
 'First won the office at the general election of 2020-11-03. Fulton County''s own Election Summary Report for November 03, 2020, marked "Official and Complete", lists "Sheriff — Patrick "Pat" Labat (Dem), 426,171" with NO incumbency marker. Control: that same document marks incumbents, e.g. "Natalie Hall (I) (Dem)" in County Commission District 4 and "Arthur E. Ferdinand (I) (Dem)" for Tax Commissioner, so the absence of "(I)" on Labat is meaningful. He then carries "(I)" in the SOS certified 2024-11-05 general. Georgia county officers take office the following January; month precision because no document states the oath day. (CC_0248)'),

('cf12fe11-360d-4379-8085-09ad1b68d598'::uuid,
 'Bob Ellis — Commissioner, District 2',
 DATE '2015-01-01', 'month',
 'First won the seat at the general election of 2014-11-04. Fulton County''s own Statement of Votes Cast for November 4, 2014, marked "Official and Complete", lists "CO COMM DIST 2 — BOB ELLIS (R)" unopposed with NO incumbency marker. Control: that document uses the "(I)" marker 126 times (BRIAN P. KEMP (I), DAVID A. SCOTT (I) and others), so its absence is meaningful. Continuity of occupancy is evidenced at every subsequent election: "B. ELLIS (I) R" in Fulton''s certified 2016 general, "Bob Ellis (I) (Rep)" in Fulton''s certified 2020 general, and "Bob Ellis (I) (Rep)" in the SOS certified 2024 general. Month precision: the return fixes the election, not the oath. (CC_0248)'),

('647cede8-37cf-446c-855e-83f974ce7d86'::uuid,
 'Marvin S. Arrington, Jr. — Commissioner, District 5',
 DATE '2015-01-01', 'month',
 'First won the seat at the general election of 2014-11-04. Fulton County''s own Statement of Votes Cast for November 4, 2014, marked "Official and Complete", lists "CO COMM DIST 5 — M. ARRINGTON JR. (D)" unopposed with NO incumbency marker, in a document that uses "(I)" 126 times. Continuity: he carries "(I)" as "Marvin Arrington, Jr. (I)" in Fulton''s certified General Primary of 2022-05-24, which places him in the seat continuously from the 2014 win through 2022 — a gap would require a non-incumbent win in between, and none appears. District 5 was not on the 2016 county ballot. Month precision. (CC_0248)'),

('31e14a21-1d81-48a6-b8b2-cd92037ffc2e'::uuid,
 'Khadijah Abdur-Rahman — Commissioner, District 6',
 DATE '2021-01-01', 'month',
 'First won the seat at the general election of 2020-11-03. Fulton County''s own Election Summary Report for November 03, 2020, marked "Official and Complete", lists "County Commission District 6 — Khadijah Abdur-Rahman (Dem), 78,479" with NO incumbency marker, in a document that does mark incumbents. ⚠ She did NOT win the 2019 District 6 special: Fulton''s certified Special Runoff Election summary for October 15, 2019 was won by "J. CARN" with 62.79% over "G. JOYNER", so the document whose title names Fulton County Commissioner District 6 dates her PREDECESSOR, not her. Month precision. (CC_0248)'),

('834e5536-704e-44d2-9e74-dfe016c0dd01'::uuid,
 'Bridget Thorne — Commissioner, District 1',
 DATE '2023-01-01', 'month',
 'First won the seat in the 2022 cycle. Fulton County''s own Election Summary Report for the General Primary of 2022-05-24 lists "REP - County Commissioner Dist 1 — Bridget Thorne, 9,710" with NO incumbency marker, in a document that uses "(I)" 54 times and applies it to the sitting members in the same contest block ("Robb Pitts (I)", "Marvin Arrington, Jr. (I)"). She holds the seat today. 🔴 The November 2022 general return itself could not be obtained: the Secretary of State''s 2022 county payload carries no county offices, and Fulton''s own archive holds no November 2022 general document — so the first-win YEAR rests on the certified primary plus present occupancy, and the January start follows Georgia''s county term rule. Month precision. (CC_0248)'),

('d5cc424c-d5cd-4538-954e-729dc9ccf98c'::uuid,
 'Dana Barrett — Commissioner, District 3',
 DATE '2023-01-01', 'month',
 'First won the seat in the 2022 cycle. Fulton County''s own Election Summary Report for the General Primary of 2022-05-24 lists "DEM - County Commissioner Dist 3 — Dana Barrett, 12,133" with NO incumbency marker, in a document that uses "(I)" 54 times and marks the sitting members in neighbouring contests. She holds the seat today. 🔴 Same limitation as District 1: neither the SOS nor Fulton''s archive holds the November 2022 general return, so the first-win year rests on the certified primary plus present occupancy. Month precision. (CC_0248)'),

-- ── DeKalb County ──────────────────────────────────────────────────────────────────────────
('8cc82faf-7955-4783-ad71-db36d8aba333'::uuid,
 'Robert Patrick — Commissioner, District 1',
 DATE '2021-01-01', 'month',
 'First won the seat at the general election of 2020-11-03. DeKalb County''s own Election Summary Report for November 3, 2020, marked "Official and Complete", lists "County Commission District 1 — Nancy Jester (I) (Rep), Robert Patrick (Dem)" — the incumbency marker sits on the person he DEFEATED, which is the clearest possible control that the marker was in use and absent on him. Month precision. (CC_0248)'),

('91c04057-7ce8-40c4-ba02-88e3b52e575e'::uuid,
 'Michelle Long Spears — Commissioner, District 2',
 DATE '2023-01-01', 'month',
 'First won the seat at the general election of November 2022. DeKalb County''s own Election Summary Report for that general, marked "Official and Complete", lists "County Commissioner D2 — Michelle Long Spears (Dem)" with NO incumbency marker, while the same document marks "County Commissioner D3 — Larry Johnson (I) (Dem)" and "County Commissioner D7 — Lorraine Cochran-Johnson (I) (Dem)". Month precision. (CC_0248)'),

('8c2b9610-b2d7-4a01-bf3c-84faf91ac1cf'::uuid,
 'Nicole Massiah — Commissioner, District 3',
 DATE '2024-12-01', 'month',
 'Won the certified special-election runoff of 2024-12-03. DeKalb County''s own Election Summary Report for December 03, 2024, marked "Official and Complete", reports "County Commissioner D3 (Special)" as Massiah 5,493 (75.99%) to Andrew W. Bell 1,736 (24.01%). The seat was vacant because Larry Johnson, its holder at the 2022 general, left to run for CEO. Corroborated by DeKalb County''s own commissioner page for District 3, which states "She was elected in December 2024". 🔴 A special-election winner is seated on certification, not the following January, so January 2025 would have been the WRONG default. Month precision: the exact oath day is not recorded — DeKalb''s Legistar holds no matter containing "Oath" (controlled against substringof(''Resolution'')). Closes half of ROSTERS.md open item 5. (CC_0248)'),

('300323b6-a517-448c-adc7-44df53223c32'::uuid,
 'Mereda Davis Johnson — Commissioner, District 5',
 DATE '2015-07-01', 'month',
 'Won the certified special-election runoff of 2015-07-14. DeKalb County''s own Election Summary Report for July 14, 2015, headed "State of Georgia Special Runoff Election" and marked "Official and Complete", reports "County Comm 5 — M. D. JOHNSON (D) 2,003 (53.12%)" to "G. TURNER JR. (D) 1,768 (46.88%)". Continuity of occupancy thereafter: "M. JOHNSON (I)" in DeKalb''s certified 2016-05-24 primary, "M. JOHNSON (I)(D)" in the certified 2016 general ("CC D5"), "Mereda Davis Johnson (I) (Dem)" in the certified 2020 general, and "(I)" in the SOS certified 2024 general. 🔴 Seated on certification in July 2015, not the following January. Month precision. (CC_0248)'),

('14803999-325c-47b0-880f-7dcf43b35914'::uuid,
 'Edward "Ted" Terry — Commissioner, Super District 6',
 DATE '2021-01-01', 'month',
 'First won the seat at the general election of 2020-11-03. DeKalb County''s own Election Summary Report for November 3, 2020, marked "Official and Complete", lists "County Commission District 6 — Edward "Ted" Terry (Dem)" with NO incumbency marker, in a document that marks incumbents throughout (Debra DeBerry (I), Melody M. Maddox (I), Mereda Davis Johnson (I), Nancy Jester (I)). Month precision. (CC_0248)'),

('7edb787c-6c73-40dd-aaec-4d177369c1e3'::uuid,
 'LaDena Bolton — Commissioner, Super District 7',
 DATE '2024-12-01', 'month',
 'Won the certified special-election runoff of 2024-12-03. DeKalb County''s own Election Summary Report for December 03, 2024, marked "Official and Complete", reports "County Commissioner D7 (Special)" as Bolton 9,631 (70.32%) to Jacqueline Adams 4,065 (29.68%). 🔴 THE FIRST ROUND WAS INVERTED: the SOS certified 2024-11-05 return has Adams 72,957 and Bolton 41,609, so reading the first round alone would have seated the wrong person. The seat was vacant because Lorraine Cochran-Johnson, its holder at the 2022 general, left to run for CEO and won. A special-election winner is seated on certification, not the following January. Month precision: Bolton''s own county page carries no date language at all (control: the District 3 page does). Closes the other half of ROSTERS.md open item 5. (CC_0248)');

-- Guard: every term_id must exist, be open-ended, and currently be undated.
DO $$
DECLARE
  v_missing int;
  v_dated   int;
BEGIN
  SELECT count(*) INTO v_missing
    FROM _atl_dates d
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.id = d.term_id);
  IF v_missing > 0 THEN
    RAISE EXCEPTION 'CC_0248: % of the 13 target terms do not exist', v_missing;
  END IF;

  SELECT count(*) INTO v_dated
    FROM _atl_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.term_end IS NOT NULL;
  IF v_dated > 0 THEN
    RAISE EXCEPTION 'CC_0248: % target terms are closed; this migration only dates OPEN terms', v_dated;
  END IF;
END $$;

-- The write. Guarded on term_start IS NULL, so a re-run is a no-op.
-- 🔴 The `| unverified <slot>` tag is stripped: these terms now have a start and must become
-- visible to essentials.office_holders_as_of(date).
UPDATE essentials.office_terms t
   SET term_start      = d.term_start,
       start_precision = d.start_precision,
       source          = d.source
  FROM _atl_dates d
 WHERE t.id = d.term_id
   AND t.term_start IS NULL;

-- Post-verify gate.
DO $$
DECLARE
  v_ok        int;
  v_unverif   int;
  v_remaining int;
BEGIN
  SELECT count(*) INTO v_ok
    FROM _atl_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.term_start = d.term_start
     AND t.start_precision = d.start_precision;
  IF v_ok <> 13 THEN
    RAISE EXCEPTION 'CC_0248: expected 13 dated terms, found %', v_ok;
  END IF;

  SELECT count(*) INTO v_unverif
    FROM _atl_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.source LIKE '%| unverified %';
  IF v_unverif <> 0 THEN
    RAISE EXCEPTION 'CC_0248: % dated terms still carry the "| unverified" tag and would stay '
                    'invisible to office_holders_as_of', v_unverif;
  END IF;

  -- The wave's undated count must fall from 20 to exactly 7.
  SELECT count(*) INTO v_remaining
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o   ON o.chamber_id = ch.id
    JOIN essentials.office_terms t ON t.office_id = o.id AND t.term_end IS NULL
   WHERE g.geo_id IN ('1304000','13121','13089')
     AND t.politician_id IS NOT NULL
     AND t.term_start IS NULL;
  IF v_remaining <> 7 THEN
    RAISE EXCEPTION 'CC_0248: expected 7 undated occupancies left in the wave, found %', v_remaining;
  END IF;

  RAISE NOTICE 'CC_0248 OK — 13 occupancies dated, 7 remain undated by design';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE 7 LEFT UNDATED, AND THE EXACT BLOCKER FOR EACH. They keep their `| unverified` tag.
--
--   Fulton Chairperson, Robb Pitts    — "(I)" in the certified 2022-05-24 primary, so the start
--                                       is before 2022. Needs Fulton's November 2017 countywide
--                                       special or its November 2018 general. The SOS holds no
--                                       county offices for either year and Fulton's archive
--                                       slices its 2017 documents BY CITY (Atlanta, Roswell,
--                                       East Point, …) with no countywide file.
--   Fulton Clerk, Ché Alexander       — Fulton's certified 2020 general shows a DIFFERENT clerk,
--                                       Cathelene "Tina" Robinson (I); Alexander is "(I)" by
--                                       2024. The Clerk is not on the 2022 ballot, so she
--                                       arrived mid-term by appointment. Fulton's Legistar holds
--                                       only Clerk procurement items, no appointment.
--   Fulton Tax Commissioner, Ferdinand — "(I)" continuously from at least 2016. First took the
--                                       office in the 1990s; Fulton's archive reaches 1969 but
--                                       the walk-back was not performed.
--   Fulton Probate Judge, Kenya M. Johnson — appears in NO certified return, because Georgia
--                                       declares an unopposed nonpartisan candidate elected
--                                       without a ballot (the CC_0245 finding, unchanged).
--   DeKalb Clerk, Debra DeBerry       — already "DEBRA DEBERRY (I)(D)" in DeKalb's certified
--                                       2012 general, so she took office in or before 2012,
--                                       by appointment. Needs pre-2012 county records.
--   DeKalb Sheriff, Melody M. Maddox  — ⚠ CORRECTED after this file was first written: there WAS
--                                       a Sheriff special in 2020 ("Sheriff (Special From March)",
--                                       voted 2020-05-19, runoff 2020-08-11). She carries "(I)" in
--                                       BOTH, so she already held the office and the special does
--                                       not date her either. She arrived by APPOINTMENT before
--                                       March 2020. (The US House District 5 special of 2020-09-29
--                                       is a separate contest and is not hers.)
--   DeKalb Probate Judge, Bedelia C. Hargrove — same nonpartisan-unopposed rule as Fulton's.
-- ───────────────────────────────────────────────────────────────────────────────────────────
