-- 1583_la_county_2026_primary_county_judicial_lausd.sql
--
-- Record outcomes for the 2026-06-02 LA County primary — county offices, the 11 Superior Court
-- contests, and LAUSD. 49 candidate rows across 17 races.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 49 ids below>);
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1583_la_county_2026_primary_county_judicial_lausd.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- SOURCE
-- ---------------------------------------------------------------------------------------------------
--   LA County Registrar-Recorder/County Clerk, official certified results for the June 2, 2026
--   Statewide Direct Primary Election — results.lavote.gov/text-results/4338 (fetched 2026-08-07).
--   Certified 2026-06-26 by Registrar Dean C. Logan; 2,227,461 ballots, 37.81% turnout.
--
-- 🔑 THIS SOURCE IS ONLY AUTHORITATIVE FOR CONTESTS WHOLLY INSIDE LA COUNTY. The same page also
-- carries Governor, Lieutenant Governor, Attorney General and the rest — but those are the LA COUNTY
-- SHARE of a statewide contest, and California's top-two is decided on STATEWIDE totals. Reading
-- them here would produce confident, wrong answers. The 7 statewide and 3 legislative/congressional
-- races on this election are deliberately NOT in this migration; they need the Secretary of State's
-- statement of vote and are left for a follow-up.
--
-- ---------------------------------------------------------------------------------------------------
-- THE RULE BEING APPLIED
-- ---------------------------------------------------------------------------------------------------
-- County offices, Superior Court judgeships and LAUSD board seats are NONPARTISAN in California: a
-- candidate taking more than 50% in the June primary is elected outright; otherwise the top two
-- advance to a November runoff. So a single race can produce `won` OR `runoff` depending only on the
-- margin, and both appear below.
--
-- Office No. 116 is the reason to be careful with that threshold: Pat Connolly took 50.46% — 15,341
-- votes clear of Paul A. Thompson out of 1,658,503 cast. That is a majority and an outright win, but
-- it is under a point, and rounding it the wrong way would invent a runoff that does not exist.
--
-- NOTE ON SEATING: nothing here touches `office_terms`. Winners of a June primary do not take office
-- in June — judges and LAUSD members are seated in December/January. Recording `won` is a statement
-- about the race, not about who currently holds the seat.
-- ---------------------------------------------------------------------------------------------------

-- ===================================================================================================
-- WON OUTRIGHT (>50% in the primary)
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 Statewide Direct Primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Nonpartisan office: >50% in the primary is elected outright.'
 WHERE id IN (
  'ec6278f7-b35b-43a6-b832-fe85b4d4b344',  -- Maria Elena Durazo   Supervisor 1st   184,974  60.58%
  '859fde3e-c2d8-4abd-9aae-57b20c935b80',  -- Lindsey P. Horvath   Supervisor 3rd   276,973  66.35%
  '909eb944-c7fe-4371-900a-796a0e31b14f',  -- Jeff Prang           Assessor       1,028,580  57.73%  (ballot name JEFFREY PRANG)
  '404842e5-1c9a-44f4-99cf-61c1b4b816e0',  -- Tal K. Valbuena      Judge Off. 2     981,043  56.84%
  '14eef699-541b-450f-99c1-54763b23bd1e',  -- Irene Lee            Judge Off. 14    964,365  56.91%
  '0cda31c8-afd2-4a3e-a9b0-73828df2d702',  -- Ben Forer            Judge Off. 66  1,161,181  70.02%
  '533e5b0e-ffde-4c52-97c6-bfb16674d90a',  -- David B. Walgren     Judge Off. 81  1,267,154  76.89%  (ballot name DAVID WALGREN)
  '12aeaf5c-cef1-4512-83f3-73a9bd14c23b',  -- Patrick Connolly     Judge Off. 116   836,922  50.46%  (ballot name PAT CONNOLLY)
  '5274f54d-cf04-488e-8d66-1c7d57cbb410',  -- Gloria Marin         Judge Off. 176   947,807  57.54%
  'b6a5bd6e-cbdf-40ca-9a84-30c5834cba29',  -- Ryan Dibble          Judge Off. 181   919,050  58.18%
  '2302cb93-4d7f-43eb-824b-76ee0c2ff8d6',  -- Rocio Rivas          LAUSD D2          64,429  64.36%
  '99e5f026-9d7e-4f4b-b4af-a7e813d5f430',  -- Nick Melvoin         LAUSD D4         104,177  61.58%
  '7a789d00-ba46-413c-ad1f-6b7e6a1d9b55'   -- Kelly Gonez          LAUSD D6          82,231 100.00%  (unopposed)
 );

-- ===================================================================================================
-- ADVANCED TO THE NOVEMBER RUNOFF (top two, no majority)
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 Statewide Direct Primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). No candidate reached 50%; this candidate finished in the top two and advances to the November 3 2026 runoff.'
 WHERE id IN (
  'c72e1388-c5a4-438a-ae22-b026fa3f9838',  -- Robert Luna          Sheriff          859,070  44.15%  (1st; 2nd is Alex Villanueva 422,272 / 21.70%, absent from our roster)
  '9de696f6-a753-4e2c-a8bd-b9813c27adaa',  -- Maria Ghobadi        Judge Off. 64    750,184  44.05%
  'f0bbd559-93af-496e-aa7a-2fe9f20759e2',  -- Rhonda A. Haymon     Judge Off. 64    717,844  42.15%
  '0a66f25a-ee3c-4c00-9f59-9852050244e5',  -- Justin Allen Clayton Judge Off. 65    614,230  36.69%
  '41d0cab4-0915-4db4-ab07-e1eba8f0ca79',  -- Anna Slotky Reitano  Judge Off. 65    500,183  29.88%
  '7d07967d-1eee-49d5-b63f-662e6a3efa9e',  -- Anthony (A.J.) Bayne Judge Off. 87    694,004  42.04%
  'b86c49e6-4cbe-4c20-b364-8c85a76c330f',  -- David DeJute         Judge Off. 87    516,631  31.30%
  'd0816b49-8231-4616-81f8-65024b8809ea',  -- Donna Tryfman        Judge Off. 131   612,858  37.31%
  '2ddb7c36-122c-4418-acfb-d69e342a6535'   -- David Ross           Judge Off. 131   546,032  33.24%
 );

-- ===================================================================================================
-- LOST (on the ballot, did not win or advance)
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 Statewide Direct Primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07).'
 WHERE id IN (
  '6b148e48-ed14-44e8-8dae-ff7e49ee8b71',  -- Elaine Alaniz              Supervisor 1st    41,306  13.53%
  '8c826134-6c3f-480a-914f-02eeda32f0d8',  -- David Argudo               Supervisor 1st    29,095   9.53%  (ballot name DAVID E. ARGUDO)
  'dace3c9b-e2ae-452f-9ce7-a7aeed658f9b',  -- Noel Almario               Supervisor 1st    29,058   9.52%
  '5311b242-6eeb-4ed2-bf0f-9e6d462fa2ca',  -- Annabella F. Mazariegos    Supervisor 1st    20,887   6.84%
  'f5c71ffe-0b78-4e51-9bee-9b27cb074cd1',  -- Tonia Arey                 Supervisor 3rd    67,966  16.28%
  'a7e3af17-6dc7-4c20-9910-8a035beaaa99',  -- Karla Carranza             Sheriff          114,615   5.89%
  'c7ec371d-49c4-4d48-a112-07a8b598c94e',  -- Mike Bornman               Sheriff           76,919   3.95%
  'a1ec9174-11fc-47b8-a2dc-7528f2d1feb9',  -- Brendan Corbett            Sheriff           24,618   1.27%
  '33b69a07-269f-46eb-9805-52124a5da3f8',  -- Stephen A. Adamus          Assessor         151,715   8.52%
  '595fbd43-686a-4e0c-9e81-9a596b66cd91',  -- Robert S. Draper           Judge Off. 2     744,824  43.16%
  'f85c2914-43c1-4ead-8ee4-2c341e58ef67',  -- Angie Christides           Judge Off. 14    730,247  43.09%
  '8a26326e-6741-4492-8d57-12698afea2aa',  -- Francisco Amador           Judge Off. 64    235,003  13.80%
  '4f968d3f-314f-44cd-8124-ef0c84d1fc1a',  -- Samuel Wolloch Krause      Judge Off. 65    341,861  20.42%
  'c2f01aa3-b451-4823-a866-5b26a40c8d61',  -- Chellei G. Jimenez         Judge Off. 65    217,865  13.01%
  'c1e99515-c55e-48b4-b54e-aaf616ecd816',  -- Cheryl C. Turner           Judge Off. 66    497,241  29.98%
  '3777ce80-df09-4032-be2b-e2e5a81622b2',  -- Dan Kapelovitz             Judge Off. 81    380,765  23.11%
  '7dda54cd-63c7-445b-8deb-7a2778ca3037',  -- Sharee Sanders Gordon      Judge Off. 87    440,136  26.66%
  '025eed6f-0378-41a1-809f-0cf9f435303f',  -- Paul A. Thompson           Judge Off. 116   821,581  49.54%
  'a75569e5-c648-4b55-9afc-cac3045c83a2',  -- Carlos Dammeier            Judge Off. 131   245,969  14.97%
  '8282d7f5-64f9-4f37-a8d2-d08e24e0785a',  -- Troy W. Slaten             Judge Off. 131   237,894  14.48%
  'f0d02550-16f3-43e4-9720-d14bb5dc39cd',  -- Zachary Smith              Judge Off. 176   699,461  42.46%
  'ef3dcc2d-e94b-41fe-a71f-89c40e772ae5',  -- Thanayi Lindsey            Judge Off. 181   660,620  41.82%
  '4ab5e824-f0af-4246-b926-b8d3dbf7aaea',  -- Raquel Zamora              LAUSD D2          35,673  35.64%
  'ed5973d1-d6a1-4ec6-998d-eb5b5f69fdb0'   -- Ankur Patel                LAUSD D4          64,994  38.42%
 );

-- ===================================================================================================
-- NOT NOMINATED — on our roster, absent from the certified ballot
-- ===================================================================================================
-- Each of these three appears in `race_candidates` but in NO line of the certified result for their
-- contest. The contests they sit in are fully reported (5, 4 and 2 names respectively, percentages
-- summing to 100.00%), so this is not a truncated source — they were not on the ballot.
--
-- Scott Schmerelson is the one worth a second look: he is a sitting LAUSD board member, but for
-- DISTRICT 3, and our roster has him as a District 2 candidate. District 2's certified field is
-- Rivas and Zamora only. A real officeholder on the wrong district's race is a seeding error, not a
-- defeated candidacy — `not_nominated` records that he was not on this ballot without asserting he
-- ran and lost.
UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Absent from the certified field for this contest in the LA County RR/CC official results for the June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). The contest is fully reported — every listed candidate''s percentages sum to 100.00% — so this is absence from the ballot, not a truncated source.'
 WHERE id IN (
  '38434b75-34ae-4de0-8681-0cabb30c83e9',  -- James Aldana       Supervisor 1st (certified field: Durazo, Alaniz, Argudo, Almario, Mazariegos)
  'ac6f11e5-1b77-4e1e-8bc0-d9c5f60f2289',  -- Roxanne Hoge       Supervisor 3rd (certified field: Horvath, Arey, Minasyan, Sidenfaden)
  '4db2564a-3ed2-4daa-b230-060b891d31d9'   -- Scott Schmerelson  LAUSD D2       (certified field: Rivas, Zamora) — sits for D3 in real life
 );

-- ---------------------------------------------------------------------------------------------------
-- 🔴 FOUND, NOT FIXED (1): FIVE SPURIOUS BOARD OF SUPERVISORS RACE SHELLS
-- ---------------------------------------------------------------------------------------------------
-- This election carries TWO race rows for the same Board of Supervisors seats, on the SAME office_id:
--
--   office ab608cce…  "Board of Supervisors District 1"                  1 cand: Hilda L. Solis   (source la_roster)
--                     "Los Angeles County Board of Supervisors District 1" 6 cands                (source manual)   ← real
--   office a38babc0…  "Board of Supervisors District 3"                  1 cand: Lindsey Horvath (source la_roster)
--                     "Los Angeles County Board of Supervisors District 3" 3 cands                (source manual)   ← real
--
-- The `la_roster` rows are roster artefacts — the sitting supervisor auto-attached to an election as
-- though they were a candidate. Districts 2, 4 and 5 have the same artefact (Mitchell, Hahn, Barger)
-- with no real race behind them, and D2/D4 are not even up in 2026: LA County elects supervisors 1,
-- 3 and 5 in gubernatorial years, 2 and 4 in presidential years.
--
-- 🔴 VOTER-FACING CONSEQUENCE: Hilda Solis shows as a 2026 candidate for a seat Maria Elena Durazo
-- just won outright with 60.58%. No result is recorded on those five rows here, because recording an
-- outcome would dignify a race that did not happen. Deleting five race rows is a structural change
-- that deserves its own decision.
--
-- ▶ FOLLOW-UP OWED: retire the five `la_roster` BoS race shells; separately, District 5 IS up in 2026
--   and has no real candidate field at all.
--
-- ---------------------------------------------------------------------------------------------------
-- FOUND, NOT FIXED (2): CERTIFIED CANDIDATES MISSING FROM OUR ROSTER
-- ---------------------------------------------------------------------------------------------------
--   Sheriff ......... Alex Villanueva (422,272 / 21.70%) — the SECOND RUNOFF CANDIDATE is absent, so
--                     the November runoff currently shows one participant.
--                     Also Eric Strong, Oscar Antonio Martinez, Andre N. White.
--   Supervisor 3rd .. Carmenlina Minasyan, Tomas Sidenfaden
--   Assessor ........ Sandy Sun, Rob Newland, Steven B. Palty
-- Seeding candidates is additive work with its own sourcing bar; recorded, not done.
