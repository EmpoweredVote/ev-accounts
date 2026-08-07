-- 1581_tx_may_2026_municipal_general_results.sql
--
-- Record the outcomes of the 2026-05-02 Texas municipal general election for every race settled by
-- the Collin County official canvass. 52 candidate rows across 21 races.
--
--   Rollback: UPDATE essentials.race_candidates
--                SET result=NULL, result_source=NULL, result_recorded_at=NULL
--              WHERE race_id IN (SELECT id FROM essentials.races
--                                 WHERE election_id='8eaba170-95f5-4c98-849e-19ff93a17680');
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1581_tx_may_2026_municipal_general_results.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- SOURCE — ONE DOCUMENT, OFFICIAL, NOT A NEWS ROUND-UP
-- ---------------------------------------------------------------------------------------------------
--   Collin County Elections, "Summary Results Report — Joint General and Special Election,
--   May 2, 2026", FINAL RESULTS / All Races, 19 pages, generated 05/11/2026 11:37 AM.
--   collincountytx.gov/docs/default-source/elections/results-archive/
--     may-2-2026---joint-election---summary-report----official-results.pdf   (fetched 2026-08-07)
--
-- This is the canvassed official return, not an election-night file — the county publishes both, and
-- the unofficial one sits at a nearly identical URL. Every vote total below was read off that PDF.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT `runoff` IS FOR, DEMONSTRATED
-- ---------------------------------------------------------------------------------------------------
-- Two races produced no majority and went to the 2026-06-13 runoff. Their candidates are NOT winners
-- and NOT losers of this election:
--
--   Frisco Mayor      Mark Hill 4,803 (36.94%) · Rod Vilhauer 3,702 (28.47%)   → result = 'runoff'
--   Princeton Place 4 Jan Goria 199 (41.46%) · Jaisen Rutledge 158 (32.92%)    → result = 'runoff'
--
-- 🔑 Princeton is the clean demonstration that the `result` axis is per-RACE, not per-person. On this
-- May race Rutledge is `runoff`; on the June runoff race (migration 1580) the same man is `won`. One
-- person, two rows, two different true statements. A column that lived on the politician instead of
-- the candidacy could not say both.
--
-- ⚠️ Frisco Mayor's June 13 runoff has NO race row in our data, so its winner is not recorded
-- anywhere yet. Flagged below.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 NOT COVERED — 18 of this election's 40 races are absent from the Collin canvass
-- ---------------------------------------------------------------------------------------------------
-- Blue Ridge (3), Farmersville (2), Nevada (3), Prosper (2), Saint Paul (4), Van Alstyne (2),
-- Murphy Mayor (1), Longview (2). Two distinct reasons, neither of them "no result":
--
--   * CANCELLED UNOPPOSED ELECTIONS. Every one of Blue Ridge, Farmersville, Nevada, Prosper,
--     Saint Paul and Murphy Mayor has exactly ONE candidate per seat in our data. Texas Election
--     Code § 2.053 lets a city cancel the election and declare an unopposed candidate elected, and a
--     cancelled contest never reaches the county canvass. Their absence from this PDF is evidence of
--     a cancellation, NOT of a missing result — but "declared elected" needs the city's own
--     declaration order, not an inference from a silent county report. Note that Fairview Seat 2 was
--     ALSO unopposed and was NOT cancelled (Joe W. Boggs, 603 votes, 100%), which is exactly why the
--     inference cannot be made in bulk.
--   * DIFFERENT COUNTY. Van Alstyne city straddles Collin and Grayson (its ISD races appear here, its
--     city races do not); Longview is in Gregg County entirely.
--
-- ▶ FOLLOW-UP OWED: the 6 cities' cancellation/declaration orders, Grayson County for Van Alstyne
--   city, Gregg County for Longview District 3 (May 2, which forced the runoff already recorded in
--   migration 1580) and District 4, and the 2026-06-13 Frisco Mayor runoff result.
-- ---------------------------------------------------------------------------------------------------

-- WON ------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Collin County Elections, Summary Results Report — Joint General and Special Election, May 2, 2026, FINAL RESULTS (official canvass, generated 05/11/2026). Vote totals as printed. (fetched 2026-08-07)'
 WHERE id IN (
  '19fd4cc0-a86e-4bc7-8a24-78219d34901c',  -- Tommy Baril         Allen P2      3,206 (100.00%, unopposed)
  '5f49e3c4-3bbe-490a-af81-a9981f25eac8',  -- Chris Schulmeister  Allen Mayor   3,300 (81.08%)
  '0f3b7e3b-86fe-4191-a1b0-3bb656933a42',  -- Jessica Walden      Anna P3         403 (67.96%)
  '5a471452-7a6d-4e21-a4d8-2336a6a15f24',  -- Elden Baker         Anna P5         347 (58.22%)
  '639d5095-2068-4d5d-aa16-17731097fd08',  -- Shea Scott          Celina P4       864 (50.44%)
  'd1aee510-8e06-49de-b115-77daf5d6e167',  -- Shane Lambert       Celina P5     1,153 (68.43%)
  'a8fd5eea-8022-403f-8d89-8d51fddd522d',  -- Ryan Tubbs          Celina Mayor  1,300 (75.41%)
  'f08d5211-bee1-4366-9660-e8996977f94e',  -- Joe W. Boggs        Fairview S2     603 (100.00%, unopposed but NOT cancelled)
  '7030946d-e3a8-4739-8aa3-990f4c2cef93',  -- John Stanley        Fairview S4     384 (52.10%)
  'c97dbf1d-e5c1-49a8-85d6-065a93dff866',  -- Lakia Works         Fairview S6     529 (74.61%)
  'e2792fec-eed7-46d9-b3f7-ceccaf3283be',  -- Laura Rummel        Frisco P5     7,931 (61.83%)
  'afeea8ab-f33a-4b3c-8367-9da43ab7ee18',  -- Brittany Colberg    Frisco P6     6,800 (53.82%)
  '546967df-3674-4135-8ab3-ee9ec5ea76b4',  -- G Hijazen           Lowry X W4        6 (40.00%, Vote For 2)
  'ab878fcb-f42d-4f5f-9a64-0f4c47a2b8e1',  -- Ollie Simpson       Lowry X W4        5 (33.33%, Vote For 2)
  '515819e8-ffc9-499e-9a69-d9f4862fe144',  -- Jonathan Underhill  Lucas S1        505 (85.74%)
  '69dbcd49-8695-49da-b47c-db26652e0eaa',  -- Rebecca B. Orr      Lucas S2        396 (63.56%)
  '19349bd3-579a-440e-81eb-fd1178c99e6e',  -- Debbie Ison         Murphy P3     1,583 (64.27%)
  '7f60ec84-2590-42de-abdf-61c1703ba8e5',  -- Kevin Kelley        Murphy P5     1,494 (60.46%)
  'ee0127e1-f1fe-40fb-9214-d94e1aec8474',  -- Lee Pettle          Parker Mayor    452 (56.08%)
  '5c9eae2c-6b9a-469c-bbbb-7cc6c6955506',  -- Buddy Pilgrim       Parker At-Lg    490 (31.33%, Vote For 2)
  '168002da-7c38-4d42-b9ea-65e5f4a06c0c'   -- Billy Barron        Parker At-Lg    450 (28.77%, Vote For 2)
 );

-- LOST -----------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Collin County Elections, Summary Results Report — Joint General and Special Election, May 2, 2026, FINAL RESULTS (official canvass, generated 05/11/2026). Vote totals as printed. (fetched 2026-08-07)'
 WHERE id IN (
  '9f20f490-7117-4788-98f7-f43b090d4f8d',  -- Dave Shafer            Allen Mayor     770 (18.92%)
  'ffb6a763-bdf3-4d1d-91bb-8d36dec8c62c',  -- Mike Olivarez          Anna P3         190 (32.04%)
  'e9f7175d-0f4f-47b4-b5bc-2d88cb59bb81',  -- Susan Jones            Anna P5         249 (41.78%)
  'd8b1d8f5-ec32-49a9-b5ed-dfe8c5976997',  -- Katie Dunn             Celina P4       849 (49.56%)
  '762413bf-2d5f-490a-b66a-08f107436958',  -- Brent Baty             Celina P5       532 (31.57%)
  '648a3cfe-7c7e-4054-a728-7b32a481f8ef',  -- Eric Becker            Celina Mayor    373 (21.64%)
  '125acf87-d340-4160-9576-a557bde8b950',  -- Erica Cornelius        Celina Mayor     51 (2.96%)
  '04f04386-1b14-40a8-9eeb-04c1f2ba665b',  -- Ricardo Doi            Fairview S4     353 (47.90%)
  '52f4af84-b351-43f0-a055-b7f0d390bb9b',  -- Ryan Riyad             Fairview S6     180 (25.39%)
  '1e959e10-7a5b-40ce-bb40-1d7f07c09395',  -- Vijay Karthik          Frisco P5     3,057 (23.83%)
  'b31e5fb1-294d-4673-8a50-08219482db1d',  -- Sreekanth Reddy        Frisco P5     1,839 (14.34%)
  '80eed7f6-7d9b-41ec-85d6-85ce1aa222e1',  -- Sai Krishnarajanagar   Frisco P6     2,752 (21.78%)
  '142c733f-4202-4fe1-a82d-4e4c33fbbb1b',  -- Matt Chalmers          Frisco P6     2,048 (16.21%)
  '69bea52a-386f-474c-bee5-e0a5db838b95',  -- Jerry Spencer          Frisco P6     1,035 (8.19%)
  '5962097a-782e-4f6a-8b37-b923829f562a',  -- Donna Crenshaw Outland Lowry X W4        4 (26.67%)
  'fabe04e8-34fd-4366-bc15-8cf35eadc328',  -- Richard Alan           Lucas S1         84 (14.26%)
  'f0a15b05-c655-4727-b69e-c553449d7c9a',  -- John Awezec            Lucas S2        227 (36.44%)
  '3d1ff717-33d6-4b99-b714-747e9886e581',  -- Andrew Chase           Murphy P3       880 (35.73%)
  '12debcb2-5a9a-44f0-a55e-7618b7356f27',  -- Laura Deel             Murphy P5       849 (34.36%)
  '0f33b885-8db2-479a-b125-be264275aa6c',  -- Manoj Varghese         Murphy P5        65 (2.63%)
  '1bb37c60-9679-4bab-8483-78da41a7ee57',  -- Sarah Fincanon         Murphy P5        63 (2.55%)
  '2cd09d91-aa01-4ca6-aeaa-25539df8a915',  -- Melissa Tierce         Parker Mayor    338 (41.94%)
  'c684f31a-0569-4bab-ad3e-aed5bce5d342',  -- Marcos Arias           Parker Mayor     16 (1.99%)
  'be7a1f60-e0e0-4d79-bee3-08c48aa44cdc',  -- Amanda Noe             Parker At-Lg    332 (21.23%)
  '400a9e55-8b4a-4487-a877-1c17b57fe96f',  -- Alan Meyer             Parker At-Lg    292 (18.67%)
  'ac719fed-9cc4-4559-8e8f-269ebbbf5e28',  -- Sharad Ramani          Princeton P4    105 (21.88%)
  'fa58aa93-07e6-494d-bb46-d3ec726aaee6'   -- Hassan Abdulkareem     Princeton P4     18 (3.75%)
 );

-- RUNOFF ---------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Collin County Elections, Summary Results Report — Joint General and Special Election, May 2, 2026, FINAL RESULTS (official canvass, generated 05/11/2026): no candidate reached a majority, so this candidate advanced to the 2026-06-13 runoff. Frisco Mayor — Mark Hill 4,803 (36.94%), Rod Vilhauer 3,702 (28.47%). Princeton Place 4 — Jan Goria 199 (41.46%), Jaisen Rutledge 158 (32.92%). (fetched 2026-08-07)'
 WHERE id IN (
  '7483b431-a418-48a1-89d9-b00db3594f5e',  -- Mark Hill        Frisco Mayor
  '7329f5f2-a56c-4e1c-90c7-400b8f3973ad',  -- Rod Vilhauer     Frisco Mayor
  'f61a49e0-c074-480e-a391-a1c29a3a9d7f',  -- Jan Goria        Princeton P4
  '05195836-ee47-4371-aeae-d9690f14b72f'   -- Jaisen Rutledge  Princeton P4  (see mig 1580: WON the runoff)
 );

-- Frisco Mayor also had two candidates eliminated outright in May.
UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Collin County Elections, Summary Results Report — Joint General and Special Election, May 2, 2026, FINAL RESULTS (official canvass, generated 05/11/2026): Mayor — City of Frisco. Eliminated in the first round; did not advance to the 2026-06-13 runoff. (fetched 2026-08-07)'
 WHERE id IN (
  '09d46d7b-07cf-4a59-b24a-1689e5d58928',  -- Shona Sowell   2,644 (20.34%)
  '914169c4-93ff-49c7-af9d-3af97332b4e0'   -- John Keating   1,853 (14.25%)
 );
