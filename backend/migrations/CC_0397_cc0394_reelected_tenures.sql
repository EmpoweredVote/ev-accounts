-- CC_0397 — correct the CC_0394 tenure starts that were really the start of a LATER term.
--
-- WHY. CC_0394 copied politicians.valid_from onto 290 tenures as the date each person first took
-- the seat. That column holds the start of the person's CURRENT TERM. For a newcomer the two are the
-- same; for anyone re-elected they are not, and the tenure then claims the person was not in office
-- before their latest re-election. CC_0396 fixed the 7 rows where that turned check:incumbency red.
-- This file fixes the rest that research could establish.
--
-- HOW IT WAS CHECKED. All 236 local and Indiana tenures still carrying a CC_0394 date were researched
-- against the bodies' own sites, minutes, county results and local news (GoodParty, BallotReady and
-- AI summary sites were not accepted as a sole source). Per row the question was: did this person
-- already hold THIS seat (same office, same place/district, continuous service) before the stored
-- date? The 50 federal and California/Indiana statewide rows were reviewed by hand and left alone:
-- their dates are first starts (e.g. Fiona Ma 2019-01-07, Karen Ross 2011-01-12).
--
--   84  EARLIER       held this seat before the stored date      -> term_start NULL ('unknown')
--   16  TOO EARLY     took this seat AFTER the stored date        -> the sourced date, see below
--   68  confirmed     stored date matches the person's first start -> untouched
--    6  near-match    a few days or one month off, not contradicted -> untouched
--   62  unknown       could not be established either way         -> untouched (listed in the PR)
--
-- 🔴 WHY EARLIER ROWS ARE UNDATED, NOT RE-DATED. Most of the earlier starts the research found rest on
-- an election year, a bio line ("first elected 2018") or a fetch tool's summary of a page rather than
-- the page itself. That is enough to prove the stored date FALSE, and not enough to publish a new
-- one. NULL is true; a re-date would need the oath record. A later pass can date them one by one.
-- Undating keeps the person seated: office_current_holder treats a NULL start as open-ended.
--
-- 🔴 TOO-EARLY ROWS TAKE THE COARSEST PRECISION THEIR SOURCE SUPPORTS (the CC_0394 asymmetry rule).
-- A source that says only "elected in 2025" yields year 2025, not the month of the election, because
-- the oath may fall in the following month. Day precision only where minutes record the oath:
--   Tammy Hodges, Agur Rios, Pat Kelly (Lowry Crossing minutes, 12 Nov 2024 and 11 Nov 2025) and
--   Larry Nail (St. Paul minutes, 8 Jul 2024, "Swearing in and seating of Larry Nail").
-- Eugene Escobar Jr. (Princeton mayor) won the 14 Dec 2024 runoff; whether he was sworn in December
-- or January is not sourced, so he is UNDATED rather than given a year that might be wrong.
-- Ken Cook and Carl Clemencich (Allen, seated after the June 2024 runoff) and Terrance Johnson and
-- Cristina Todd (Princeton, elected 4 Nov 2024) are UNDATED too: their sources support only the year
-- 2024, and a year is stored as 1 January, which would be EARLIER than the May 2024 value it replaces
-- and would seat them before they were elected. 6 too-early rows are therefore undated, 10 re-dated.
--
-- 🔴 TWO RACE ROWS FLIP. Lowry Crossing's 11 Nov 2025 minutes: the roll call before the oath lists
-- neither Pat Kelly nor Agur Rios; then "Janis Cable led newly elected officials in the Oath of
-- Office", naming "Pat Kelly Mayor 2-year term" and "Agur Rios Ward 2 1-year term". The 10 Jun 2025
-- roll call names Bob Petitt, then mayor. So both were challengers in the 4 Nov 2025 election, and
-- once their tenures are dated correctly race_candidates.is_incumbent must say so:
--   0c59532f-ae5b-4ef7-bf0a-0f5269095973  Pat Kelly   true -> false
--   0aec1f87-4b53-48cc-ab2d-4f263a4aed9b  Agur Rios   true -> false
-- ⚠ That election (2025-11-04) is just outside the one-year window check:incumbency and the
-- incumbency guard read, so neither would have flagged these two. They are flipped because they are
-- wrong, not because a gate asked. The guard below was watched failing: pushing John Nustad's
-- (Longview) date past his in-window race made it raise and name him; the real write passes it.
--
-- NOT DONE HERE, reported in the PR: rotating-mayor rows (Burbank, Glendale, Norwalk) whose stored
-- date is the council start, Blue Ridge's "Place N" labels on at-large seats, and the 62 unknowns.
--
-- NOT tagged '| unverified' (CA_0171): that tag would drop sitting officeholders from history.
-- OVERWRITE RECORD: every row's previous value is in the plan below and, with the research behind
-- it, in backend/data/transition-tracker/cc_0397_evidence.json.
--
-- Idempotent: each write is guarded on the value it changes.
--
-- Applied to production 2026-11-11: 100 tenures updated (84 + 6 undated, 10 re-dated), 2 race rows
-- -> false. check:incumbency then read 0 drift rows, control-reconcile-incumbency.mjs passed, and
-- check:seating held.

BEGIN;

CREATE TEMP TABLE cc0397_plan (
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

INSERT INTO cc0397_plan VALUES
 ('d78a9108-e685-42af-ac5c-1bee2a10a5bc','Rich Connelly','Fairview Council Member Seat 1','2024-05-01','month',NULL,'unknown','reelected','Town page says elected to council May 2021 (Seat One per page); stored 2024-05 is a re-election (https://fairviewtexas.org/government/mayor-town-council/)'),
 ('2b1b1b7b-f0ee-4cf3-9736-3dadddde2178','John Hubbard','Fairview Mayor','2024-05-01','month','2025-01-01','year','too_early','Town page puts his Mayor start at May 2025 (council seat since 2020 is a different seat); stored 2024-05 looks wrong (https://fairviewtexas.org/government/mayor-town-council/)'),
 ('67e8e624-ffb0-4702-8e21-aaac935368f6','John Nustad','Longview Council Member District 4','2026-05-01','month',NULL,'unknown','reelected','City District 4 page shows first election May 2023; stored 2026-05 is a re-election (our data also has inc=true) (https://longviewtexas.gov/2205/District-4---Kristen-Ishihara)'),
 ('ca0f4cd9-cd4d-4e1f-aefc-0dcf72a6ec11','Curtis Dorian','Richardson Council Member District 1','2025-05-01','month',NULL,'unknown','reelected','Won open Place 1 in May 2023 and was unopposed in 2025, so the stored 2025-05 start is a re-election (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('2b96fb76-484e-4a19-bded-05aa5f34851f','Jennifer Justice','Richardson Council Member District 2','2025-05-01','month',NULL,'unknown','reelected','Richardson Today (May 2023) lists this member as a returning member of the 2023-25 council in the same Place, so they held the seat before May 2023; true first start not found (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('fbce97a3-7ae5-4a94-9625-e7b1ebb69ab8','Dan Barrios','Richardson Council Member District 3','2025-05-01','month',NULL,'unknown','reelected','New to Place 3 in May 2023 and unopposed in 2025, so stored 2025-05 is a re-election (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('c7140df9-d39d-4256-a999-edf11e2c0cb6','Joe Corcoran','Richardson Council Member District 4','2025-05-01','month',NULL,'unknown','reelected','Richardson Today (May 2023) lists this member as a returning member of the 2023-25 council in the same Place, so they held the seat before May 2023; true first start not found (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('0b1668c3-fe12-42b2-a58e-be7d5ac1a3d2','Ken Hutchenrider','Richardson Council Member Place 5','2025-05-01','month',NULL,'unknown','reelected','Richardson Today (May 2023) lists this member as a returning member of the 2023-25 council in the same Place, so they held the seat before May 2023; true first start not found (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('244a13f5-77dd-478b-8538-e110a7ddba9d','Arefin Shamsul','Richardson Council Member Place 6','2025-05-01','month',NULL,'unknown','reelected','Richardson Today (May 2023) lists this member as a returning member of the 2023-25 council in the same Place, so they held the seat before May 2023; true first start not found (https://richardsontoday.com/may-6-election-votes-canvassed-new-mayor-council-sworn-in/)'),
 ('4c573a49-4274-4b00-986e-3a7c062b11e4','Burt Thakur','Frisco Council Member Place 2','2024-05-01','month','2025-01-01','year','too_early','New to seat in June 2025 runoff; stored 2024-05 start looks wrong (too early), term should run to May 2028 (https://communityimpact.com/dallas-fort-worth/frisco/election/2025/06/07/thakur-elad-win-respective-races-for-2-frisco-city-council-seats/)'),
 ('36b8cb6d-50ec-49b6-9fbe-31082afc033a','Angelia Pelham','Frisco Council Member Place 3','2025-05-01','month',NULL,'unknown','reelected','Took Place 3 in 2021; re-elected May 2024 (Collin May 4 2024 results show Pelham vs Redmond for Place 3) (https://communityimpact.com/dallas-fort-worth/frisco/city-county/2021/06/15/angelia-pelham-sworn-in-as-newest-frisco-city-council-member)'),
 ('38507ad3-63ac-4b95-bdc8-91bb4a086dd7','Laura Rummel','Frisco Council Member Place 5','2023-05-01','month',NULL,'unknown','reelected','Took Place 5 after March 2022 special runoff; stored 2023-05 is a re-election (https://www.friscotexas.gov/1773/Laura-Rummel)'),
 ('d62d68ed-1c71-4720-92a3-639efe279e51','Pam Sardo','Josephine Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','Candidate bio (Branch, secondary) says first elected 2021; seat number not stated on page, so Place 4 continuity unverified (https://branch.vote/races/2025-texas-contitutional-amendemnt-election-tx-state-city-council-member-tx-city-josephine-4/candidates/pamela-sardo)'),
 ('2d83ad5e-960e-470a-91fb-14997dc3985f','Elizabeth Abraham','Murphy Council Member Place 1','2024-05-01','month',NULL,'unknown','reelected','Incumbent in 2022; 2025 article says third term, consistent with first win in May 2019 (2019 Monitor results article, summarized) (https://murphymonitor.com/2022/05/12/incumbent-will-continue-to-serve/)'),
 ('8c2b4358-66dd-4e43-85e1-161300e96287','Scott Smith','Murphy Council Member Place 2','2024-05-01','month',NULL,'unknown','reelected','Won Nov 2023 special election for Berthiaume''s vacated Place 2; stored 2024-05 is too late (https://murphymonitor.com/2023/11/07/smith-bests-egwuekwe-for-murphy-council/)'),
 ('6bdfb540-86d7-4f3d-890f-5002f0f73699','Ken Oltmann','Murphy Council Member Place 4','2025-05-01','month',NULL,'unknown','reelected','Won Place 4 in May 2019 over incumbent Spraggins; continuing in 2022 and 2025 (https://murphymonitor.com/2022/05/12/incumbent-will-continue-to-serve/)'),
 ('23ddd37f-e65a-4f21-9618-956e941e4699','Jené Butler','Murphy Council Member Place 6','2025-05-01','month',NULL,'unknown','reelected','Retained Place 6 in 2022; first won May 2019 (2019 Monitor results article, summarized) (https://murphymonitor.com/2022/05/12/incumbent-will-continue-to-serve/)'),
 ('c7898178-763a-4fc9-9a43-d5f90868533f','Scott Bradley','Murphy Mayor','2023-05-01','month',NULL,'unknown','reelected','Elected mayor May 2017; stored 2023-05 is a re-election (https://murphymonitor.com/2017/05/06/city-school-district-posts-decided/)'),
 ('a4ef7077-fa2c-499e-a1fb-aa516c71c6fc','Buddy Pilgrim','Parker Council Member Place 3','2026-05-01','month',NULL,'unknown','reelected','Sitting member before the May 2026 election (re-elected); Parker seats appear at-large, start date not found (https://branch.vote/races/2026-texas-may-uniform-election-tx-state-city-council-member-tx-city-parker/candidates/buddy-pilgrim)'),
 ('2a8f6298-d35b-4fe3-93d2-1a8f53e6482e','Billy Barron','Parker Council Member Place 5','2026-05-01','month',NULL,'unknown','reelected','Appointed 2025 (his own candidate profile); stored 2026-05 is a re-election/election (https://tx3dnews.com/billy-barron-candidate-for-parker-city-council/)'),
 ('ea4f99eb-8ded-45d1-b69e-db727c4b0dee','Maria Tu','Plano Council Member Place 1','2023-05-01','month',NULL,'unknown','reelected','Incumbent in May 2023; a search snippet says first won 2019 (not fetched) (https://news.ballotpedia.org/2023/05/09/city-council-incumbents-win-re-election-in-plano-texas/)'),
 ('16de6d7b-e979-47a1-8c31-19dd02d75bae','John B. Muns','Plano Mayor','2025-05-01','month',NULL,'unknown','reelected','Wikipedia infobox lists Muns as sitting mayor before the May 2025 election; earlier start not sourced (https://en.wikipedia.org/wiki/2025_Plano_municipal_elections)'),
 ('abf511e2-33ef-41fb-99eb-118813dd71a1','Ken Cook','Allen Council Member Place 3','2024-05-01','month',NULL,'unknown','too_early','Won June 2024 runoff over incumbent Cornette and was sworn in as a new member; stored 2024-05-01 is about a month early (https://www.localprofile.com/community/city-of-allen-welcomes-new-council-members-9151352)'),
 ('a18157e1-baaf-4d68-a25c-b1cf503cb0a1','Carl Clemencich','Allen Council Member Place 5','2024-05-01','month',NULL,'unknown','too_early','Defeated incumbent Dave Shafer in the June 2024 runoff; earlier Allen ISD board and other service was not this seat (https://www.localprofile.com/community/city-of-allen-welcomes-new-council-members-9151352)'),
 ('f2ef449a-846e-4137-bf44-09c17343dd63','Ben Trahan','Allen Council Member Place 6','2025-05-01','month',NULL,'unknown','reelected','Won Place 6 in the May 7, 2022 election, so the 2025 date is a re-election (https://www.nbcdfw.com/news/elections//2958399/)'),
 ('a6b44c1f-0ce8-4c5b-bba6-0b2275c9b459','Philip Ferguson','Celina Council Member Place 1','2024-05-01','month',NULL,'unknown','reelected','Stored 2024-05-01 is wrong; he was first elected 2022 and re-elected 2025 (https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/02/17/1-contested-1-unopposed-race-in-celina-city-council-election)'),
 ('46a805c4-3dba-4c35-a6b3-eecf225537ec','Andy Hopkins','Celina Council Member Place 3','2025-05-01','month',NULL,'unknown','reelected','Incumbent in the May 2024 race, so he held Place 3 before the stored 2025-05 date; true first date not found (https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2024/02/20/filing-period-closes-for-celina-prosper-council-seat-races)'),
 ('b6b4abf9-711a-4a24-8009-cf6115e58086','Brandon Grumbles','Celina Council Member Place 6','2025-05-01','month',NULL,'unknown','reelected','Took Place 6 unopposed after Griggs resigned; year 2024 comes from search summaries (article text shows only Jan. 9); 2025 was a re-election (https://communityimpact.com/prosper-celina/government/brandon-grumbles-sworn-into-celina-city-council/)'),
 ('8e558152-ff59-4cec-942c-9deb7a661d62','Mike Shepard','Lavon Council Member Place 1','2024-05-01','month',NULL,'unknown','reelected','Present in Place 1 by Nov 21, 2023 (Kell held it Dec 2022); this is a latest-possible date, true start is between (https://lavontx.gov/wp-content/uploads/Public-Documents/City%20Council%20Minutes/2023-11-21-CC-Minutes.pdf)'),
 ('a5fc81b0-223b-4bcc-b06c-3e0cc880c562','Mike Cook','Lavon Council Member Place 2','2024-05-01','month',NULL,'unknown','reelected','Already Place 2 member in Dec 2022 (latest-possible date); 2023 oath was a re-election (https://lavontx.gov/wp-content/uploads/Public-Documents/City%20Council%20Agendas/2022-12-20-CC-Meeting-Agenda.pdf)'),
 ('7e467a97-4f38-4e4b-b257-1cd3d7acef4b','Lindsey Hedge','Lavon Council Member Place 5','2024-05-01','month',NULL,'unknown','reelected','Sworn into Place 5 Dec 2022 (listed as newly elected); possibly earlier (https://lavontx.gov/wp-content/uploads/Public-Documents/City%20Council%20Agendas/2022-12-20-CC-Meeting-Agenda.pdf)'),
 ('2727a867-01a8-4653-b10c-9cdad734509a','Vicki Sanson','Lavon Mayor','2024-05-01','month',NULL,'unknown','reelected','Already mayor Dec 2022 (latest-possible date), before stored 2024-05-01; Nov 2023 oath was a re-election (https://lavontx.gov/wp-content/uploads/Public-Documents/City%20Council%20Agendas/2022-12-20-CC-Meeting-Agenda.pdf)'),
 ('1133ac28-a892-487c-b68b-58b7c57ddfb4','Justin Beller','McKinney Council Member District 1','2025-05-01','month',NULL,'unknown','reelected','First took District 1 in May 2021; 2025 was a re-election (https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus)'),
 ('58d67221-1061-4a70-b1dd-fbb18110a146','Geré Feltus','McKinney Council Member District 3','2025-05-01','month',NULL,'unknown','reelected','Elected 2021, re-elected 2025 (https://communityimpact.com/mckinney/election/gere-feltus-wins-re-election-to-mckinney-city-council/)'),
 ('d3ef6f15-cde4-409a-ac3c-335fea1e42c3','Rick Franklin','McKinney Council Member District 4','2023-05-01','month',NULL,'unknown','reelected','Won District 4 in May 2019; 2023 was re-election (unopposed per search summary, not fetched) (https://www.nbcdfw.com/news/local/mckinney-props-isd-trustee-city-council-election-results/139181/?amp=1)'),
 ('1d269377-e33b-4a95-badc-77914d2390f3','Marcus E. Ray','Prosper Council Member Place 1','2025-05-01','month',NULL,'unknown','reelected','Re-elected unopposed 2025 and on council by May 16, 2023 (latest-possible date); town directory reportedly says elected 2019 but that page was unreachable (https://mccmeetingspublic.blob.core.usgovcloudapi.net/prospertx-meet-76f313c690404cf98222ea6aaa920045/ITEM-Attachment-001-8a639b5e537c4e25a862261db5489e85.pdf)'),
 ('0df9db63-bd50-4434-8c99-951a3f88e221','Craig Andres','Prosper Council Member Place 2','2024-05-01','month',NULL,'unknown','reelected','Incumbent Place 2 in 2024 and on council May 2023 (latest-possible date); directory reportedly says 2018 but was unreachable (https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2024/02/20/filing-period-closes-for-celina-prosper-council-seat-races)'),
 ('2215f0f6-e7d5-4936-bddd-046be289c8f3','Amy Bartley','Prosper Council Member Place 3','2023-05-01','month',NULL,'unknown','reelected','Incumbent Place 3 in May 2023, so stored 2023-05-01 is a re-election; directory reportedly says elected Nov 2020, not verified (https://mccmeetingspublic.blob.core.usgovcloudapi.net/prospertx-meet-702892e3477b46aca8d8c463b52b177d/ITEM-Attachment-001-9bd5451f9d36401d819cb5c3d8545b97.pdf)'),
 ('7c3cefcf-aafc-482c-8f59-4d21674f8c84','Chris Kern','Prosper Council Member Place 4','2025-05-01','month',NULL,'unknown','reelected','Re-elected unopposed 2025 and on council May 2023 (latest-possible date) (https://mccmeetingspublic.blob.core.usgovcloudapi.net/prospertx-meet-76f313c690404cf98222ea6aaa920045/ITEM-Attachment-001-8a639b5e537c4e25a862261db5489e85.pdf)'),
 ('9d5e6510-a070-44b9-a9c6-265fc18e6d6c','David F. Bristol','Prosper Mayor','2025-05-01','month',NULL,'unknown','reelected','Mayor in May 2023 (latest-possible date) and re-elected unopposed 2025 (https://mccmeetingspublic.blob.core.usgovcloudapi.net/prospertx-meet-76f313c690404cf98222ea6aaa920045/ITEM-Attachment-001-8a639b5e537c4e25a862261db5489e85.pdf)'),
 ('a3c76bd2-f8bc-4436-8d9c-076c0398bc2f','Ryan Neal','Van Alstyne Council Member Place 1','2024-05-05','day',NULL,'unknown','reelected','Incumbent Place 1 at the May 7, 2022 election (latest-possible date; article undated, matched to Grayson 2022 results) (https://graarticles.optin.com/newsletter/awlist5581551/MTQzMTUxNDM=/van-alstyne-voters-overwhelmingly-approve-city-charter.htm)'),
 ('2b342a08-b4b0-46c7-9092-c74fb9712ec7','Marla Butler','Van Alstyne Council Member Place 2','2024-05-05','day',NULL,'unknown','reelected','Incumbent Place 2 in May 2022 (latest-possible date) (https://graarticles.optin.com/newsletter/awlist5581551/MTQzMTUxNDM=/van-alstyne-voters-overwhelmingly-approve-city-charter.htm)'),
 ('472b0a63-6881-4ffd-8c03-d30170fd23c8','Dusty Williams','Van Alstyne Council Member Place 3','2024-05-05','day',NULL,'unknown','reelected','Won Place 3 in May 2022; 2024 was a re-election (https://graarticles.optin.com/newsletter/awlist5581551/MTQzMTUxNDM=/van-alstyne-voters-overwhelmingly-approve-city-charter.htm)'),
 ('18d857bf-824a-46b3-821b-ccffb6b58724','Burhan Azeem','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','Incumbent first elected 2021, took office Jan 2022 (month inferred from Cambridge''s January terms) (https://en.wikipedia.org/wiki/Burhan_Azeem)'),
 ('6e456a29-f348-4d54-bb74-14de8dc605c3','Catherine Zusy','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','Elected Sept 19, 2024 to fill the vacancy left by Joan Pickett''s death; sworn in the following Monday (Sept 23, 2024, inferred); re-elected 2025 (https://www.cambridgeday.com/2024/09/19/zusy-is-elected-to-cambridges-city-council-filling-surprise-vacancy-for-a-monday-start/)'),
 ('1f10807d-77af-4974-b1b2-990170ea38f7','E. Denise Simmons','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','Wikipedia says continuously on the council since 2002 (elected 2001); no break found (https://en.wikipedia.org/wiki/E._Denise_Simmons)'),
 ('2b3a4ab3-4e5b-408b-a645-b5322f2c19e9','Jivan Sobrinho-Wheeler','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','First served about Jan 2020-2021, then a gap; re-elected 2023 so continuous stint starts Jan 2024 (inferred); the 2026 date is a later re-election (https://www.cambridgeday.com/2023/11/08/sobrinho-wheeler-wilson-and-pickett-elected-onto-council-hudson-and-harding-for-schools/)'),
 ('a9b3ee8a-7e30-414f-a24e-aed547e7e18c','Marc C. McGovern','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','Elected to council in 2013; I did not check for a break in service since 2014 (https://en.wikipedia.org/wiki/Marc_McGovern)'),
 ('dd1798d0-5c02-4a4b-babe-531c4727b94e','Patricia M. Nolan','Cambridge City Councillor','2026-01-05','day',NULL,'unknown','reelected','Elected as a challenger in Nov 2019 (term from Jan 2020; a search summary of Ballotpedia gave Jan 6, 2020, which I did not fetch); re-elected since (https://www.cambridgeday.com/2019/11/05/nolan-jivan-sobrinho-wheeler-join-council-committee-sees-wilson-villarreal-weinstein/)'),
 ('2f7edff3-3c1f-4b1f-b853-0dadfeded2ad','David Weinstein','Cambridge School Committee Member','2026-01-05','day',NULL,'unknown','reelected','Three terms by 2025 implies first elected 2019 (start Jan 2020, inferred); lost on election night 2025 then won after corrected count, no gap (https://www.cambridgeday.com/2026/01/05/new-school-committee-elects-weinstein-chair/)'),
 ('2156ba67-71ef-4b25-86e9-4a6eec73cea1','Richard Harding, Jr.','Cambridge School Committee Member','2026-01-05','day',NULL,'unknown','reelected','Long history, absent 2018-2023, back for Jan 2024 (inferred; 2023 final result conflicting in sources); incumbent in 2025, so continuous stint starts 2024-01 at the latest, low confidence (https://www.cambridgeday.com/2026/01/05/new-school-committee-elects-weinstein-chair/)'),
 ('650eb755-fc0d-4401-9532-a0855df528b3','Elizabeth Hudson','Cambridge School Committee Member','2026-01-05','day',NULL,'unknown','reelected','First elected Nov 2023 (start Jan 2024, inferred); 2025 article calls 2025 her second term (https://www.cambridgeday.com/2023/11/08/sobrinho-wheeler-wilson-and-pickett-elected-onto-council-hudson-and-harding-for-schools/)'),
 ('40149015-398e-4aef-bc05-5f39530868c6','Coleman Strickland','Farmersville Council Member Place 1','2026-05-01','month',NULL,'unknown','reelected','Re-elected unopposed in 2026 for a second term in Place 1, so the 2026-05 start is only a later term; 2023 is inferred from ''second term'' and a 3-year term cycle, not directly sourced (https://farmersvilletimes.com/?p=19771)'),
 ('626369de-e3db-412a-8a4b-1185775f07fd','Russell Chandler','Farmersville Council Member Place 2','2024-05-01','month','2024-10-01','month','too_early','Appointed to Place 2 in Oct 2024 (then ran unopposed 2025), so the stored 2024-05 is too early; he was not holding the seat in May 2024 (https://farmersvilletimes.com/?p=18449)'),
 ('b8e7f971-5c31-4ace-9ed1-0bac1c5f69fb','Kristi Mondy','Farmersville Council Member Place 3','2026-05-01','month',NULL,'unknown','reelected','Appointed to Place 3 in June 2025 (article dated Feb 2026), so 2026-05 is the start of her first full term, not first service in the seat (https://farmersvilletimes.com/?p=19771)'),
 ('be4677bf-374a-4204-b744-6ce5e32e1ee5','Mike Henry','Farmersville Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','Held Place 4 before the May 2022 election (second term then); exact first start not sourced (a 2020 Farmersville Times filing story names a ''Gary Henry'' for Place 4, unconfirmed) (https://farmersvilletimes.com/?p=14447)'),
 ('bdbc839d-9be9-46fc-97d8-f9fc205f9626','Tonya Fox','Farmersville Council Member Place 5','2024-05-01','month','2025-01-01','year','too_early','Place 5 was held by Lance Hudson in May 2024 and he resigned Jan 2025 per Farmersville Times search snippets, so Fox took the seat in 2025; stored 2024-05 is too early (exact date not found) (https://farmersvilletimes.com/?p=18449)'),
 ('4ff8fbad-dae7-4667-8809-fbc932f03b4b','Scott Pitchure','Lowry Crossing Council Member Place 1','2024-05-01','month',NULL,'unknown','reelected','Sworn in for Ward 1 on 2023-11-14 (not on the roll before oath), so 2024-05 is not his first start; Lowry Crossing uses wards with two seats each, so Place 1 vs Place 5 within Ward 1 is inferred (https://webgen1files1.revize.com/lowrycrossingtx/Document%20Center/Operations/Meeting%20Minutes/City%20Of%20Council/2024/CC%20Minutes%2011%2014%2023.pdf)'),
 ('9642ecc3-6499-4fc3-930a-c6519ed853c0','Tammy Hodges','Lowry Crossing Council Member Place 2','2024-05-01','month','2024-11-12','day','too_early','Newly elected Ward 2 member sworn 2024-11-12; stored 2024-05 is too early (she is not in the May 2024 roll) (https://webgen1files1.revize.com/lowrycrossingtx/CC%20Minutes%2011%2012%2024.pdf)'),
 ('50f9b8be-52b9-4615-93b7-c00b9e4b0a5d','Eusebio "Joe" Trujillo III','Lowry Crossing Council Member Place 3','2024-05-01','month',NULL,'unknown','reelected','On council by Nov 2023 and re-elected Nov 2024 (Ward 3); earliest start not sourced, 2023-11-14 is only the first roll appearance found (https://webgen1files1.revize.com/lowrycrossingtx/Document%20Center/Operations/Meeting%20Minutes/City%20Of%20Council/2024/CC%20Minutes%2011%2014%2023.pdf)'),
 ('2794505c-ca84-490f-aa80-03d394fcfe78','Chris Madrid','Lowry Crossing Council Member Place 5','2024-05-01','month',NULL,'unknown','reelected','On council before Nov 2023; earliest start not sourced (2023-11-14 is the first roll found); re-elected Nov 2024 and Nov 2025 (https://webgen1files1.revize.com/lowrycrossingtx/Document%20Center/Operations/Meeting%20Minutes/City%20Of%20Council/2024/CC%20Minutes%2011%2014%2023.pdf)'),
 ('c19befb2-1589-43e4-b353-c22f86f12f34','Agur Rios','Lowry Crossing Council Member Place 6','2024-05-01','month','2025-11-11','day','too_early','First appears when sworn in on 2025-11-11 as newly elected Ward 2; stored 2024-05 is too early (https://webgen1files1.revize.com/lowrycrossingtx/CC%20Minutes%2011%2011%2025.pdf)'),
 ('dea21e55-bcd2-4a31-8a7d-449d7213e933','Cindy Cash','Lowry Crossing Council Member Place 7','2024-05-01','month',NULL,'unknown','reelected','Already on the roll before being sworn for Ward 3 in Nov 2023 (so re-elected then); earliest start not sourced (https://webgen1files1.revize.com/lowrycrossingtx/Document%20Center/Operations/Meeting%20Minutes/City%20Of%20Council/2024/CC%20Minutes%2011%2014%2023.pdf)'),
 ('9a45ca9b-01ef-4b97-acc0-f7e8e5cb6b09','Ollie Simpson','Lowry Crossing Council Member Place 8','2026-05-01','month',NULL,'unknown','reelected','Listed as elected Ward 4 in Nov 2025 but absent for the oath and first seen attending June 2026; low confidence because the May 2026 ballot also had Ward 4 seats (https://webgen1files1.revize.com/lowrycrossingtx/CC%20Minutes%2011%2011%2025.pdf)'),
 ('dc9e908f-db10-45e1-9d58-1c9dd4b9bbdc','Pat Kelly','Lowry Crossing Mayor','2024-05-01','month','2025-11-11','day','too_early','Mayor was Bob Petitt through mid-2025; Kelly sworn in as newly elected Mayor 2025-11-11 (earlier he was a council member, a different seat); stored 2024-05 is too early (https://webgen1files1.revize.com/lowrycrossingtx/CC%20Minutes%2011%2011%2025.pdf)'),
 ('fecf9980-c018-4bc8-8a8b-a7e81e13071f','Mike Laye','Nevada Council Member Place 1','2026-05-01','month',NULL,'unknown','reelected','Listed as Place 1 in May 2023 minutes (earliest start not sourced); the 2026 cancelled election only re-seated him (https://cms3.revize.com/revize/nevadatx/Documents/Government/Agendas%20and%20Minutes/2023/Minutes/050223-Minutes.pdf)'),
 ('f8e0b730-72f0-4ea5-82af-397a3da7fbdb','Paul Baker','Nevada Council Member Place 2','2026-05-01','month',NULL,'unknown','reelected','Place 2 was vacant on 2025-05-06 and Baker held it by Sept 2025 (exact date not found), so the 2026-05 start is a later term (https://cms3.revize.com/revize/nevadatx/Documents/Government/Agendas%20and%20Minutes/2025/Minutes/City%20Coouncil%20Meeting%20Minutes%205.6.25%20-%20Approved.pdf)'),
 ('b6f17064-858c-4214-b1f5-41e46c4d4141','Amanda Wilson','Nevada Council Member Place 3','2024-05-01','month','2025-01-01','year','too_early','Longoria held Place 3 in May 2024; Wilson sworn in as newly elected on 2025-05-06 (unopposed); stored 2024-05 is too early (https://cms3.revize.com/revize/nevadatx/Documents/Government/Agendas%20and%20Minutes/2024/Minutes/05%2007%2024%20Council%20Regular%20Minutes.pdf)'),
 ('723d227d-fc84-4124-8c46-87aff3ade4c1','Clayton Laughter','Nevada Council Member Place 4','2024-05-01','month',NULL,'unknown','reelected','Place 4 was Karl Fisher on 2023-05-02 and Laughter by June 2023 (OCR of 2023-05-16 minutes shows newly elected members sworn in); stored 2024-05 is too late. Minutes are scanned images read by OCR (https://cms3.revize.com/revize/nevadatx/Documents/Government/Agendas%20and%20Minutes/2023/Minutes/062023-Minutes.pdf)'),
 ('321dabae-36e0-4083-80e9-aec6a55b8c6a','Derrick Little','Nevada Council Member Place 5','2024-05-01','month','2025-01-01','year','too_early','Hudson held Place 5 in May 2024; Little sworn in 2025-05-06; stored 2024-05 is too early. Minutes are scanned images read by OCR (https://cms3.revize.com/revize/nevadatx/Documents/Government/Agendas%20and%20Minutes/2024/Minutes/05%2007%2024%20Council%20Regular%20Minutes.pdf)'),
 ('5c8ff32b-9966-4311-be27-27ae931d58dd','Donald Deering','Nevada Mayor','2026-05-01','month',NULL,'unknown','reelected','Declared elected Mayor in the cancelled May 3, 2025 special election and sworn in 2025-05-06 (earlier he was Place 2, a different seat); stored 2026-05 is a later term. Scanned images read by OCR (https://cms3.revize.com/revize/nevadatx/Documents/Government/Election/2025%20General%20&%20Special%20Election/2025.03.04%20ORDINANCE%20NO.%20O030425B%20-%20CANCELATION%20OF%20MAY%203,%202025%20SPECIAL%20ELECTION.pdf)'),
 ('effbbf62-1a61-4ccf-8868-0b9db3a1c476','Terrance Johnson','Princeton Council Member Place 1','2024-05-01','month',NULL,'unknown','too_early','Beat incumbent Kleiber in Nov 2024; stored 2024-05 is too early (https://www.ketr.org/2024-11-08/princeton-city-council-member-who-joked-about-shooting-liberals-loses-reelection)'),
 ('21ec272b-b5c3-4f7c-aea7-6e5ff6b7c851','Cristina Todd','Princeton Council Member Place 2','2024-05-01','month',NULL,'unknown','too_early','Won Place 2 in Nov 2024 over Obera; stored 2024-05 is too early (https://princetonherald.com/?p=20512)'),
 ('8bbb39a8-b049-4031-9ac2-7d22cc3d0ce2','Bryan Washington','Princeton Council Member Place 3','2024-05-01','month',NULL,'unknown','reelected','Won Place 3 in the Nov 3, 2020 election and was re-elected Nov 2023 (https://princetonherald.com/2023/11/07/council-incumbents-re-elected-new-seats-go-to-long-david-graves/)'),
 ('34971999-2847-47d6-9434-63ea5f26a581','Steven Deffibaugh','Princeton Council Member Place 5','2024-05-01','month',NULL,'unknown','reelected','Herald says he has held Place 5 since 2010 (quote is the fragment returned by the fetch tool); unopposed re-election Nov 2023 (https://princetonherald.com/2023/10/12/place-5-city-council-candidate-steven-deffibaugh/)'),
 ('370d1d52-a3fa-4e9f-bc49-3768767a0416','Ben Long','Princeton Council Member Place 6','2024-05-01','month',NULL,'unknown','reelected','Won newly created Place 6 on Nov 7, 2023, so the stored 2024-05 is too late (https://princetonherald.com/2023/11/07/council-incumbents-re-elected-new-seats-go-to-long-david-graves/)'),
 ('1961f187-5ed1-4da4-9381-a32971ec9695','Carolyn David-Graves','Princeton Council Member Place 7','2024-05-01','month',NULL,'unknown','reelected','Won newly created Place 7 on Nov 7, 2023, so the stored 2024-05 is too late (https://princetonherald.com/2023/11/07/council-incumbents-re-elected-new-seats-go-to-long-david-graves/)'),
 ('74db750b-1a9c-486a-9046-568034afe447','Eugene Escobar Jr.','Princeton Mayor','2024-05-01','month',NULL,'unknown','too_early','Beat the sitting mayor in the Dec 14, 2024 runoff; stored 2024-05 is too early (https://www.ketr.org/2024-12-18/princeton-voters-elect-mayoral-candidate-who-raised-concerns-about-rapid-growth-oust-incumbent)'),
 ('2372a3ff-25d8-495c-adc4-f9fc7fcd2f10','Larry Nail','Saint Paul Council Member Place 1','2024-05-01','month','2024-07-08','day','too_early','Appointed to Seat 1 on 2024-07-08 (he is not on the May 2024 roll); stored 2024-05 is too early. Scanned minutes read by OCR (https://cms8.revize.com/revize/stpaultx/7.8.2024_Minutes_Regular%20Council%20Meeting.pdf)'),
 ('f3ad11c2-a26c-41e8-acb6-7288115ded44','David Dryden','Saint Paul Council Member Place 2','2024-05-01','month',NULL,'unknown','reelected','On council by Jan 2024 (seat number not stated then); re-sworn for Place 2 on 2025-05-12; earliest start not sourced. Scanned minutes read by OCR (https://cms8.revize.com/revize/stpaultx/Document%20Center/1%20-%20TSP%20AGENDAS/24.01.08%20CNL%20MIN%20REG%20MEETING.pdf)'),
 ('050fdcd7-8245-452a-ae27-5872d1409a41','Claudia M. Frometa','Downey Council Member (District 4)','2022-12-06','day',NULL,'unknown','reelected','Newly elected Nov 2018 (District 4); 2022 was her second term (https://www.thedowneypatriot.com/articles/claudia-frometa-giggy-saab-win-downey-elections)'),
 ('ad77e23f-5e70-4660-8a2a-1bd249c3537a','Dorothy Pemberton','Downey Councilmember','2023-11-13','day','2023-12-01','month','too_early','Won special election; oath Tue Dec 12, 2023 (article dated Dec 13, 2023); stored 2023-11-13 is a month early, no earlier service found (https://www.thedowneypatriot.com/articles/pemberton-ortiz-take-oaths-of-office)'),
 ('1b6a17aa-a2c2-4621-8654-2ded3581bde1','Alex Padilla','Inglewood Council Member (District 2)','2022-12-18','day',NULL,'unknown','reelected','Inglewood D2 Padilla (not the senator) won the 2013 runoff over incumbent; took seat mid-2013 (search results say sworn July 16, 2013) (https://www.ourweekly.com/2013/06/13/incumbents-out-inglewood-elections/)'),
 ('be5ed03e-743e-411f-84ba-e2c243d21bcc','Eloy Morales','Inglewood Council Member (District 3)','2022-12-18','day',NULL,'unknown','reelected','Article dated Nov 20, 2020 shows he already held D3; true first start likely earlier (search result says first elected 2003, unverified) (https://wavepublication.com/?p=3545)'),
 ('6efc30a8-2c11-4872-92f6-1b320e9e1d4c','Dionne Faulk','Inglewood Council Member (District 4)','2022-12-18','day',NULL,'unknown','reelected','Elected Nov 2020 to District 4 (article dated Nov 20, 2020); took office about Dec 2020 (https://wavepublication.com/?p=3545)'),
 ('0a10a1b0-bdea-4f0b-b976-22cbff8bf33c','Bob Blumenfield','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 3 since 2013 per Wikipedia table; stored title has no district, matched by name (https://en.wikipedia.org/wiki/Los_Angeles_City_Council)'),
 ('5ab5e444-98cb-4691-9f29-e1767fd8f2cf','Heather Hutt','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 10 appointee since Sep 2022; brief lapse Mar 30-Apr 11 2023; elected 2024. Stored 2022-12-12 is wrong (https://en.wikipedia.org/wiki/Heather_Hutt)'),
 ('5d31666b-a588-4273-99dc-871463fa1a60','Marqueece Harris-Dawson','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 8 since 2015 per Wikipedia table (https://en.wikipedia.org/wiki/Los_Angeles_City_Council)'),
 ('0c296749-a2ca-4391-b983-93b183355905','John Lee','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 12 since 2019 per table (https://en.wikipedia.org/wiki/Los_Angeles_City_Council)'),
 ('354782e9-c95b-4254-9c48-c089fc06e6a8','Monica Rodriguez','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 7 since 2017 per table (https://en.wikipedia.org/wiki/Los_Angeles_City_Council)'),
 ('4a431c0e-8f2b-4272-a7cb-8811d43818f6','Nithya Raman','Los Angeles Council Member','2022-12-12','day',NULL,'unknown','reelected','District 4 since Dec 2020 per table; stored 2022-12-12 is wrong (https://en.wikipedia.org/wiki/Los_Angeles_City_Council)'),
 ('2da49509-d404-4842-8c42-1de092174e04','Doug Chaffee','Orange County Supervisor','2023-01-03','day',NULL,'unknown','reelected','Fourth District since Jan 2019; stored 2023-01-03 is a later term (https://en.wikipedia.org/wiki/Orange_County_Board_of_Supervisors)'),
 ('520c7222-27c5-40e2-9faf-8d442a313901','Richard J. Loa','Palmdale Council Member (District 2)','2022-12-09','day',NULL,'unknown','reelected','Seated in District 2 in Dec 2018 (also served 2001-2005 earlier, with a break) (https://www.avta.com/richard-loa.php)'),
 ('035e391d-86fa-4249-aaaf-a262c672ac6a','Justin Jones','Pasadena Councilmember','2022-12-12','day',NULL,'unknown','reelected','District 3 appointee since Sep 2022 (re-appointed Dec 2022); stored 2022-12-12 is not the first start (https://pasadenanow.com/main/after-two-appointments-special-election-jones-gets-first-four-year-term)'),
 ('6ad392ab-8fc8-410d-9626-cc5eee25b652','Steve Madison','Pasadena Councilmember','2022-12-12','day',NULL,'unknown','reelected','Re-elected in 2020, so stored 2022 is a later term; true first start not found (search says he was on council by 2015) (https://www.pasadenanow.com/main/?p=489969)'),
 ('bfe0c323-e4fc-401e-aa8d-2ce6e64a462b','Gene Masuda','Pasadena Councilmember','2022-12-12','day',NULL,'unknown','reelected','Re-elected in 2020, so stored 2022 is a later term; true first start not found (https://www.pasadenanow.com/main/?p=489969)'),
 ('31629cab-8566-4857-8f4e-5282d2a23f10','Laurene Weste','Santa Clarita Council Member (At-Large)','2022-12-13','day',NULL,'unknown','reelected','At-large seat; on council since 1998 (https://signalscv.com/2021/12/city-council-votes-unanimously-laurene-weste-named-mayor)'),
 ('9cbea3f3-e455-4062-929a-79d83079e05a','Jason Gibbs','Santa Clarita Council Member (District 3)','2024-12-10','day',NULL,'unknown','reelected','AMBIGUOUS: appointed first-ever District 3 rep Aug 2024; sworn Dec 10, 2024. Was on council earlier at-large (different seat) (https://signalscv.com/2024/08/council-names-gibbs-to-district-3-seat)'),
 ('eb24398d-9661-4303-a89a-7de29d17eb63','Letty Lopez-Viado','West Covina Council Member (District 2)','2022-12-20','day',NULL,'unknown','reelected','New member Dec 2018; 2022 was re-election (https://sac.media/2018/12/05/west-covina-celebrates-outgoing-welcomes-new)'),
 ('35296c7a-6930-4f92-8b88-58716be16b16','Tony Wu','West Covina Council Member (District 5)','2022-12-20','day',NULL,'unknown','reelected','On council since at least 2015 (at-large then); reelected Dec 2018 and 2022 as District 5 (https://sac.media/2018/12/05/west-covina-celebrates-outgoing-welcomes-new)');

CREATE TEMP TABLE cc0397_race (
  race_candidate_id uuid PRIMARY KEY,
  term_id           uuid NOT NULL,
  who               text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0397_race VALUES
 ('0c59532f-ae5b-4ef7-bf0a-0f5269095973','dc9e908f-db10-45e1-9d58-1c9dd4b9bbdc','Pat Kelly'),
 ('0aec1f87-4b53-48cc-ab2d-4f263a4aed9b','c19befb2-1589-43e4-b353-c22f86f12f34','Agur Rios');

-- ---------------------------------------------------------------------------------------------
-- Pre-gate.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int;
BEGIN
  IF (SELECT count(*) FROM cc0397_plan) <> 100 THEN
    RAISE EXCEPTION 'CC_0397 pre-gate: plan holds % rows, expected 100', (SELECT count(*) FROM cc0397_plan);
  END IF;

  -- Each row is an open tenure CC_0394 dated, held by the named person, still at the measured value
  -- (or already at the target, on a re-run).
  SELECT count(*) INTO v_bad
    FROM cc0397_plan pl
    LEFT JOIN essentials.office_terms ot ON ot.id = pl.term_id AND ot.term_end IS NULL
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.id IS NULL
      OR p.full_name IS DISTINCT FROM pl.who
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR NOT ( (ot.term_start = pl.was_start AND ot.start_precision = pl.was_prec)
            OR (ot.term_start IS NOT DISTINCT FROM pl.new_start AND ot.start_precision = pl.new_prec) );
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 pre-gate: % plan row(s) do not match the tenure they name', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0397_plan
   WHERE (new_start IS NULL) <> (new_prec = 'unknown')
      OR (kind = 'reelected' AND new_start IS NOT NULL)
      OR (new_start IS NOT NULL AND new_start <= was_start)
      OR (new_prec = 'year'  AND to_char(new_start, 'MM-DD') <> '01-01')
      OR (new_prec = 'month' AND extract(day FROM new_start) <> 1);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 pre-gate: % plan row(s) are internally inconsistent', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0397_race r
    LEFT JOIN essentials.office_terms ot ON ot.id = r.term_id
    LEFT JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
                                           AND rc.politician_id = ot.politician_id
   WHERE rc.id IS NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 pre-gate: % race row(s) do not belong to the planned tenure', v_bad;
  END IF;
END $$;

-- Every person whose office_terms row this writes. No seating happens here and no predecessor term
-- is closed, so the plan's own holders are BOTH sides of every write.
CREATE TEMP TABLE cc0397_people ON COMMIT DROP AS
SELECT DISTINCT ot.politician_id
  FROM cc0397_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — moves or NULLs term_start on 100 CC_0394-dated open tenures (no seating, no predecessor closed) and flips 2 Lowry Crossing race rows

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0397_people);

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
       source          = ot.source || ' | CC_0397: '
                         || CASE WHEN pl.new_start IS NULL
                                 THEN 'term start RETURNED TO UNDATED, because the CC_0394 date was the start of a later term or is not sourced. '
                                 ELSE 'term start moved to ' || to_char(pl.new_start, 'YYYY-MM-DD')
                                      || ' (' || pl.new_prec || ' precision); the CC_0394 date was before this person took the seat. ' END
                         || pl.citation || '.'
  FROM cc0397_plan pl
 WHERE ot.id = pl.term_id
   AND (ot.term_start IS DISTINCT FROM pl.new_start OR ot.start_precision IS DISTINCT FROM pl.new_prec);

UPDATE essentials.race_candidates rc
   SET is_incumbent = false
  FROM cc0397_race r
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
  SELECT count(*) INTO v_planned FROM cc0397_people;
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
    FROM cc0397_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE ot.term_start IS DISTINCT FROM pl.new_start
      OR ot.start_precision IS DISTINCT FROM pl.new_prec
      OR ot.source NOT LIKE '%CC_0394: term_start%'
      OR ot.source NOT LIKE '%CC_0397:%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 gate: % tenure(s) do not carry the planned value with provenance intact', v_bad;
  END IF;

  -- Nobody is unseated: every planned holder still resolves as the current holder.
  SELECT count(*) INTO v_bad
    FROM cc0397_plan pl JOIN essentials.office_terms ot ON ot.id = pl.term_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = ot.office_id AND och.politician_id = ot.politician_id);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 gate: % officeholder(s) no longer resolve as current', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM cc0397_race r JOIN essentials.race_candidates rc ON rc.id = r.race_candidate_id
   WHERE rc.is_incumbent IS DISTINCT FROM false;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0397 gate: % race row(s) still marked incumbent', v_bad;
  END IF;
END $$;

COMMIT;
