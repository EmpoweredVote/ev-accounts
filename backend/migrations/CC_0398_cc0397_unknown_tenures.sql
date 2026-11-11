-- CC_0398 — settle the CC_0394 tenure starts that CC_0397 could not establish.
--
-- WHY. CC_0394 copied politicians.valid_from (the start of a person's CURRENT term) onto 290 tenures
-- as their first start in the seat. CC_0396 and CC_0397 fixed 107 of them. CC_0397 left 62 local
-- tenures it could not establish either way, mostly because the city sites refused its fetches. This
-- file settles 41 of those 62, plus two rows CC_0397 flagged as wrong newcomers (Rebecca B. Orr,
-- Lucas, and Zach Williams, Van Alstyne).
--
-- HOW IT WAS CHECKED. Each of the 62 was researched again against the body's own minutes and
-- publications, Collin County's official results reports (now at new addresses on its results
-- archive), and local news. GoodParty, BallotReady and AI summary sites were not accepted as a sole
-- source. The question per row, as in CC_0397: did this person hold THIS seat (same office, same
-- place, continuous service) before the stored date?
--
--   21  EARLIER     held this seat before the stored date               -> term_start NULL ('unknown')
--   21  LATER       took this seat AFTER the stored date                -> 13 NULL, 7 re-dated, 1 left (Perez)
--   18  FIRST       stored date is the first start (to the month)       -> untouched
--    2  UNKNOWN     Josephine's Jason Turney (Mayor) and Gary Chappell   -> untouched
--  plus Orr and Z. Williams (newcomers, CC_0397 "Found, not fixed")      -> re-dated
--
-- The three rotating mayors are NOT written here: Tamala Takahashi (Burbank) and Ardy Kassakhian
-- (Glendale) count as FIRST above because their stored date is right for their COUNCIL seat, and
-- Jennifer Perez (Norwalk) is the one LATER row left alone (her council oath was April 2017, a month
-- after the stored 2017-03-07). Their stored Mayor start is their council start; what a rotating
-- mayoralty's tenure means awaits a ruling. So 21 + 20 = 41 of the 62 are written, plus Orr and
-- Williams: 43 tenures (34 undated, 9 re-dated).
--
-- 🔴 EARLIER AND MOST LATER ROWS ARE UNDATED, NOT RE-DATED (CC_0397's rule). Their earlier or later
-- start rests on an election result, a canvass or a bio year, which proves the stored date FALSE
-- but does not give the day the person took office. NULL is true and keeps the person seated.
--
-- 🔴 RE-DATED ROWS ARE DAY PRECISION FROM THE OATH OR THE BODY'S OWN TERM RECORD. Each was read from
-- the document itself, not a summary:
--   Rachel Dumas        2025-11-18  Lavon minutes 18 Nov 2025 (oath; beat incumbent Ted Dill)
--   Matthew Marchiori   2025-09-16  Weston special-meeting minutes (appointed Mayor and sworn in)
--   Brian M. Roach      2025-11-12  Weston minutes 12 Nov 2025 (oath for new aldermen)
--   Jill Hawkins        2025-05-06  Fairview Town News, June 2025 (sworn in as a new member)
--   Pat Sheehan         2025-05-06  same
--   Joe W. Boggs        2026-06-02  Fairview Town News, July 2026 (oaths of office, 2 Jun 2026)
--   John Stanley        2026-06-02  same
--   Rebecca B. Orr      2026-05-21  Lucas council meeting record: oath of office, City Council Seat 2
--   Zach Williams       2026-05-12  Van Alstyne member page: "Term: May 12 2026 - May 08 2029"
-- Patti Harrington (Weston) was appointed on 12 Aug 2025, but those minutes record the vote and no
-- oath, so she is undated. Travis Jacob (Lavon) was canvassed 18 Nov 2024 with no oath date found.
--
-- 🔴 SEVEN RACE ROWS FLIP TO NOT INCUMBENT. Each person was a challenger or an open-seat winner, and
-- each tenure is dated (or undated) here so the record says so:
--   Rachel Dumas    Lavon Place 4        2025-11-04  beat incumbent Ted Dill (canvass, 18 Nov 2025 minutes)
--   April Aurand    Josephine Place 1    2025-11-04  beat incumbent Doug Ewing (Collin County results)
--   Jane Ridgway    Josephine Place 2    2025-11-04  beat incumbent Brad Ahlfinger (Collin County results)
--   Rebecca B. Orr  Lucas Seat 2         2026-05-02  first run; outgoing Seat 2 member Stubblefield
--   Zach Williams   Van Alstyne Place 6  2026-05-02  Angelica Pena held Place 6 from 2023
--   Joe W. Boggs    Fairview Seat 2      2026-05-02  Gregg Custer held Seat 2 until May 2026
--   John Stanley    Fairview Seat 4      2026-05-02  Larry Little held Seat 4 until May 2026
-- The four 2026-05-02 rows are inside the one-year window check:incumbency reads. Each of those
-- people is re-dated AFTER election day in the same write, so the race row and the tenure agree.
-- The three 2025-11-04 rows are outside the window; they are fixed because they are wrong.
-- Aurand and Ridgway are undated: an undated tenure reads as "held on election day" to the
-- predicate, and this is the one place the predicate is wrong — they took office after it.
--
-- NOT DONE HERE, reported in the PR: Jessica Walden (Anna Place 3) is a newcomer our race row marks
-- incumbent, but no oath date was found to re-date her consistently; Kelly Patterson-Herndon (Anna
-- Place 4) held the seat from June 2024 but her May 2025 race row says not incumbent; Blue Ridge
-- and Weston seats are at-large, so our "Place N" titles are invented; the three rotating mayors.
--
-- NOT tagged '| unverified' (CA_0171): that tag would drop sitting officeholders from history.
-- OVERWRITE RECORD: every row's previous value is in the plan below and, with the research behind
-- it, in backend/data/transition-tracker/cc_0398_evidence.json.
--
-- Idempotent: each write is guarded on the value it changes.

BEGIN;

CREATE TEMP TABLE cc0398_plan (
  term_id     uuid PRIMARY KEY,
  who         text NOT NULL,
  seat        text NOT NULL,
  was_start   date NOT NULL,
  was_prec    text NOT NULL,
  new_start   date,
  new_prec    text NOT NULL,
  kind        text NOT NULL CHECK (kind IN ('reelected','too_early')),
  citation    text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0398_plan VALUES
 ('ef2fe745-f524-4fa3-af99-432a4de30480','Elden Baker','Anna Council Member Place 5','2026-05-01','month',NULL,'unknown','reelected','First won Anna Place 5 in May 2023 and was re-elected May 2, 2026. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-6-2023-combined-accumulated-totals-official-final.pdf?sfvrsn=195d3ddd_0)'),
 ('bd2f1fb8-fad1-4949-abc3-68609f5eb088','Kevin Toten','Anna Council Member Place 1','2024-05-01','month',NULL,'unknown','reelected','Won the Anna Place 1 runoff on June 16, 2018 and has held Place 1 since; 2024 was a re-election. The city bio says May 2018, but the seat was decided in the June 2018 runoff. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/june-16-2018-combined-election-day-and-early-ballots-accumulated-totals.pdf?sfvrsn=d86d8e27_0)'),
 ('d0b5a2b8-04e0-4175-b64b-45643bb4d047','Debbie Fisher','Lucas Council Member Place 5','2024-05-01','month',NULL,'unknown','reelected','She was sworn in for Seat 5 as an incumbent on May 19, 2022 (the 2022 Seat 5/6 election was cancelled as unopposed), so she held Seat 5 before then, likely since 2019. 2022-05 is the earliest date confirmed, not her true first start; she was re-elected again in May 2025. (https://lucastx.new.swagit.com/videos/174174)'),
 ('2962b1bf-7d9a-4f70-83c1-9ea1619d749a','Phil Lawrence','Lucas Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','He was re-elected to Seat 4 in 2018, unopposed in 2021, and re-elected in 2024; the city bio says fifth term, implying first election around 2012. All quotes came from search snippets because the pages refused direct fetch, so 2018-05 is a floor, not the first start. (https://www.lucastexas.us/contacts/philip-lawrence)'),
 ('8789cf7e-0fd2-4d63-a9e0-f039893ee57b','Lee Pettle','Parker Mayor','2026-05-01','month',NULL,'unknown','reelected','Minutes confirm he was mayor throughout 2024, well before the stored 2026-05 date. A news snippet says he was first elected mayor in May 2018; continuous service 2018-2024 was not checked meeting by meeting. (https://swagit-attachments.granicus.com/uploads/video/agenda_file/308369/6-18_ParkerCC.pdf)'),
 ('41ef8eeb-cc6f-40e1-a2d5-8128fb545760','Katrina Arsenault','Van Alstyne Council Member Place 5','2025-05-04','day',NULL,'unknown','reelected','She took the oath for Place 5 at or just before the May 9, 2023 meeting and was re-elected in 2025 (the 2025 council race did not appear on the county ballot, so it was likely cancelled as unopposed). She was also on the council in May 2022, but the Home Rule Charter was adopted that month and place numbers may have changed, so 2023-05 is the earliest confirmed date for Place 5. (https://cityofvanalstyne.civicweb.net/document/10684)'),
 ('20467965-e360-49db-b037-597e14666a6e','Lee Thomas','Van Alstyne Council Member Place 4','2025-05-04','day',NULL,'unknown','reelected','He was sworn in for Place 4 on May 9, 2023, sat through 2024, and was re-elected in 2025. He was also on the council in May 2022 (seat number then not confirmed). (https://cityofvanalstyne.civicweb.net/document/10684)'),
 ('b49ccd58-fb4c-4135-9925-8d1278a63e50','Lakia Works','Fairview Council Member Seat 6','2026-05-01','month',NULL,'unknown','reelected','Works was appointed to Seat 6 in May 2025, after John Hubbard left it to become mayor. She then won the seat in May 2026. A news snippet that could not be opened gave the vote date as May 20; the town newsletter says May 29. (https://fairviewtexas.org/wp-content/uploads/2025/11/July-2025-Fairview-Town-News.pdf)'),
 ('c8cd8d2b-cca0-4719-b72e-a27ff95c4436','Craig Ackerman','Melissa Council Member Place 5','2024-05-01','month',NULL,'unknown','reelected','Ackerman won Melissa Place 5 on May 6, 2017 (county results). The FY23 and FY24 city budgets list him on the council as Mayor Pro Tem. Service since 2017 looks continuous, but I did not find a document that shows every year. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-6-2017-combined-election-day-and-early-ballots-accumulated-totals-final.pdf?sfvrsn=3305428e_0)'),
 ('cf793d45-5fb7-4f66-9501-11cb79499d2f','Dana Conklin','Melissa Council Member Place 3','2024-05-01','month',NULL,'unknown','reelected','Conklin held Place 3 in the FY23 budget (2022) and won re-election as the incumbent in May 2024. Her first year is not found; it is 2022 or earlier, probably 2021, an uncontested year with no county race. (https://stories.opengov.com/cityofmelissatx/published/mnY_sBMnD)'),
 ('3d663b5f-43d6-4fa9-95c9-f2f3020e71ff','Jay Northcut','Melissa Mayor','2024-05-01','month',NULL,'unknown','reelected','Northcut won the mayor''s race in May 2022 and was re-elected in May 2025. A Dallas News snippet says he was elected mayor in May 2022, which suggests 2022 was his first mayoral term, but I could not open the article. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-7-2022-combined-election-day-and-early-ballots-accumulated-totals.pdf?sfvrsn=4e64808a_0)'),
 ('c7283331-0f87-42b2-888d-d6c8943bc81a','Joseph Armstrong','Melissa Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','Armstrong won Place 4 unopposed in May 2022 and was on the 2025 ballot again. I did not find whether he held the seat before 2022, so 2022-05 is the earliest date I can confirm. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-7-2022-combined-election-day-and-early-ballots-accumulated-totals.pdf?sfvrsn=4e64808a_0)'),
 ('529e31c1-ae16-441b-afc5-d2c84ce49be2','Rendell Hendrickson','Melissa Council Member Place 2','2024-05-01','month',NULL,'unknown','reelected','Chad Taylor won Place 2 in May 2022. Hendrickson is on the FY24 budget council list (adopted about Sept 2023), so he likely replaced Taylor in 2022-2023, probably by appointment. That evidence is only a search summary, and his place number in that list is not confirmed. (https://www.cityofmelissa.com/Archive.aspx?ADID=137)'),
 ('92b4d5b1-fa1a-4c08-8296-f375afe1a443','Sean Lehr','Melissa Council Member Place 6','2024-05-01','month',NULL,'unknown','reelected','Lehr won contested Place 6 in May 2022 and is listed in the FY23 and FY24 budgets. I did not check whether he served before 2022. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-7-2022-combined-election-day-and-early-ballots-accumulated-totals.pdf?sfvrsn=4e64808a_0)'),
 ('3e517eb8-a570-4402-bb89-603a3eec5983','David Apple','Blue Ridge Council Member Place 1','2026-05-01','month',NULL,'unknown','reelected','City ''State of the City 2025'' report says he has served since 2024 (the 2024 election was cancelled and the council filled a vacant seat), so the May 2026 term is a renewal. Exact 2024 month not found. Blue Ridge seats are at-large, so ''Place 1'' is not a real seat label. (https://ecode360.com/BL6250/document/753119705.pdf)'),
 ('6d6ee8ee-6cbc-40ea-b9a5-e1e1bdcdbcd7','Keith Chitwood','Blue Ridge Council Member Place 5','2026-05-01','month',NULL,'unknown','reelected','City 2025 report lists him as Mayor Pro Tem serving on council since 2018; the May 2026 term is a renewal. Seats are at-large, so ''Place 5'' is not a real seat label. (https://ecode360.com/BL6250/document/753119705.pdf)'),
 ('518c44ca-d537-4771-8eba-c8660dd63753','Rhonda Williams','Blue Ridge Mayor','2026-05-01','month',NULL,'unknown','reelected','City 2025 report says she has served since 2013 under the Mayor heading, and she signed a 2023 election certificate as Mayor. The May 2026 term is a renewal. It is not clear whether all of 2013 onward was as mayor. (https://ecode360.com/BL6250/document/753119705.pdf)'),
 ('171c5f13-e8e9-455f-92b0-4e66e954540e','Alex Esquivel','Josephine Council Member Place 3','2024-05-01','month',NULL,'unknown','reelected','Won Place 3 unopposed on 7 Nov 2023 (the earlier snippet saying Place 2 was wrong; Place 2 in 2023 was Ridgway vs Ahlfinger). Place 3 was held by Ahlfinger after 2020, so Nov 2023 is most likely his first start, though a mid-term appointment before that cannot be ruled out. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/november-7-2023-combined-election-day-and-early-ballots-accumulated-totals-final-official-results.pdf?sfvrsn=51d2c81b_0)'),
 ('cefab288-b916-434e-a5b3-6a2f8e903d53','Jeff Metzger','Weston Council Member Place 3','2024-05-01','month',NULL,'unknown','reelected','Won one of three at-large seats on 8 Nov 2022 (2nd of 6), canvassed 21 Nov 2022, and was voting as a council member by Jan 2023. He was absent from Aug and Nov 2022 vote records, so Nov 2022 is most likely his first start. Re-elected 2024. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/november-8-2022-general-and-special-election-combined-accumulated-totals.pdf?sfvrsn=e336cc91_0)'),
 ('46a63173-c9f7-496a-b319-787df9bbf6cf','Mike Hill','Weston Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','First elected 3 Nov 2020 (canvassed 10 Nov 2020, with an oath item for new members). He is not in the March or Oct 2020 vote records. Re-elected Nov 2022 and Nov 2024 to Weston''s at-large seats, and he ran again in Nov 2026. (https://www.westontexas.com/upload/common/Minutes/2020%20Minutes/Minutes%202020-11-10.pdf)'),
 ('722774a0-4575-486c-8084-81732e655623','Victor Preciado','Pomona Council Member','2022-11-14','day',NULL,'unknown','reelected','He first won District 2 in Nov 2018 and was re-elected in Nov 2022 (county results), so he held the seat before the stored Nov 2022 date. The 2018 win and the Jan 2019 start come from Ballotpedia, backed by The Pomonan; the city bio would not load. Early Nov 2026 counts show challenger Jacky Elizalde leading him, so he may leave the seat in Dec 2026. (https://results.lavote.gov/text-results/4300)'),
 ('f60a0120-0ea4-4547-852b-5587e91c0e1a','Kelly Patterson-Herndon','Anna Council Member Place 4','2024-05-01','month',NULL,'unknown','too_early','May 2024 Place 4 unexpired-term race went to a runoff, which she won on June 15, 2024; re-elected to a full term May 2025. She also ran for Place 3 in May 2023 and lost. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/june-15-2024-joint-runoff-election-early-ballots-combined-accumulated-totals-official-final.pdf?sfvrsn=2692db4_0)'),
 ('f1840326-580f-4e0a-92d9-5e4b3ee625fb','Manny Singh','Anna Council Member Place 6','2024-05-01','month',NULL,'unknown','too_early','First elected to Place 6 in May 2025, a year after the stored date. The county PDF prints identical vote totals for Place 4 and Place 6 in 2025, which may be a report layout error, but the winner is clear. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-3-2025-election-summary-results-report-official-final.pdf?sfvrsn=ef78248c_0)'),
 ('7171dd0a-8464-40e3-8a1b-90a0e9f6cb43','Nathan Bryan','Anna Council Member Place 2','2024-05-01','month',NULL,'unknown','too_early','Led the May 2025 Place 2 race without a majority and won the June 7, 2025 runoff. In May 2024 the Place 2 unexpired term was contested by Bills, Dillingham and Engels, not Bryan. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/may-3-2025-election-summary-results-report-official-final.pdf?sfvrsn=ef78248c_0)'),
 ('36b1acd2-61ae-4a4c-b789-0612790b7ca8','Colleen Halbert','Parker Council Member Place 2','2024-05-01','month',NULL,'unknown','too_early','She was not on the council in June or December 2024 (the five members were Reed, Fecht, Kercho, Noe, Pilgrim). She was elected at large in the May 3, 2025 election (canvass Resolution 2025-844); exact oath day not found. Parker seats are at large, not numbered places. (https://parkertexas.us/Archive/ViewFile/Item/4254)'),
 ('b579a83f-f9b8-4709-bce6-48739ec4e3b0','Darrel Sharpe','Parker Council Member Place 4','2024-05-01','month',NULL,'unknown','too_early','He was not on the council in 2024 and was elected at large on May 3, 2025 (canvass Resolution 2025-844); exact oath day not found. (https://parkertexas.us/Archive/ViewFile/Item/4254)'),
 ('592e8069-d5d0-4556-ab52-ae6970a088b2','Roxanne Bogdan','Parker Council Member Place 1','2024-05-01','month',NULL,'unknown','too_early','In the Dec 3, 2024 minutes she spoke as a member of the public, not a councilmember. She was elected at large on May 3, 2025 (canvass Resolution 2025-844); exact oath day not found. (https://parkertexas.us/Archive/ViewFile/Item/4254)'),
 ('05d57508-bb97-4c7b-ab39-0c6bc0fee7cb','Linda Braly','Blue Ridge Council Member Place 2','2024-05-01','month',NULL,'unknown','too_early','Elected as a newcomer in the 3 May 2025 at-large election (Farmersville Times, 8 May 2025), so the stored 2024-05 is a year too early. She is now Mayor Pro Tem; the city elections page spells her name ''Braley''. (https://farmersvilletimes.com/?p=18317)'),
 ('92a88048-ebb1-43d2-9570-d373c0cf6478','Trenton Sissom','Blue Ridge Council Member Place 3','2024-05-01','month',NULL,'unknown','too_early','Newcomer elected in the 3 May 2025 at-large election; stored 2024-05 is a year too early. (https://farmersvilletimes.com/?p=18317)'),
 ('f9dd8734-43a7-42e7-bccf-f25ce13dcbfd','Wendy Mattingly','Blue Ridge Council Member Place 4','2024-05-01','month',NULL,'unknown','too_early','Newcomer elected in the 3 May 2025 at-large election; stored 2024-05 is a year too early. (https://farmersvilletimes.com/?p=18317)'),
 ('4ceb9d95-7895-4a30-9988-436b1c28b1ac','April Aurand','Josephine Council Member Place 1','2024-05-01','month',NULL,'unknown','too_early','Doug Ewing held Place 1 from Nov 2023; Aurand defeated him on 4 Nov 2025, so she took Place 1 in Nov 2025, not 2024-05. An undated directory (txdirectory.com) lists her as an alderman on an older roster, so she may have served earlier, but not continuously. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/november-4-2025-summary-results-report-official-final.pdf?sfvrsn=dc3d7670_0)'),
 ('3d353b2d-dfc5-49cb-bb2c-927fd07b1205','Jane Ridgway','Josephine Council Member Place 2','2024-05-01','month',NULL,'unknown','too_early','She lost Place 2 to Ahlfinger in Nov 2023 and won it back from him on 4 Nov 2025, so her current continuous service starts Nov 2025. She probably held Place 2 before Nov 2023 too, but that service was broken. (https://www.collincountytx.gov/docs/default-source/elections/results-archive/november-4-2025-summary-results-report-official-final.pdf?sfvrsn=dc3d7670_0)'),
 ('fa46e928-703f-4b51-93b9-ee1bfa128f8f','Travis Jacob','Lavon Council Member Place 3','2024-05-01','month',NULL,'unknown','too_early','He defeated incumbent Kay Wright in the Nov 5, 2024 election (canvassed Nov 18, 2024) and was seated by the Dec 3, 2024 meeting. The prior note that Wright held Place 3 through Jan 2025 is contradicted by the Dec 3, 2024 roll call; the exact oath date was not found (likely the Nov 19, 2024 meeting). (https://cityoflavon.com/wp-content/uploads/Public-Documents/City%20Council%20Agendas/2024-11-18%20Agenda%20CC%20Special%20Meeting.pdf)'),
 ('05c8ecb4-972f-46bc-b3fb-fc57057d0e75','Patti Harrington','Weston Council Member Place 1','2024-05-01','month',NULL,'unknown','too_early','Appointed to a vacant alderman seat on 12 Aug 2025, then elected on 4 Nov 2025 (2nd of 4 for two at-large seats). Seats are at-large, so it is unclear whether the elected seat is the same one she was appointed to. Her service as alderman has been continuous since Aug 2025. (https://www.westontexas.com/upload/page/0044/docs/Minutes%20-%208.12.25%20-%20Corrected.pdf)'),
 ('393ff895-032b-4950-9662-e18a66eaa345','Rachel Dumas','Lavon Council Member Place 4','2024-05-01','month','2025-11-18','day','too_early','Lavon minutes 18 Nov 2025: oath administered to Place Four (4) Rachel Dumas, who beat incumbent Ted Dill 658-319 on 4 Nov 2025 (https://lavontx.gov/wp-content/uploads/Public-Documents/City%20Council%20Minutes/2025-11-18-CC-Meeting-Minutes.pdf)'),
 ('e608cac7-4853-448a-9338-4f0718a1e0d0','Brian M. Roach','Weston Council Member Place 2','2024-05-01','month','2025-11-12','day','too_early','Weston minutes 12 Nov 2025: Oath of Office for new aldermen, Alderman Brian Roach; absent from the 28 Oct 2025 roll call (https://www.westontexas.com/upload/page/0044/11.12.25%20Minutes.pdf)'),
 ('1f1177b9-bef5-474e-96c2-8ddf86fb2539','Matthew Marchiori','Weston Mayor','2024-05-01','month','2025-09-16','day','too_early','Weston minutes 16 Sep 2025: council appointed Marchiori Mayor after Mayor Richardson resigned; Mayor Marchiori Sworn in with Oath of Office (https://www.westontexas.com/upload/page/0044/docs/Minutes%20-%209.16.25%20-%20Special%20Meeting%20-%20Corrected.pdf)'),
 ('ae9ebad4-3485-486c-92c2-4424dbc3e13c','Jill Hawkins','Fairview Council Member Seat 3','2023-05-01','month','2025-05-06','day','too_early','Fairview Town News June 2025: at the May 6, 2025 meeting new Council members Jill Hawkins, Seat 3, and Pat Sheehan, Seat 5, were sworn into office; Ricardo Doi held Seat 3 in Sept 2023 (https://fairviewtexas.org/wp-content/uploads/2025/11/June-2025-Fairview-Town-News.pdf)'),
 ('46a7716b-cf35-4bd1-8032-6aca097d98b5','Pat Sheehan','Fairview Council Member Seat 5','2024-05-01','month','2025-05-06','day','too_early','Fairview Town News June 2025: at the May 6, 2025 meeting new Council members Jill Hawkins, Seat 3, and Pat Sheehan, Seat 5, were sworn into office; Ken Logsdon held Seat 5 in Sept 2023 (https://fairviewtexas.org/wp-content/uploads/2025/11/June-2025-Fairview-Town-News.pdf)'),
 ('bf194891-dc4f-454b-8a51-a5f810811f1a','Joe W. Boggs','Fairview Council Member Seat 2','2026-05-01','month','2026-06-02','day','too_early','Fairview Town News July 2026: at the June 2, 2026 meeting the Council administered the oaths of office for Councilmembers Joe Boggs (Seat 2), John Stanley (Seat 4) and Lakia Works (Seat 6); Gregg Custer held Seat 2 until May 2026 (https://fairviewtexas.org/wp-content/uploads/2025/11/July-2026-Fairview-Town-News.pdf)'),
 ('fb2e27b3-0e59-4dba-8986-60bc753fbf9e','John Stanley','Fairview Council Member Seat 4','2026-05-01','month','2026-06-02','day','too_early','Fairview Town News July 2026: at the June 2, 2026 meeting the Council administered the oaths of office for Councilmembers Joe Boggs (Seat 2), John Stanley (Seat 4) and Lakia Works (Seat 6); Larry Little held Seat 4 until May 2026 (https://fairviewtexas.org/wp-content/uploads/2025/11/July-2026-Fairview-Town-News.pdf)'),
 ('d6190382-580c-40b0-8122-132c898447db','Rebecca B. Orr','Lucas Council Member Place 2','2026-05-01','month','2026-05-21','day','too_early','Lucas council meeting 21 May 2026: Administer the Oath of Office and Certificate of Election to Jonathan Underhill, City Council Seat 1, and Rebecca Orr, City Council Seat 2; outgoing Seat 2 member Stubblefield recognized (https://lucastx.new.swagit.com/videos/388905)'),
 ('f7c58488-4af3-4d42-901b-385c692d7d10','Zach Williams','Van Alstyne Council Member Place 6','2026-05-02','day','2026-05-12','day','too_early','Van Alstyne member page: Zach Williams Alderman Place 6, Term: May 12 2026 - May 08 2029; elected to City Council Place 6 in 2026; Angelica Pena held Place 6 from 2023 (https://cityofvanalstyne.civicweb.net/portal/members.aspx?id=10)');

CREATE TEMP TABLE cc0398_race (
  race_candidate_id uuid PRIMARY KEY,
  term_id           uuid NOT NULL,
  who               text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0398_race VALUES
 ('ee87628c-f5ce-44a4-b3c7-aaac25bebbe0','393ff895-032b-4950-9662-e18a66eaa345','Rachel Dumas'),
 ('f08d5211-bee1-4366-9660-e8996977f94e','bf194891-dc4f-454b-8a51-a5f810811f1a','Joe W. Boggs'),
 ('7030946d-e3a8-4739-8aa3-990f4c2cef93','fb2e27b3-0e59-4dba-8986-60bc753fbf9e','John Stanley'),
 ('69dbcd49-8695-49da-b47c-db26652e0eaa','d6190382-580c-40b0-8122-132c898447db','Rebecca B. Orr'),
 ('f05866a3-5b72-40ef-ab3b-f0fc088dee2d','f7c58488-4af3-4d42-901b-385c692d7d10','Zach Williams'),
 ('c8b28827-54cc-4f00-b262-3b9cee8d73b0','4ceb9d95-7895-4a30-9988-436b1c28b1ac','April Aurand'),
 ('456babdb-5027-4c10-83ba-2912c55271cd','3d353b2d-dfc5-49cb-bb2c-927fd07b1205','Jane Ridgway');

-- ---------------------------------------------------------------------------------------------
-- Pre-gate.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  IF (SELECT count(*) FROM cc0398_plan) <> 43 THEN
    RAISE EXCEPTION 'CC_0398 pre-gate: plan holds % rows, expected 43', (SELECT count(*) FROM cc0398_plan);
  END IF;

  -- Each row is an open tenure CC_0394 dated, held by the named person, still at the measured value
  -- (or already at the target, on a re-run).
  SELECT count(*) INTO v_bad
    FROM cc0398_plan pl
    LEFT JOIN essentials.office_terms ot ON ot.id = pl.term_id AND ot.term_end IS NULL
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.id IS NULL
      OR p.full_name IS DISTINCT FROM pl.who
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR NOT ( (ot.term_start = pl.was_start AND ot.start_precision = pl.was_prec)
            OR (ot.term_start IS NOT DISTINCT FROM pl.new_start AND ot.start_precision = pl.new_prec) );
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 pre-gate: % plan row(s) do not match the tenure they name', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0398_plan
   WHERE (new_start IS NULL) <> (new_prec = 'unknown')
      OR (kind = 'reelected' AND new_start IS NOT NULL)
      OR (new_start IS NOT NULL AND new_start <= was_start)
      OR (new_prec = 'year'  AND to_char(new_start, 'MM-DD') <> '01-01')
      OR (new_prec = 'month' AND extract(day FROM new_start) <> 1);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 pre-gate: % plan row(s) are internally inconsistent', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0398_race r
    LEFT JOIN essentials.office_terms ot ON ot.id = r.term_id
    LEFT JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
                                           AND rc.politician_id = ot.politician_id
   WHERE rc.id IS NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 pre-gate: % race row(s) do not belong to the planned tenure', v_bad;
  END IF;
END $$;

-- Every person whose office_terms row this writes. No seating happens here and no predecessor term
-- is closed, so the plan's own holders are BOTH sides of every write.
CREATE TEMP TABLE cc0398_people ON COMMIT DROP AS
SELECT DISTINCT ot.politician_id
  FROM cc0398_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — NULLs term_start on 34 and moves it later on 9 CC_0394-dated open tenures (no seating, no predecessor closed) and sets 7 newcomer race rows to not incumbent

-- Snapshot what the cached column says, and what office_terms says, for every race row belonging to
-- a person this migration touches. `expected` is reconcile-incumbency.mjs's own SQL.
--
-- ⚠ KEEP THE `expected` EXPRESSION AND THE THREE WHERE CLAUSES CHARACTER-IDENTICAL TO THE SCRIPT
-- (backend/scripts/reconcile-incumbency.mjs, computeIncumbencyDrift). If they drift apart, this
-- passes while CI fails, which is worse than having no guard — you would then believe the question
-- had been asked.
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0398_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Write.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.office_terms ot
   SET term_start      = pl.new_start,
       start_precision = pl.new_prec,
       source          = ot.source || ' | CC_0398: '
                         || CASE WHEN pl.new_start IS NULL
                                 THEN CASE pl.kind WHEN 'reelected' THEN 'term start RETURNED TO UNDATED, because this person held the seat before the CC_0394 date (that date is a later term''s start). ' ELSE 'term start RETURNED TO UNDATED, because this person took the seat AFTER the CC_0394 date and no oath record gives the day. ' END
                                 ELSE 'term start moved to ' || to_char(pl.new_start, 'YYYY-MM-DD')
                                      || ' (' || pl.new_prec || ' precision); the CC_0394 date was before this person took the seat; the new date is the oath or term-start day in the source. ' END
                         || pl.citation || '.'
  FROM cc0398_plan pl
 WHERE ot.id = pl.term_id
   AND (ot.term_start IS DISTINCT FROM pl.new_start OR ot.start_precision IS DISTINCT FROM pl.new_prec);

UPDATE essentials.race_candidates rc
   SET is_incumbent = false
  FROM cc0398_race r
 WHERE rc.id = r.race_candidate_id
   AND rc.is_incumbent IS DISTINCT FROM false;

-- ▼▼ BLOCK B — PASTE AFTER YOUR LAST WRITE TO essentials.office_terms, BEFORE COMMIT ▼▼

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0398_people;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
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

-- ▲▲ END OF BLOCK B ▲▲

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM cc0398_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE ot.term_start IS DISTINCT FROM pl.new_start
      OR ot.start_precision IS DISTINCT FROM pl.new_prec
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR ot.source NOT LIKE '%CC_0398:%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 gate: % tenure(s) do not carry the planned value with provenance intact', v_bad;
  END IF;

  -- Nobody is unseated: every planned holder still resolves as the current holder.
  SELECT count(*) INTO v_bad
    FROM cc0398_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = ot.office_id AND och.politician_id = ot.politician_id);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 gate: % officeholder(s) no longer resolve as current', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0398_race r JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
   WHERE rc.is_incumbent IS DISTINCT FROM false;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0398 gate: % race row(s) still marked incumbent', v_bad;
  END IF;
END $$;

COMMIT;
