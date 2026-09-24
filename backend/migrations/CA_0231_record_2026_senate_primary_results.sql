-- CA_0231_record_2026_senate_primary_results.sql
--
-- Slot CA_0231 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- PR B1 of the CA_0222 follow-ups: record the certified outcome of every 2026 U.S. SENATE PRIMARY row
-- whose primary has passed, in the fourteen states where our primary rows still carried the
-- pre-primary 'filed' status and no result (AK DE FL KS MA ME MI MN NH OK RI TN VA WY; 103 rows).
--
-- Same shape as 1585 / 1842 / Phase 167 (1853-1859): set race_candidates.result, result_source and
-- result_recorded_at. candidate_status is NOT touched, and nothing is deleted or deactivated.
-- Phase 167 is the U.S. House; its requirements put Senate races out of scope, so this does not
-- overlap it. Its rules are followed: the jurisdiction's own document, a second document where one
-- exists, and an unsettled row is HELD rather than guessed.
--
-- ===========================================================================================
-- WHAT IS WRITTEN — 101 rows
-- ===========================================================================================
--   won            24   the party nominee (or, in a one-name contest, the only name)
--   lost           69
--   advanced        3   Alaska's top-four open primary: Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.
--   not_nominated   3   NOT on the U.S. Senate primary ballot at all — our row names the wrong office
--                       or a later write-in: Christopher Beardsley (DE; running for State Senator
--                       District 14), Travis Stevens (DE; a November declared write-in only), Allen
--                       Waters (RI; filed for Providence Mayor). is_live_candidate() drops these.
--   withdrew        2   MA: Alexander Rikleen, William Gates — already candidate_status 'withdrawn',
--                       and absent from the certified Democratic primary ballot.
-- Each row's result_source names the document, the status wording, and the figures.
--
-- ===========================================================================================
-- HELD — 2 rows left with result NULL, on purpose
-- ===========================================================================================
--   ALASKA (2): David B. Leslie finished 4th (1,850) — a top-four place — but is NOT on the certified
--     general list; Gerald L. Heikes finished 5th (1,741) and IS on it. News reports a Leslie withdrawal
--     on 2026-08-31 (the post-primary withdrawal deadline), which would move Heikes up, but no state
--     record says so. Writing 'advanced' for Leslie would be true of the count and false of the ballot;
--     writing it for Heikes would be false of the count. Held until a state record explains it.
--
-- ===========================================================================================
-- SOURCES (all fetched 2026-09-24; raw files kept with the PR's evidence)
-- ===========================================================================================
--   AK  Division of Elections, Election Summary Report OFFICIAL RESULTS (enr26/results), matched to the
--       vote by an independent sum of the precinct CSV.
--   DE  Department of Elections ENR JSON, "Results Type": "OFFICIAL RESULTS", 530/530; county file agrees.
--   FL  Division of Elections DetailRpt, "Official Results"; 67 county rows sum to the totals.
--       (Its FED summary page shows every Senate total DOUBLED — not used.)
--   KS  Secretary of State, "2026 Primary Election Official Vote Totals" (2026-09-01). One document only.
--   MA  electionstats.state.ma.us 172905 / 172906, linked by the Secretary as "Certified Election Results".
--   ME  Secretary of State "US Senate DEM - FINAL.xlsx" / "US Senate REP - FINAL.xlsx".
--   MI  Bureau of Elections Official Candidate Listing, PRI vs GEN reports (who went on to November);
--       Board of State Canvassers certified 2026-08-24. Statewide vote totals were NOT reachable from a
--       state source (mielections.us refused; mvic.sos.state.mi.us 403), so MI rows carry no counts.
--   NH  Secretary of State 2026-09-08 summary tallies (labelled only "subject to change if clerks submit
--       amendments"; a recount schedule is posted) for the vote counts, and — for WHO WON — the
--       Secretary of State's general-election "CANDIDATE LIST W/ ADDRESS - 09/17/2026", which names
--       Pappas (DEM) and Sununu (REP) as the U.S. Senate nominees. A tally could still move by an
--       amendment; the nominee list is the state saying who is on the November ballot. (Downloaded by
--       the operator on 2026-09-24; mm.nh.gov is bot-walled to scripts.)
--   MN  Secretary of State ussenate.txt, 4105/4105; State Canvassing Board certified 2026-08-18.
--   OK  State Election Board "Official Results", 2026-08-25 runoff (our OK primary race IS the runoff).
--   RI  Board of Elections ENR API, isOfficialResults true, 40/40.
--   TN  Secretary of State primary-by-county PDFs, matched by an independent sum of the precinct XLSX.
--       No "certified" wording on the files; the Nov. 3 candidate list agrees on both nominees.
--   VA  Department of Elections ENR, "OFFICIAL RESULTS", summed from the precinct CSV.
--   WY  Secretary of State Official Summary, certified by the State Canvassing Board 2026-08-26.
--
-- NOT DONE HERE (PR B2): the general-election rosters. Eight of these states have no 2026-11-03 U.S.
-- Senate race row at all (AK DE FL KS MI NH RI WY), and several general races are missing nominees.
--
-- IDEMPOTENT: every write is guarded on result IS NULL. Dry run: the body wrapped BEGIN; ... ROLLBACK;
-- against prod, applied twice in one transaction, then the rollback confirmed by re-reading the rows.
-- ROLLBACK (once applied): UPDATE essentials.race_candidates SET result = NULL, result_source = NULL,
--   result_recorded_at = NULL WHERE result_source LIKE '%Recorded by CA_0231 (2026-09-24).';

BEGIN;

CREATE TEMP TABLE ca0231_result ON COMMIT DROP AS
SELECT v.rc_id, v.st, v.full_name, v.status_before, v.result, v.result_source
FROM (VALUES
  ('c38b3960-848f-4305-815e-742742949e9a'::uuid, 'AK', 'Carol Kitty Hafner', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Carol Kitty Hafner: 1,009. Recorded by CA_0231 (2026-09-24).'),
  ('4b190e6c-650c-4543-9589-070bfe2fca7f'::uuid, 'AK', 'Dan S. Sullivan', 'filed', 'advanced',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Dan S. Sullivan: 68,726, 2nd (incumbent); on the certified general list. Recorded by CA_0231 (2026-09-24).'),
  ('ef7623a3-4b4e-4f88-a0a9-998ccaf508af'::uuid, 'AK', 'Daniel J. Sullivan Jr.', 'filed', 'advanced',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Daniel J. Sullivan Jr.: 4,107, 3rd; on the certified general list. Recorded by CA_0231 (2026-09-24).'),
  ('73553af4-bd7f-4906-bba9-b69fc767613d'::uuid, 'AK', 'Dustin Darden', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Dustin Darden: 808. Recorded by CA_0231 (2026-09-24).'),
  ('e2351821-60c1-44e5-b467-67a18f822014'::uuid, 'AK', 'Earl D. Southworth', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Earl D. Southworth: 803. Recorded by CA_0231 (2026-09-24).'),
  ('8d5ee62f-a8a5-4afc-b24f-b393a67b5012'::uuid, 'AK', 'Fred C. Grauberger', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Fred C. Grauberger: 479. Recorded by CA_0231 (2026-09-24).'),
  ('aadddbed-b6e6-443f-8644-d11f2914eb2f'::uuid, 'AK', 'Heather McElwain', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Heather McElwain: 972. Recorded by CA_0231 (2026-09-24).'),
  ('9d0e6d33-bafb-4bbd-b72d-cd057f4a23e6'::uuid, 'AK', 'Mary Peltola', 'filed', 'advanced',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Mary Peltola: 82,244, 1st; on the certified general list. Recorded by CA_0231 (2026-09-24).'),
  ('2444eca7-367e-45da-b98c-efd52dba46e4'::uuid, 'AK', 'Reece J. Roberts', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Reece J. Roberts: 602. Recorded by CA_0231 (2026-09-24).'),
  ('3950f271-5f1f-4470-b0f5-74b99322753c'::uuid, 'AK', 'Richard B. Mayers', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Richard B. Mayers: 609. Recorded by CA_0231 (2026-09-24).'),
  ('74d4c0bc-5d6b-4da4-b307-281ca42f226d'::uuid, 'AK', 'Richard Grayson', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Richard Grayson: 432. Recorded by CA_0231 (2026-09-24).'),
  ('2cde97a5-98a1-4585-93da-6a4131b22570'::uuid, 'AK', 'Scott A. Kohlhaas', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Scott A. Kohlhaas: 794. Recorded by CA_0231 (2026-09-24).'),
  ('d1c68940-3cde-4521-bf1a-9af6de172493'::uuid, 'AK', 'Shirley A. Saucerman', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Shirley A. Saucerman: 306. Recorded by CA_0231 (2026-09-24).'),
  ('6233d234-9891-4faf-8def-d40d962fbd4e'::uuid, 'AK', 'Sidney Hill', 'filed', 'lost',
   'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, printed 8/31/2026), "U.S. Senator", top-four open primary; matches an independent sum of GA_ENR_Precinct_State_of_Alaska.csv to the vote (166,004 votes). General list elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02): Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr.. Sidney Hill: 522. Recorded by CA_0231 (2026-09-24).'),
  ('bd1904a0-2abe-4cfe-a748-054f2359e2e5'::uuid, 'DE', 'Chris Coons', 'filed', 'won',
   'Delaware Department of Elections, 2026 Primary Election, "U.S. Senator", Results Type OFFICIAL RESULTS, 530 of 530 precincts (elections.delaware.gov/results/enr/Election_StatewideResults_ID_PR2026.json; county file sums agree), 2026-09-15; general list genl_fcddt_2026.html (2026-09-24): Coons (D), Katz (R). Chris Coons: D 68,154 (77.99%) / Appelhans 9,294 / Louve 6,577 / Hansen 3,367. Recorded by CA_0231 (2026-09-24).'),
  ('725470f6-fd3b-4f57-a82a-f1dd9237ce1b'::uuid, 'DE', 'Christopher Beardsley', 'filed', 'not_nominated',
   'Delaware Department of Elections, 2026 Primary Election, "U.S. Senator", Results Type OFFICIAL RESULTS, 530 of 530 precincts (elections.delaware.gov/results/enr/Election_StatewideResults_ID_PR2026.json; county file sums agree), 2026-09-15; general list genl_fcddt_2026.html (2026-09-24): Coons (D), Katz (R). Christopher Beardsley: NOT on the U.S. Senate primary ballot; he is a candidate for Delaware State Senator District 14. Recorded by CA_0231 (2026-09-24).'),
  ('2d2d539c-d845-401b-8403-a3276006afce'::uuid, 'DE', 'Travis Stevens', 'filed', 'not_nominated',
   'Delaware Department of Elections, 2026 Primary Election, "U.S. Senator", Results Type OFFICIAL RESULTS, 530 of 530 precincts (elections.delaware.gov/results/enr/Election_StatewideResults_ID_PR2026.json; county file sums agree), 2026-09-15; general list genl_fcddt_2026.html (2026-09-24): Coons (D), Katz (R). Travis Stevens: NOT on the primary ballot; a declared November write-in only (genl_wcddt_2026.html, 2026-09-17). Recorded by CA_0231 (2026-09-24).'),
  ('67ffd7df-44ec-490c-85f5-c4d1ec26b430'::uuid, 'DE', 'John Shulli', 'filed', 'lost',
   'Delaware Department of Elections, 2026 Primary Election, "U.S. Senator", Results Type OFFICIAL RESULTS, 530 of 530 precincts (elections.delaware.gov/results/enr/Election_StatewideResults_ID_PR2026.json; county file sums agree), 2026-09-15; general list genl_fcddt_2026.html (2026-09-24): Coons (D), Katz (R). John Shulli: R 9,052; Katz 30,896. Recorded by CA_0231 (2026-09-24).'),
  ('8d58d4d1-e338-44aa-a64c-b53e31bd0f53'::uuid, 'DE', 'Michael Katz', 'filed', 'won',
   'Delaware Department of Elections, 2026 Primary Election, "U.S. Senator", Results Type OFFICIAL RESULTS, 530 of 530 precincts (elections.delaware.gov/results/enr/Election_StatewideResults_ID_PR2026.json; county file sums agree), 2026-09-15; general list genl_fcddt_2026.html (2026-09-24): Coons (D), Katz (R). Michael Katz: R 30,896 (77.34%) / Shulli 9,052. Recorded by CA_0231 (2026-09-24).'),
  ('68bb7555-5dab-4221-8018-9820718aae97'::uuid, 'FL', 'Alex Vindman', 'filed', 'lost',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Alex Vindman: D: Nixon 705,835 / Vindman 553,138. Recorded by CA_0231 (2026-09-24).'),
  ('89572273-5270-47b5-98be-ad79f2bed323'::uuid, 'FL', 'Angela Nixon', 'filed', 'won',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Angela Nixon: D: Nixon 705,835 / Vindman 553,138. Recorded by CA_0231 (2026-09-24).'),
  ('3d71a902-74c0-48d4-b752-4f6b9c039eb4'::uuid, 'FL', 'Ashley B. Moody', 'filed', 'won',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Ashley B. Moody: R: Moody 1,320,780 / Gleason 228,010 / Rivera 79,973 / Perry 31,250. Recorded by CA_0231 (2026-09-24).'),
  ('16850192-b693-4eb8-816d-9fc48407e07d'::uuid, 'FL', 'Chris Gleason', 'filed', 'lost',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Chris Gleason: R: Moody 1,320,780 / Gleason 228,010. Recorded by CA_0231 (2026-09-24).'),
  ('f008c756-0224-41ab-b7dd-d195f2f939c5'::uuid, 'FL', 'Ernie Rivera', 'filed', 'lost',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Ernie Rivera: R: Moody 1,320,780 / Rivera 79,973. Recorded by CA_0231 (2026-09-24).'),
  ('a2e50fd7-544b-456c-b655-2c404d553fb5'::uuid, 'FL', 'Neelam Perry', 'filed', 'lost',
   'Florida Division of Elections, August 18, 2026 Primary Election, Official Results, United States Senator (results.elections.myflorida.com/DetailRpt.Asp?ELECTIONDATE=8/18/2026&RACE=USS&PARTY=<REP|DEM>; 67 county rows sum to the totals; NOT the FED summary page, which doubles the Senate totals). Neelam Perry: R: Moody 1,320,780 / Perry 31,250. Recorded by CA_0231 (2026-09-24).'),
  ('131b7d19-ae91-45ba-9046-11fa1f066a57'::uuid, 'KS', 'Adam Hamilton', 'filed', 'won',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Adam Hamilton: D plurality 77,607 (34.63%). Recorded by CA_0231 (2026-09-24).'),
  ('e7c0ccae-c6a8-4331-b2a1-3b529f3dfce2'::uuid, 'KS', 'Anne Parelkar', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Anne Parelkar: D 16,836; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('d7517d1a-7fd5-48e7-9c68-ee754212cf69'::uuid, 'KS', 'Christy Davis', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Christy Davis: D 31,857; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('cb5a4715-f07e-487c-b8cb-7083f90aae21'::uuid, 'KS', 'Damon Anderson', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Damon Anderson: D 5,879; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('f3add044-a6bf-4d5e-94d2-f22a2cd299fa'::uuid, 'KS', 'Erik Murray', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Erik Murray: D 15,177; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('2a0253e3-b7c7-41b4-ae6f-00ffcecf1f46'::uuid, 'KS', 'Jason Hart', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Jason Hart: D 12,412; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('b7c87f43-1de1-4749-83a9-cf39e04367d9'::uuid, 'KS', 'Kevin Latz', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Kevin Latz: D 4,110; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('8bf7d1e0-e802-4b6e-8ed2-b9f5bd2d0cad'::uuid, 'KS', 'Michael Soetaert', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Michael Soetaert: D 3,716; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('4701a388-80cc-427c-b5ca-173dd0505012'::uuid, 'KS', 'Noah Taylor', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Noah Taylor: D 30,362; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('bc726d84-667b-4174-821c-fe8c855fe795'::uuid, 'KS', 'Patrick Schmidt', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Patrick Schmidt: D 13,403; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('856f0da2-7e6a-4ede-9606-87e79c96828e'::uuid, 'KS', 'Sandy Spidel Neumann', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Sandy Spidel Neumann: D 12,717; Hamilton 77,607. Recorded by CA_0231 (2026-09-24).'),
  ('081dd237-81a4-4a66-9862-c2ea0c9ce75a'::uuid, 'KS', 'Pond Naramore', 'filed', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Pond Naramore: R 68,100; Marshall 270,632. Recorded by CA_0231 (2026-09-24).'),
  ('463970be-2dc8-4af9-ba3a-1d655abf59f3'::uuid, 'KS', 'Roger Marshall', 'filed', 'won',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), United States Senate. Roger Marshall: R 270,632 (79.90%) / Naramore 68,100. Recorded by CA_0231 (2026-09-24).'),
  ('3c866d72-b942-4bf2-ad6e-53264ed08539'::uuid, 'MA', 'Alexander Rikleen', 'withdrawn', 'withdrew',
   'Secretary of the Commonwealth, electionstats.state.ma.us (linked as "Certified Election Results"): "2026 U.S. Senate Democratic Primary" (election 172905) and "2026 U.S. Senate Republican Primary" (172906), 2026-09-01; county rows sum to the totals. Alexander Rikleen: not on the certified Democratic primary ballot (already candidate_status withdrawn). Recorded by CA_0231 (2026-09-24).'),
  ('804e91f9-db97-4e68-9b78-d66c89c1c71f'::uuid, 'MA', 'Ed Markey', 'active', 'won',
   'Secretary of the Commonwealth, electionstats.state.ma.us (linked as "Certified Election Results"): "2026 U.S. Senate Democratic Primary" (election 172905) and "2026 U.S. Senate Republican Primary" (172906), 2026-09-01; county rows sum to the totals. Ed Markey: D: Markey 580,628 (64.7%) / Moulton 314,198. Recorded by CA_0231 (2026-09-24).'),
  ('c918292e-1f56-4bbd-ae13-c1bd4f304d6f'::uuid, 'MA', 'Seth Moulton', 'active', 'lost',
   'Secretary of the Commonwealth, electionstats.state.ma.us (linked as "Certified Election Results"): "2026 U.S. Senate Democratic Primary" (election 172905) and "2026 U.S. Senate Republican Primary" (172906), 2026-09-01; county rows sum to the totals. Seth Moulton: D: Markey 580,628 / Moulton 314,198. Recorded by CA_0231 (2026-09-24).'),
  ('6f394631-f0f6-450f-89f4-acc61e30b14f'::uuid, 'MA', 'William Gates', 'withdrawn', 'withdrew',
   'Secretary of the Commonwealth, electionstats.state.ma.us (linked as "Certified Election Results"): "2026 U.S. Senate Democratic Primary" (election 172905) and "2026 U.S. Senate Republican Primary" (172906), 2026-09-01; county rows sum to the totals. William Gates: not on the certified Democratic primary ballot (already candidate_status withdrawn). Recorded by CA_0231 (2026-09-24).'),
  ('fcedf315-0b18-4b7f-be29-52524076cbe0'::uuid, 'MA', 'John Deaton', 'filed', 'won',
   'Secretary of the Commonwealth, electionstats.state.ma.us (linked as "Certified Election Results"): "2026 U.S. Senate Democratic Primary" (election 172905) and "2026 U.S. Senate Republican Primary" (172906), 2026-09-01; county rows sum to the totals. John Deaton: R: unopposed, 221,950 (99.3%). Recorded by CA_0231 (2026-09-24).'),
  ('0d247528-537b-4f2e-806e-15ec15b66e24'::uuid, 'ME', 'David Costello', 'filed', 'lost',
   'Maine Secretary of State, June 9, 2026 primary, "US Senate DEM - FINAL.xlsx" and "US Senate REP - FINAL.xlsx" (maine.gov/sos/cec/elec/results). David Costello: D: Platner 156,084 / Costello 17,560. Recorded by CA_0231 (2026-09-24).'),
  ('2dc9c555-b4bf-44e2-b802-788acf0b69db'::uuid, 'ME', 'Graham Platner', 'filed', 'won',
   'Maine Secretary of State, June 9, 2026 primary, "US Senate DEM - FINAL.xlsx" and "US Senate REP - FINAL.xlsx" (maine.gov/sos/cec/elec/results). Graham Platner: D: Platner 156,084 / Mills 41,644 / Costello 17,560 (he later withdrew as nominee 2026-07-10; CA_0222). Recorded by CA_0231 (2026-09-24).'),
  ('ec18a73b-175d-4928-bc43-1a3920b0458f'::uuid, 'ME', 'Susan M. Collins', 'filed', 'won',
   'Maine Secretary of State, June 9, 2026 primary, "US Senate DEM - FINAL.xlsx" and "US Senate REP - FINAL.xlsx" (maine.gov/sos/cec/elec/results). Susan M. Collins: R: unopposed, 126,398. Recorded by CA_0231 (2026-09-24).'),
  ('10edcad8-9560-468c-8d6d-23007d3e6f18'::uuid, 'MI', 'Abdul El-Sayed', 'filed', 'won',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 PRI report lists El-Sayed, McMorrow, Stevens (D) and Rogers (R); the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) carries only El-Sayed (D) and Rogers (R); the Board of State Canvassers certified the 2026-08-04 primary on 2026-08-24. Statewide vote totals were NOT reachable from a state source (mielections.us refused, mvic 403). Abdul El-Sayed: Democratic nominee per the GEN listing. Recorded by CA_0231 (2026-09-24).'),
  ('e5bf0e06-4977-498a-b561-81b2a3227aec'::uuid, 'MI', 'Haley Stevens', 'filed', 'lost',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 PRI report lists El-Sayed, McMorrow, Stevens (D) and Rogers (R); the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) carries only El-Sayed (D) and Rogers (R); the Board of State Canvassers certified the 2026-08-04 primary on 2026-08-24. Statewide vote totals were NOT reachable from a state source (mielections.us refused, mvic 403). Haley Stevens: absent from the GEN listing. Recorded by CA_0231 (2026-09-24).'),
  ('6e65d3d9-2b72-439f-b74f-66f89813cd48'::uuid, 'MI', 'Mallory McMorrow', 'filed', 'lost',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 PRI report lists El-Sayed, McMorrow, Stevens (D) and Rogers (R); the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) carries only El-Sayed (D) and Rogers (R); the Board of State Canvassers certified the 2026-08-04 primary on 2026-08-24. Statewide vote totals were NOT reachable from a state source (mielections.us refused, mvic 403). Mallory McMorrow: absent from the GEN listing; no withdrawal filed, on the ballot. Recorded by CA_0231 (2026-09-24).'),
  ('61cb92ce-f5ee-4b5b-9bd6-998c7d390ac8'::uuid, 'MI', 'Mike Rogers', 'filed', 'won',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 PRI report lists El-Sayed, McMorrow, Stevens (D) and Rogers (R); the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) carries only El-Sayed (D) and Rogers (R); the Board of State Canvassers certified the 2026-08-04 primary on 2026-08-24. Statewide vote totals were NOT reachable from a state source (mielections.us refused, mvic 403). Mike Rogers: Republican nominee per the GEN listing. Recorded by CA_0231 (2026-09-24).'),
  ('c107c904-11ca-4b5e-9774-28ce77aa3cea'::uuid, 'MN', 'Angie Craig', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Angie Craig: DFL 274,920; Flanagan 411,853. Recorded by CA_0231 (2026-09-24).'),
  ('366d6de5-d777-4e7c-9f84-b7ec8aa6cd2a'::uuid, 'MN', 'Billy Nord', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Billy Nord: DFL 2,896; Flanagan 411,853. Recorded by CA_0231 (2026-09-24).'),
  ('46c23326-2620-4589-bd6b-ec2b5bf11a7f'::uuid, 'MN', 'George H Kalberer', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. George H Kalberer: DFL 2,076; Flanagan 411,853. Recorded by CA_0231 (2026-09-24).'),
  ('86cb1227-f8b9-4608-a0de-f300aa83b9a7'::uuid, 'MN', 'Kurt Michael Anderson', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Kurt Michael Anderson: DFL 4,521; Flanagan 411,853. Recorded by CA_0231 (2026-09-24).'),
  ('0e455dc8-a95f-4e83-9258-70110e22051c'::uuid, 'MN', 'Peggy Flanagan', 'filed', 'won',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Peggy Flanagan: DFL 411,853 (59.01%). Recorded by CA_0231 (2026-09-24).'),
  ('2fe48dd8-c607-439b-9daf-6b4eba68eab0'::uuid, 'MN', 'Peter John Murgic', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Peter John Murgic: DFL 1,661; Flanagan 411,853. Recorded by CA_0231 (2026-09-24).'),
  ('46d51390-f53e-4ecb-b83b-00b72cf6aa76'::uuid, 'MN', 'Adam Schwarze', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Adam Schwarze: R 97,470; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('b97a65fb-58a2-4da5-b1b4-11b1bc2868da'::uuid, 'MN', 'Ahmad R. Hassan', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Ahmad R. Hassan: R 1,742; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('bfcd5828-c38a-4423-a819-6b3e1a36f088'::uuid, 'MN', 'Bob Carney Jr.', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Bob Carney Jr.: R 5,678; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('039e7819-ecb6-48b8-b533-5643985223aa'::uuid, 'MN', 'Cynthia Gail', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Cynthia Gail: R 5,929; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('5be7173b-94fc-48c8-b74c-59aba4bd4708'::uuid, 'MN', 'Joyce Lacey', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Joyce Lacey: R 7,474; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('3d844cdc-51a6-40e3-987a-e31162f6f94f'::uuid, 'MN', 'Michele Tafoya', 'filed', 'won',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Michele Tafoya: R 211,813 (52.07%). Recorded by CA_0231 (2026-09-24).'),
  ('c992ad68-1e5e-42cb-938c-206b700b4950'::uuid, 'MN', 'Patrick Munro', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Patrick Munro: R 7,096; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('6c2cf4e2-630a-4ca1-93e6-7858a9445481'::uuid, 'MN', 'Royce White', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Royce White: R 45,374; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('52c5f0de-fb50-4a78-a658-4e7193066c36'::uuid, 'MN', 'Tom Weiler', 'filed', 'lost',
   'Minnesota Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt (4105 of 4105 precincts; State Canvassing Board certified 2026-08-18), U.S. Senator. Tom Weiler: R 24,247; Tafoya 211,813. Recorded by CA_0231 (2026-09-24).'),
  ('aeca312c-f6fe-484c-a956-b5533d75584a'::uuid, 'NH', 'Chris Pappas', 'filed', 'won',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Chris Pappas: D 100,088; the Democratic nominee on the 09/17/2026 general list. Recorded by CA_0231 (2026-09-24).'),
  ('ff5365d2-c538-4b9e-9fd8-49c8c23753f8'::uuid, 'NH', 'David Jarvis', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). David Jarvis: D 1,212; Pappas 100,088. Recorded by CA_0231 (2026-09-24).'),
  ('6b6ecb1b-5aeb-4efa-a619-e024832fd251'::uuid, 'NH', 'John Vail', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). John Vail: D 956; Pappas 100,088. Recorded by CA_0231 (2026-09-24).'),
  ('c2dbb71f-bb17-454c-b879-c11730658cf3'::uuid, 'NH', 'Karishma Manzur', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Karishma Manzur: D 50,321; Pappas 100,088. Recorded by CA_0231 (2026-09-24).'),
  ('439848c2-3939-4367-9df5-76fbb394c088'::uuid, 'NH', 'Maxwell Saal', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Maxwell Saal: D 932; Pappas 100,088. Recorded by CA_0231 (2026-09-24).'),
  ('76ba9efd-c362-4ad5-8640-92add849ea24'::uuid, 'NH', 'Andy Martin', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Andy Martin: R 789; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('2cd2f0be-47e9-4fd5-af3c-30e126799480'::uuid, 'NH', 'John Sununu', 'filed', 'won',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). John Sununu: R 75,839; the Republican nominee on the 09/17/2026 general list. Recorded by CA_0231 (2026-09-24).'),
  ('4e5a36ad-9d8c-4088-ac8f-ef9e680f877d'::uuid, 'NH', 'Mary Maxwell', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Mary Maxwell: R 774; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('f0f9e976-8975-4d9a-9ce6-208497042a59'::uuid, 'NH', 'Richard McMenamon II', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Richard McMenamon II: R 403; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('1a73f4e1-3eb6-4c29-88c8-beb5db055f4c'::uuid, 'NH', 'Sabrina Smith', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Sabrina Smith: R 955; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('78da47b7-724d-42a8-aedb-dd9c8d2d715a'::uuid, 'NH', 'Scott Brown', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Scott Brown: R 29,517; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('c053e815-7ce0-47e1-a62d-88bc6bf56b4e'::uuid, 'NH', 'Sky Danley', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Sky Danley: R 1,187; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('84596ef4-a703-4f00-8ca7-94b0d221f57b'::uuid, 'NH', 'Tom Alciere', 'filed', 'lost',
   'New Hampshire Secretary of State: 2026 State Primary (2026-09-08) summary tallies 2026-sp-us-senator-summary-democratic.xlsx / -republican.xlsx (sos.nh.gov/2026-state-primary-election-results; county rows sum to TOTALS; labelled only "subject to change if clerks submit amendments"), and the nominees confirmed by the Secretary of State''s "CANDIDATE LIST W/ ADDRESS - 09/17/2026" for the general election, United States Senator: Pappas (DEM), Sununu (REP), Laplante (CON). Tom Alciere: R 602; Sununu 75,839. Recorded by CA_0231 (2026-09-24).'),
  ('96984fe7-ec09-45a9-bfd1-529b856cf4d5'::uuid, 'OK', 'Jim Priest', 'filed', 'lost',
   'Oklahoma State Election Board, Official Results, 2026-08-25 runoff primary (results.okelections.us/OKER/?elecDate=20260825, 1984 of 1984 precincts), FOR UNITED STATES SENATOR - Democrat. Jim Priest: Thomas 79,229 / Priest 50,249. Recorded by CA_0231 (2026-09-24).'),
  ('c4bda444-4e97-40ab-9dc2-ba88c08292e0'::uuid, 'OK', 'N''Kiyla Thomas', 'filed', 'won',
   'Oklahoma State Election Board, Official Results, 2026-08-25 runoff primary (results.okelections.us/OKER/?elecDate=20260825, 1984 of 1984 precincts), FOR UNITED STATES SENATOR - Democrat. N''Kiyla Thomas: Thomas 79,229 (61.19%) / Priest 50,249. Recorded by CA_0231 (2026-09-24).'),
  ('6967ddf3-afa7-4248-8856-96712ecd0c0e'::uuid, 'RI', 'Connor Burbridge', 'filed', 'lost',
   'Rhode Island Board of Elections, 2026 Statewide Primary, "DEM/REP Senator in Congress", isOfficialResults true, 40 of 40 units (electionresults.ri.gov/results/public/api/elections/rhodeisland/RI2026StatewidePrimary, asOf 2026-09-15), 2026-09-09. Connor Burbridge: D 17,192; Reed 98,473. Recorded by CA_0231 (2026-09-24).'),
  ('f50b22ba-b447-4be9-8a56-0b1d51da37c3'::uuid, 'RI', 'Jack Reed', 'filed', 'won',
   'Rhode Island Board of Elections, 2026 Statewide Primary, "DEM/REP Senator in Congress", isOfficialResults true, 40 of 40 units (electionresults.ri.gov/results/public/api/elections/rhodeisland/RI2026StatewidePrimary, asOf 2026-09-15), 2026-09-09. Jack Reed: D 98,473 / Burbridge 17,192 / Munoz 12,529. Recorded by CA_0231 (2026-09-24).'),
  ('76aa67b0-9b2d-46ba-bf32-3fcc22b79589'::uuid, 'RI', 'Luis Daniel Muñoz', 'filed', 'lost',
   'Rhode Island Board of Elections, 2026 Statewide Primary, "DEM/REP Senator in Congress", isOfficialResults true, 40 of 40 units (electionresults.ri.gov/results/public/api/elections/rhodeisland/RI2026StatewidePrimary, asOf 2026-09-15), 2026-09-09. Luis Daniel Muñoz: D 12,529; Reed 98,473. Recorded by CA_0231 (2026-09-24).'),
  ('88804cd3-d90a-43ea-ab25-fa083f34cdd2'::uuid, 'RI', 'Allen Waters', 'filed', 'not_nominated',
   'Rhode Island Board of Elections, 2026 Statewide Primary, "DEM/REP Senator in Congress", isOfficialResults true, 40 of 40 units (electionresults.ri.gov/results/public/api/elections/rhodeisland/RI2026StatewidePrimary, asOf 2026-09-15), 2026-09-09. Allen Waters: NOT on the U.S. Senate primary ballot; he filed for Providence Mayor. Recorded by CA_0231 (2026-09-24).'),
  ('1e7aadbd-1ed0-4c13-80bf-a0e655156415'::uuid, 'RI', 'Raymond McKay', 'filed', 'won',
   'Rhode Island Board of Elections, 2026 Statewide Primary, "DEM/REP Senator in Congress", isOfficialResults true, 40 of 40 units (electionresults.ri.gov/results/public/api/elections/rhodeisland/RI2026StatewidePrimary, asOf 2026-09-15), 2026-09-09. Raymond McKay: R unopposed, 20,354. Recorded by CA_0231 (2026-09-24).'),
  ('70365ef1-a83b-4548-acf0-5d27f92d228d'::uuid, 'TN', 'Civil Miller-Watkins', 'filed', 'lost',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Civil Miller-Watkins: D 29,596; Bradshaw 186,230. Recorded by CA_0231 (2026-09-24).'),
  ('3e0b1d88-a3bb-49c1-98b7-ff94e8669f42'::uuid, 'TN', 'Diana Onyejiaka', 'filed', 'lost',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Diana Onyejiaka: D 28,805; Bradshaw 186,230. Recorded by CA_0231 (2026-09-24).'),
  ('112c23f6-02d2-49b3-8abe-ef7127161041'::uuid, 'TN', 'Kevin Lee McCants', 'filed', 'lost',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Kevin Lee McCants: D 34,234; Bradshaw 186,230. Recorded by CA_0231 (2026-09-24).'),
  ('030df661-8ec4-4e8a-9bde-f9471a79bcf1'::uuid, 'TN', 'Maria Brewer', 'filed', 'lost',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Maria Brewer: D 61,061; Bradshaw 186,230. Recorded by CA_0231 (2026-09-24).'),
  ('0735d536-df55-483e-8b6f-a0e7ea991b87'::uuid, 'TN', 'Marquita Bradshaw', 'filed', 'won',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Marquita Bradshaw: D 186,230. Recorded by CA_0231 (2026-09-24).'),
  ('24ef0577-56d2-402d-8350-e85accedeb25'::uuid, 'TN', 'Bill Hagerty', 'filed', 'won',
   'Tennessee Secretary of State, August 6, 2026 primary by county (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf; match an independent sum of 20260806AllbyPrecinct.xlsx), United States Senate; the 2026-11-03 candidate list USSenate_Nov2026.pdf names Hagerty (R) and Bradshaw (D). Bill Hagerty: R 629,194. Recorded by CA_0231 (2026-09-24).'),
  ('e2345d87-e8b7-4a92-81bc-2c71c7708596'::uuid, 'VA', 'Bert Mizusawa', 'filed', 'won',
   'Virginia Department of Elections, "2026 August Republican Primary", OFFICIAL RESULTS (enr.elections.virginia.gov; API isOfficialResults true), Member, United States Senate; summed from the precinct CSV. Bert Mizusawa: 124,271 (51.49%). Recorded by CA_0231 (2026-09-24).'),
  ('770fd125-2de7-4cfd-a314-f78622d47385'::uuid, 'VA', 'David Williams', 'filed', 'lost',
   'Virginia Department of Elections, "2026 August Republican Primary", OFFICIAL RESULTS (enr.elections.virginia.gov; API isOfficialResults true), Member, United States Senate; summed from the precinct CSV. David Williams: 69,725; Mizusawa 124,271. Recorded by CA_0231 (2026-09-24).'),
  ('cacc69df-5185-4cf1-a38d-dc9ae214e21d'::uuid, 'VA', 'Kim Farington', 'filed', 'lost',
   'Virginia Department of Elections, "2026 August Republican Primary", OFFICIAL RESULTS (enr.elections.virginia.gov; API isOfficialResults true), Member, United States Senate; summed from the precinct CSV. Kim Farington: 47,357; Mizusawa 124,271. Recorded by CA_0231 (2026-09-24).'),
  ('3ae1632d-9d43-4c6f-b51c-826b45578b95'::uuid, 'WY', 'Billy Benavidez', 'filed', 'lost',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. Billy Benavidez: D 2,499; Byrd 9,591. Recorded by CA_0231 (2026-09-24).'),
  ('505252a8-8944-4006-bbf3-04ba88ff8f22'::uuid, 'WY', 'James Byrd', 'filed', 'won',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. James Byrd: D 9,591. Recorded by CA_0231 (2026-09-24).'),
  ('62f20be7-fe71-4255-8986-c33a94f4db25'::uuid, 'WY', 'Harriet Hageman', 'filed', 'won',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. Harriet Hageman: R 83,807. Recorded by CA_0231 (2026-09-24).'),
  ('d68d3519-9b77-48bb-9653-20fccfa85789'::uuid, 'WY', 'Jill M Edwards', 'filed', 'lost',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. Jill M Edwards: R 3,431; Hageman 83,807. Recorded by CA_0231 (2026-09-24).'),
  ('6895a843-26ff-4198-9894-96c9b4151590'::uuid, 'WY', 'Jimmy Skovgard', 'filed', 'lost',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. Jimmy Skovgard: R 3,527; Hageman 83,807. Recorded by CA_0231 (2026-09-24).'),
  ('bb942953-8cfb-4949-ba9a-6141b0029f68'::uuid, 'WY', 'John Holtz', 'filed', 'lost',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. John Holtz: R 2,539; Hageman 83,807. Recorded by CA_0231 (2026-09-24).'),
  ('60d56b0f-cbb6-48a5-883b-f0b315777caf'::uuid, 'WY', 'Sam Mead', 'filed', 'lost',
   'Wyoming Secretary of State, 2026 Statewide Candidates Official Summary (sos.wyo.gov/Elections/Docs/2026/Results/Primary/2026_Statewide_Candidates_Summary.pdf), certified by the State Canvassing Board 2026-08-26; matches the county rows and the precinct zip. Sam Mead: R 35,879; Hageman 83,807. Recorded by CA_0231 (2026-09-24).')
) AS v(rc_id, st, full_name, status_before, result, result_source);

-- The two rows deliberately left NULL (see header).
CREATE TEMP TABLE ca0231_held ON COMMIT DROP AS
SELECT rc.id AS rc_id
  FROM essentials.race_candidates rc
  JOIN essentials.races ra ON ra.id = rc.race_id
  JOIN essentials.elections e ON e.id = ra.election_id
 WHERE e.election_type = 'primary' AND ra.position_name LIKE 'U.S. Senate%'
   AND e.state = 'AK' AND e.election_date = '2026-08-18'
   AND rc.full_name IN ('David B. Leslie', 'Gerald L. Heikes');

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0231_result;
  IF n <> 101 THEN RAISE EXCEPTION 'PRE: % result rows listed, expected 101', n; END IF;
  SELECT count(*) INTO n FROM ca0231_held;
  IF n <> 2 THEN RAISE EXCEPTION 'PRE: % held rows found, expected 2 (Leslie + Heikes)', n; END IF;

  -- Every listed row is the row it claims to be: same id, same name, a U.S. Senate PRIMARY in that
  -- state whose date has passed, and still carrying the status it had at authoring.
  SELECT count(*) INTO n
    FROM ca0231_result c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id AND rc.full_name = c.full_name
                                      AND rc.candidate_status = c.status_before
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name LIKE 'U.S. Senate%'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'primary'
                               AND e.state = c.st AND e.election_date < CURRENT_DATE;
  IF n <> 101 THEN RAISE EXCEPTION 'PRE: only % of 101 rows match id / name / status / race', n; END IF;

  -- Untouched since authoring (first run) or written by THIS migration (re-run). Anything else is
  -- someone else's result; do not overwrite it.
  SELECT count(*) INTO n FROM ca0231_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE NOT (rc.result IS NULL OR (rc.result = c.result AND rc.result_source = c.result_source));
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows already carry a different result', n; END IF;

  -- The fourteen states' past Senate primaries hold exactly these 103 rows: nothing is left unreviewed.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name LIKE 'U.S. Senate%'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'primary'
   WHERE e.election_date < CURRENT_DATE
     AND e.state IN ('AK','DE','FL','KS','MA','ME','MI','MN','NH','OK','RI','TN','VA','WY')
     AND rc.id NOT IN (SELECT rc_id FROM ca0231_result UNION ALL SELECT rc_id FROM ca0231_held);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % Senate primary rows in these states were not reviewed', n; END IF;

  RAISE NOTICE 'CA_0231 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- Record the results. Guarded on result IS NULL.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_source      = c.result_source,
       result_recorded_at = '2026-09-24T00:00:00Z'
  FROM ca0231_result c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0231_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = c.result AND rc.result_source = c.result_source AND rc.result_recorded_at IS NOT NULL
     AND rc.candidate_status = c.status_before;
  IF n <> 101 THEN RAISE EXCEPTION 'POST: % of 101 rows carry their result with candidate_status unchanged', n; END IF;

  SELECT count(*) INTO n FROM ca0231_held h JOIN essentials.race_candidates rc ON rc.id = h.rc_id
   WHERE rc.result IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % held rows were written', n; END IF;

  -- At most one winner per party primary race. Maine is the exception by modelling, not by fact: its
  -- primary is ONE race row with no primary_party holding both party contests, so it has exactly two
  -- winners — Platner (D) and Collins (R).
  SELECT count(*) INTO n FROM ca0231_result WHERE result = 'won';
  IF n <> 24 THEN RAISE EXCEPTION 'POST: % won, expected 24', n; END IF;
  SELECT count(*) INTO n
    FROM (SELECT ra.id FROM ca0231_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
            JOIN essentials.races ra ON ra.id = rc.race_id
           WHERE c.result = 'won' AND ra.primary_party IS NOT NULL GROUP BY ra.id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % party primary races have two winners', n; END IF;
  SELECT count(*) INTO n FROM ca0231_result
   WHERE st = 'ME' AND result = 'won' AND full_name IN ('Graham Platner', 'Susan M. Collins');
  IF n <> 2 THEN RAISE EXCEPTION 'POST: Maine should have exactly its two party nominees as won, found %', n; END IF;

  RAISE NOTICE 'CA_0231 applied: 101 Senate primary results recorded (24 won, 69 lost, 3 advanced, '
               '3 not_nominated, 2 withdrew); 2 held (AK Leslie + Heikes)';
END $$;

COMMIT;
