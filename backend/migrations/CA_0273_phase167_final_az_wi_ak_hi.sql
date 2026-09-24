-- CA_0273_phase167_final_az_wi_ak_hi.sql
--
-- Slot CA_0273 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Phase 167 (2026 U.S. House post-primary reconciliation; taken over by Chris Andrews 2026-09-24): the last
-- open items. Same shape as 1853 / CA_0263 / CA_0266 / CA_0269.
--
-- 1. ARIZONA CD2 — the State of Arizona Official Canvass, 2026 Primary (report 8/5/2026; the operator
--    downloaded it, azsos.gov blocks scripts), page 2: Eli Crane (R) 89,205*, Jonathan Nez (D) 65,118*,
--    Curtis Goodwin (L) 318* (* = winner). All three 'advanced'. Crane and Nez carried no flag; Goodwin's
--    flag is KEPT — no Arizona November list could be read, so independents are unverified (rule 5).
--
-- 2. WISCONSIN — the whole U.S. House picture, which CA_0243 and CA_0254 left to Phase 167:
--    a. the 32 U.S. Representative PRIMARY rows get their certified results (WEC xlsx, certified
--       2026-08-25): 16 won, 16 lost. CD6 D: Brad Smith 36,413 / Amanda Bell 36,046.
--    b. the 5 existing November rows — all Independents who filed nomination papers (Provance, Kent,
--       Burks, Fitzgibbon, Thurow) — are on WEC's November ballot list: 'advanced', flag cleared.
--    c. the 16 party nominees were ON NO November race at all (two races, CD1 and CD2, held nobody).
--       They are added from their primary rows' politician_id, 'active' / 'advanced'; is_incumbent is
--       taken from the seat itself (office_current_holder on the race's office) — 7 incumbents.
--    Source for (b) and (c): WEC "Candidates on Ballot by Election, 2026 General Election - 11/3/2026"
--    (printed 8/25/2026; 21 names across the 8 districts). Every race then matches it exactly.
--
-- 3. ALASKA AT-LARGE — reconciled to the Division of Elections' CERTIFIED general list (Begich, Hafner,
--    Hill, McDermott). 1856 worked from the count alone, so two of its rows disagree with the ballot:
--      Matt Schultz  (3rd, 13,149)  advanced      -> not_nominated  — not on the certified list
--      Jim McDermott (8th,  1,951)  not_nominated -> advanced       — certified, filling a top-four
--                                                                     vacancy under AS 15.25.100(c)
--      John B. Williams (5th, held) NULL          -> not_nominated  — not on the certified list
--    The certified list is the state's record of who is on the ballot; the count cannot show later
--    withdrawals. Each result_source says so.
--
-- 4. HAWAII CD2 — Edward A. Codelia (N), held by 1853 on HRS 12-41(b). The Office of Elections' own rule
--    (elections.hawaii.gov/candidates/nonpartisan-candidates-in-partisan-contests): a nonpartisan
--    candidate needs "at least 10% of the votes cast for the office" — its worked example uses the whole
--    office's vote — or a vote at least the lowest nominated partisan's. Codelia: 1,230 of ~128,940
--    (under 1%); lowest nominee Awa (R) 26,290. Neither: 'not_nominated', flag cleared.
--
-- CI: no candidate_status changes. The 16 new rows are Wisconsin races for people whose Wisconsin
-- primary row already sets their stance-sources bucket, so no bucket moves (the #719 / #762 mode).
-- Every prod-reading CI check is run before and after the apply.
--
-- IDEMPOTENT: each update is guarded on its exact pre-image (result NULL, or the 1856 value it corrects);
-- inserts by NOT EXISTS. Dry run: BEGIN; ... ROLLBACK; against prod, applied twice, then re-read.
-- ROLLBACK (once applied): restore result/result_source to the pre-image for rows whose result_source ends
--   'Recorded by CA_0273 (2026-09-24).' (Schultz 'advanced', McDermott 'not_nominated', all others NULL)
--   and their provisional_until; DELETE the 16 race_candidates rows whose source ends 'added by CA_0273
--   (2026-09-24)'.

BEGIN;

CREATE TEMP TABLE ca0273_upd ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('c786d837-3ae2-49d3-bb6f-eaf1b65319ef'::uuid, 'Bryan Steil', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Bryan Steil: Republican primary, U.S. Representative District 1: Bryan Steil 50,915 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('228a1b21-a865-4b9c-9fa0-b23ce70a5b5c'::uuid, 'Peter Burgelis', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Peter Burgelis: Democratic primary, U.S. Representative District 1: Peter Burgelis 15,455; winner Mitchell Berman 31,494. Recorded by CA_0273 (2026-09-24).'),
  ('f924bf81-8fd3-4c8f-8bf6-445b499b84b0'::uuid, 'Mitchell Berman', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Mitchell Berman: Democratic primary, U.S. Representative District 1: Mitchell Berman 31,494 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('5e306ed2-f3eb-4930-a7cf-5dd4042da5eb'::uuid, 'Miguel Aranda', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Miguel Aranda: Democratic primary, U.S. Representative District 1: Miguel Aranda 9,701; winner Mitchell Berman 31,494. Recorded by CA_0273 (2026-09-24).'),
  ('4ec78195-bee9-4e72-af3e-dee3e65439bc'::uuid, 'Lorenzo J. Santos', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Lorenzo J. Santos: Democratic primary, U.S. Representative District 1: Lorenzo J. Santos 14,590; winner Mitchell Berman 31,494. Recorded by CA_0273 (2026-09-24).'),
  ('5b803866-6831-4aeb-a5e5-63596fd00275'::uuid, 'Douglas Alexander', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Douglas Alexander: Democratic primary, U.S. Representative District 2: Douglas Alexander 19,610; winner Mark Pocan 144,365. Recorded by CA_0273 (2026-09-24).'),
  ('ed8ce2e6-81dd-464c-af2e-631ebb3c7dae'::uuid, 'Mark Pocan', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Mark Pocan: Democratic primary, U.S. Representative District 2: Mark Pocan 144,365 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('44318496-2b3d-4b76-afa3-fa4992cbe80d'::uuid, 'Derrick Van Orden', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Derrick Van Orden: Republican primary, U.S. Representative District 3: Derrick Van Orden 56,948 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('b82cf290-e91a-44d4-9e0f-a2cc78152ab0'::uuid, 'Rebecca Cooke', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Rebecca Cooke: Democratic primary, U.S. Representative District 3: Rebecca Cooke 56,650 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('d160b112-604a-48f8-9415-d7b466184b34'::uuid, 'Emily Berge', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Emily Berge: Democratic primary, U.S. Representative District 3: Emily Berge 36,958; winner Rebecca Cooke 56,650. Recorded by CA_0273 (2026-09-24).'),
  ('7edeedd3-7133-4075-b516-8a960e99db84'::uuid, 'Tim Rogers', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Tim Rogers: Republican primary, U.S. Representative District 4: Tim Rogers 10,079 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('6bbd8b29-46f4-4ffb-bab6-1f5d0e9324db'::uuid, 'Purnima Nath', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Purnima Nath: Republican primary, U.S. Representative District 4: Purnima Nath 2,356; winner Tim Rogers 10,079. Recorded by CA_0273 (2026-09-24).'),
  ('9da5d45c-bf07-4507-9548-0dccd3c1315d'::uuid, 'Gwen Moore', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Gwen Moore: Democratic primary, U.S. Representative District 4: Gwen Moore 81,707 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('e6f51abd-b708-41fe-85d5-74b378e1e2d3'::uuid, 'Amy Donahue', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Amy Donahue: Democratic primary, U.S. Representative District 4: Amy Donahue 31,707; winner Gwen Moore 81,707. Recorded by CA_0273 (2026-09-24).'),
  ('3a5bd46e-9310-46b3-83ce-7f87e98c20bf'::uuid, 'Scott Fitzgerald', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Scott Fitzgerald: Republican primary, U.S. Representative District 5: Scott Fitzgerald 76,702 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('83154170-84f5-41fa-b66b-4f9262c39a61'::uuid, 'Andrew Beck', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Andrew Beck: Democratic primary, U.S. Representative District 5: Andrew Beck 64,504 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('6f6700e3-58c3-4167-a779-ec7a7edad05b'::uuid, 'Matthew Arndt', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Matthew Arndt: Wisconsin Green primary, U.S. Representative District 6: Matthew Arndt 62 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('d4905f0a-38e9-4dd4-91e7-177e85501bcd'::uuid, 'Glenn Grothman', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Glenn Grothman: Republican primary, U.S. Representative District 6: Glenn Grothman 63,462 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('4d1a92a0-378d-430a-8eb5-7853bd138218'::uuid, 'Brad Smith', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Brad Smith: Democratic primary, U.S. Representative District 6: Brad Smith 36,413 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('eb8211a5-ca36-4b37-b26b-c1bcde58eee3'::uuid, 'Amanda Bell', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Amanda Bell: Democratic primary, U.S. Representative District 6: Amanda Bell 36,046; winner Brad Smith 36,413. Recorded by CA_0273 (2026-09-24).'),
  ('59bfb5f0-acf3-4900-a70a-ca5184e924d0'::uuid, 'Michael Alfonso', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Michael Alfonso: Republican primary, U.S. Representative District 7: Michael Alfonso 49,720 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('dff86aa8-bee2-4881-8a77-9ebb21347436'::uuid, 'Niina Baum', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Niina Baum: Republican primary, U.S. Representative District 7: Niina Baum 4,893; winner Michael Alfonso 49,720. Recorded by CA_0273 (2026-09-24).'),
  ('804166d4-863d-4fcd-aec9-8e674a0c7195'::uuid, 'Jessi Ebben', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Jessi Ebben: Republican primary, U.S. Representative District 7: Jessi Ebben 15,937; winner Michael Alfonso 49,720. Recorded by CA_0273 (2026-09-24).'),
  ('46b71881-3776-4111-a485-d93422f636d1'::uuid, 'Kevin Hermening', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Kevin Hermening: Republican primary, U.S. Representative District 7: Kevin Hermening 27,009; winner Michael Alfonso 49,720. Recorded by CA_0273 (2026-09-24).'),
  ('1c769919-ec26-47ef-8a0d-a713c953c958'::uuid, 'Don Raihala', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Don Raihala: Republican primary, U.S. Representative District 7: Don Raihala 3,926; winner Michael Alfonso 49,720. Recorded by CA_0273 (2026-09-24).'),
  ('08a9f3d9-37e2-4a00-a151-2e00b5d95b11'::uuid, 'Chris Armstrong', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Chris Armstrong: Democratic primary, U.S. Representative District 7: Chris Armstrong 20,764; winner Fred Clark 25,716. Recorded by CA_0273 (2026-09-24).'),
  ('e02f8d44-73dc-408d-89c7-70e796059747'::uuid, 'Ginger Murray', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Ginger Murray: Democratic primary, U.S. Representative District 7: Ginger Murray 21,726; winner Fred Clark 25,716. Recorded by CA_0273 (2026-09-24).'),
  ('498e8566-3f16-4fc3-b371-15381706c1a2'::uuid, 'Fred Clark', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Fred Clark: Democratic primary, U.S. Representative District 7: Fred Clark 25,716 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('b461d8cc-5bed-4b32-9d32-759f9d1d2506'::uuid, 'Tony Wied', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Tony Wied: Republican primary, U.S. Representative District 8: Tony Wied 63,211 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('f9492bbb-26b1-4368-987e-f6606183818c'::uuid, 'Rick Crosson', NULL, 'won', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Rick Crosson: Democratic primary, U.S. Representative District 8: Rick Crosson 24,970 (winner). Recorded by CA_0273 (2026-09-24).'),
  ('134d9ad1-5544-427d-bc55-5f2c0172ce69'::uuid, 'Mark Scheffler', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Mark Scheffler: Democratic primary, U.S. Representative District 8: Mark Christopher Scheffler 23,392; winner Rick Crosson 24,970. Recorded by CA_0273 (2026-09-24).'),
  ('813ebf4e-38e6-4291-83fe-c7bf489d31f5'::uuid, 'Katrina deVille', NULL, 'lost', false,
   'Wisconsin Elections Commission, 2026 Partisan Primary official results certified 2026-08-25 (County_by_County_Report_Partisan_Primary_2026_All_State_Contests.xlsx). Katrina deVille: Democratic primary, U.S. Representative District 8: Katrina deVille 22,405; winner Rick Crosson 24,970. Recorded by CA_0273 (2026-09-24).'),
  ('c6ea4a97-f8ce-4cff-8101-1258458debaa'::uuid, 'Rustin Provance', NULL, 'advanced', true,
   'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf, printed 8/25/2026): on the November ballot as an Independent (nomination papers; not on the primary ballot). Recorded by CA_0273 (2026-09-24).'),
  ('f0a27834-efd5-4d7e-849b-2c35ee9a5d8a'::uuid, 'Arthur Burks', NULL, 'advanced', true,
   'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf, printed 8/25/2026): on the November ballot as an Independent (nomination papers; not on the primary ballot). Recorded by CA_0273 (2026-09-24).'),
  ('333fdb75-fe1f-41ca-8a1e-7d5b5917fc23'::uuid, 'Elizabeth Fitzgibbon', NULL, 'advanced', true,
   'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf, printed 8/25/2026): on the November ballot as an Independent (nomination papers; not on the primary ballot). Recorded by CA_0273 (2026-09-24).'),
  ('8439119b-d200-404e-863c-c1a74672f93f'::uuid, 'Michael Thurow', NULL, 'advanced', true,
   'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf, printed 8/25/2026): on the November ballot as an Independent (nomination papers; not on the primary ballot). Recorded by CA_0273 (2026-09-24).'),
  ('d9b39dde-beb8-482f-bafc-2ca273fdc138'::uuid, 'Alexander Valiensi Kent', NULL, 'advanced', true,
   'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf, printed 8/25/2026): on the November ballot as an Independent (nomination papers; not on the primary ballot). Recorded by CA_0273 (2026-09-24).'),
  ('3ff9b0be-a73d-45f3-a82c-522a46c08a1f'::uuid, 'Elijah Crane', NULL, 'advanced', true,
   'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (Arizona Secretary of State, report 8/5/2026; operator-supplied 20260806_Primary_Canvass.pdf, page 2), U.S. Representative in Congress - District No. 2: REP Eli Crane 89,205, marked winner. Recorded by CA_0273 (2026-09-24).'),
  ('e839b499-a1fb-4315-9daa-fab748fba42b'::uuid, 'Jonathan Nez', NULL, 'advanced', true,
   'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (Arizona Secretary of State, report 8/5/2026; operator-supplied 20260806_Primary_Canvass.pdf, page 2), U.S. Representative in Congress - District No. 2: DEM Jonathan Nez 65,118, marked winner. Recorded by CA_0273 (2026-09-24).'),
  ('a48d4bf8-b07d-4ce8-bda5-6bd6b8b5c359'::uuid, 'Curtis Goodwin', NULL, 'advanced', false,
   'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (Arizona Secretary of State, report 8/5/2026; operator-supplied 20260806_Primary_Canvass.pdf, page 2), U.S. Representative in Congress - District No. 2: LBT Curtis Goodwin 318, marked winner (over write-in Alex Flores 10); race stays flagged: no Arizona November candidate list could be read (apps.arizona.vote is behind Cloudflare), so independents are unverified. Recorded by CA_0273 (2026-09-24).'),
  ('258881e7-9c9f-40c9-9cfd-6a2d167530b5'::uuid, 'Matt Schultz', 'advanced', 'not_nominated', true,
   'Alaska Division of Elections certified 2026 General candidate list (elections.alaska.gov/candidates/?election=26genr, updated 2026-09-02), UNITED STATES REPRESENTATIVE: Begich, Hafner, Hill, McDermott — each "(Certified)". Matt Schultz placed 3rd (13,149) in the top-four primary but is NOT on the certified general list: he left the ballot, and under AS 15.25.100(c) the vacancy passed down the order. Corrects 1856, which had recorded him advanced from the count alone. Recorded by CA_0273 (2026-09-24).'),
  ('c6e718bb-241c-4645-8ac1-1fcfec2f5f59'::uuid, 'James C. "Jim" McDermott', 'not_nominated', 'advanced', true,
   'Alaska Division of Elections certified 2026 General candidate list (elections.alaska.gov/candidates/?election=26genr, updated 2026-09-02), UNITED STATES REPRESENTATIVE: Begich, Hafner, Hill, McDermott — each "(Certified)". McDermott placed 8th (1,951) but IS certified on the general ballot, filling a top-four vacancy under AS 15.25.100(c). Corrects 1856, which had recorded him not_nominated from the count alone. Recorded by CA_0273 (2026-09-24).'),
  ('50f96010-94a8-43c6-ac8a-fa688fc9fe7c'::uuid, 'John B. Williams', NULL, 'not_nominated', true,
   'Alaska Division of Elections certified 2026 General candidate list (elections.alaska.gov/candidates/?election=26genr, updated 2026-09-02), UNITED STATES REPRESENTATIVE: Begich, Hafner, Hill, McDermott — each "(Certified)". John B. Williams placed 5th (4,413) and was held by 1856 pending a top-four withdrawal; he is NOT on the certified general list. Recorded by CA_0273 (2026-09-24).'),
  ('26756f61-8985-49f9-a2b8-d143f384672d'::uuid, 'Edward Codelia', NULL, 'not_nominated', true,
   'Hawaii Office of Elections, 2026 Primary SUMMARY REPORT FINAL (summary.txt), U.S. Representative, Dist II, and its rule for nonpartisan candidates in partisan contests (elections.hawaii.gov/candidates/nonpartisan-candidates-in-partisan-contests; HRS 12-41(b)): 10% of the votes cast for the office, or at least the lowest nominated partisan. Edward A. Codelia (N) 1,230 of ~128,940 votes cast for the office (under 1%), and below the lowest nominee (Awa, R, 26,290): qualifies under neither method. Recorded by CA_0273 (2026-09-24).')
) AS v(rc_id, full_name, prior_result, result, clear_provisional, result_source);

CREATE TEMP TABLE ca0273_nom ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('U.S. Representative District 1', 'Bryan Steil', '255d8144-689b-4753-b0e1-bf66ae283026'::uuid),
  ('U.S. Representative District 1', 'Mitchell Berman', '125d89b1-3764-465f-8eb8-807c965dd278'::uuid),
  ('U.S. Representative District 2', 'Mark Pocan', '59662930-3fe8-4e3e-8f02-2a341d58619f'::uuid),
  ('U.S. Representative District 3', 'Derrick Van Orden', '2bde2644-1e44-4537-b2f9-3bfd014f1ac2'::uuid),
  ('U.S. Representative District 3', 'Rebecca Cooke', '15fd9781-53bd-4a2c-a918-a475ded2832e'::uuid),
  ('U.S. Representative District 4', 'Tim Rogers', '8df2294b-67bd-4ce6-9d07-bcb964b6e26e'::uuid),
  ('U.S. Representative District 4', 'Gwen Moore', 'e268d067-d600-4443-939c-8dba4b2ecedb'::uuid),
  ('U.S. Representative District 5', 'Scott Fitzgerald', '7e2ff82b-e665-422f-a6b9-ee65682b1f6d'::uuid),
  ('U.S. Representative District 5', 'Andrew Beck', 'b8f48629-1d27-4a5f-a053-5446fdedaedf'::uuid),
  ('U.S. Representative District 6', 'Matthew Arndt', 'e9ed38b1-5e71-482f-96b8-331c63a3f083'::uuid),
  ('U.S. Representative District 6', 'Glenn Grothman', 'b1b79d5e-4e85-4348-ac57-65506c2dec60'::uuid),
  ('U.S. Representative District 6', 'Brad Smith', 'e3f5ae9f-a5e7-4eb1-bd6a-3c55b7ae8782'::uuid),
  ('U.S. Representative District 7', 'Michael Alfonso', '36971b6c-ae84-414c-9fe2-2ac666deeeb3'::uuid),
  ('U.S. Representative District 7', 'Fred Clark', '0f782c0a-9133-46d7-90aa-76ac8b7e556c'::uuid),
  ('U.S. Representative District 8', 'Tony Wied', '394452ec-3def-4802-9001-a85cad37ca4a'::uuid),
  ('U.S. Representative District 8', 'Rick Crosson', '33888d58-afd6-45e8-987a-405e73aaebd6'::uuid)
) AS v(position_name, full_name, politician_id);

CREATE TEMP TABLE ca0273_expect ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('WI','U.S. Representative District 1',2), ('WI','U.S. Representative District 2',1),
  ('WI','U.S. Representative District 3',4), ('WI','U.S. Representative District 4',3),
  ('WI','U.S. Representative District 5',2), ('WI','U.S. Representative District 6',5),
  ('WI','U.S. Representative District 7',2), ('WI','U.S. Representative District 8',2),
  ('AK','U.S. Representative At-Large',4),  ('HI','U.S. Representative District 2',2),
  ('AZ','U.S. Representative District 2',3)
) AS v(st, pos, expect);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0273_upd; IF n <> 44 THEN RAISE EXCEPTION 'PRE: % updates listed, expected 44', n; END IF;
  SELECT count(*) INTO n FROM ca0273_nom; IF n <> 16 THEN RAISE EXCEPTION 'PRE: % nominees listed, expected 16', n; END IF;

  -- Each update row: same id + name, and at its pre-image (first run) or already written by this file.
  SELECT count(*) INTO n FROM ca0273_upd u JOIN essentials.race_candidates rc ON rc.id = u.rc_id AND rc.full_name = u.full_name
   WHERE rc.result IS NOT DISTINCT FROM u.prior_result
      OR (rc.result = u.result AND rc.result_source = u.result_source);
  IF n <> 44 THEN RAISE EXCEPTION 'PRE: only % of 44 rows are at their pre-image or already written', n; END IF;

  -- Each nominee: the WI primary winner row for that district, same politician.
  SELECT count(*) INTO n FROM ca0273_nom x
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
                   JOIN essentials.elections e ON e.id = ra.election_id
                  WHERE e.state = 'WI' AND e.election_date = '2026-08-11' AND ra.position_name = x.position_name
                    AND rc.politician_id = x.politician_id::uuid);
  IF n <> 16 THEN RAISE EXCEPTION 'PRE: only % of 16 nominees match their WI primary row', n; END IF;

  -- The 11 November races resolve to exactly one race each, and every WI House race has an office.
  SELECT count(*) INTO n FROM ca0273_expect x
    JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
    JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.pos AND (x.st <> 'WI' OR ra.office_id IS NOT NULL);
  IF n <> 11 THEN RAISE EXCEPTION 'PRE: resolved % of 11 November races', n; END IF;

  RAISE NOTICE 'CA_0273 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1-4. Results (and flag clears), each guarded on its exact pre-image.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = u.result,
       result_source      = u.result_source,
       result_recorded_at = now(),
       last_verified_at   = now(),
       provisional_until  = CASE WHEN u.clear_provisional THEN NULL ELSE rc.provisional_until END,
       updated_at         = now()
  FROM ca0273_upd u
 WHERE rc.id = u.rc_id
   AND rc.result IS NOT DISTINCT FROM u.prior_result;

-- ---------------------------------------------------------------------------
-- 2c. The 16 Wisconsin nominees onto their November races.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source, result, result_source, result_recorded_at, last_verified_at)
SELECT ra.id, p.id, p.full_name, p.first_name, p.last_name,
       EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.office_id = ra.office_id AND och.politician_id = p.id),
       'active',
       'Wisconsin Elections Commission, Candidates on Ballot by Election, 2026 General Election (printed 8/25/2026); added by CA_0273 (2026-09-24)',
       'advanced',
       'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (printed 8/25/2026): on the November ballot as the certified primary winner (2026-08-11, certified 2026-08-25). Seeded by CA_0273 (2026-09-24).',
       now(), now()
  FROM ca0273_nom x
  JOIN essentials.politicians p ON p.id = x.politician_id::uuid
  JOIN essentials.elections e ON e.state = 'WI' AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = ra.id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0273_upd u JOIN essentials.race_candidates rc ON rc.id = u.rc_id
   WHERE rc.result = u.result AND rc.result_source = u.result_source
     AND (NOT u.clear_provisional OR rc.provisional_until IS NULL);
  IF n <> 44 THEN RAISE EXCEPTION 'POST: % of 44 rows in the expected end state', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates WHERE source LIKE '%added by CA_0273 (2026-09-24)';
  IF n <> 16 THEN RAISE EXCEPTION 'POST: % of 16 Wisconsin nominee rows present', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE source LIKE '%added by CA_0273 (2026-09-24)' AND is_incumbent;
  IF n <> 7 THEN RAISE EXCEPTION 'POST: % incumbents among the WI nominees, expected 7', n; END IF;

  FOR r IN
    SELECT x.st, x.pos, x.expect,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = ra.id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got
      FROM ca0273_expect x
      JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
      JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.pos
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: % % has % live candidates, expected %', r.st, r.pos, r.got, r.expect; END IF;
  END LOOP;

  -- Every WI House primary row now carries a result.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.state = 'WI' AND e.election_date = '2026-08-11' AND ra.position_name ~* 'U.S. Representative' AND rc.result IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % WI House primary rows still without a result', n; END IF;

  RAISE NOTICE 'CA_0273 applied: 44 rows reconciled, 16 WI nominees added; AZ CD2 Goodwin stays flagged (no November list)';
END $$;

COMMIT;
