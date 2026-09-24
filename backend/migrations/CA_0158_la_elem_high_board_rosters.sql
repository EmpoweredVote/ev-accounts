-- CA_0158_la_elem_high_board_rosters.sql
-- Replace the STALE sitting members of 31 LA-County ELEMENTARY and HIGH-SCHOOL district boards with the
-- verified current boards, in essentials.office_terms (the only occupancy source; ADR 0002). Same method
-- and operator decisions as the unified-board refresh (CA_0143-CA_0154); CA_0159 audits the people.
--
--   Antelope Valley JUHSD 0602820   Castaic USD 0607740        Centinela Valley UHSD 0607920
--   East Whittier City 0611850      Eastside Union 0611910      El Monte City 0612090
--   El Monte UHSD 0612120           Garvey 0614940              Gorman Joint 0615600
--   Hawthorne 0616680               Hermosa Beach City 0617040  Hughes-Elizabeth Lakes 0617880
--   Keppel Union 0619440            Lancaster 0620880           Lawndale 0621210
--   Lennox 0621420                  Little Lake City 0621930    Los Nietos 0622890
--   Mountain View 0626190           Newhall 0627180             Palmdale 0629580
--   Rosemead 0633570                Saugus Union 0635970        South Whittier 0637560
--   Sulphur Springs Union 0638220   Valle Lindo 0640650         Westside Union 0642120
--   Whittier City 0642450           Whittier UHSD 0642480       William S. Hart UHSD 0642510
--   Wilsona 0642810
--
-- No migration runner exists; this file records SQL applied by hand via
--   npx tsx scripts/_apply-file.ts <abs path>/backend/migrations/CA_0158_la_elem_high_board_rosters.sql
-- (pure DML -> DATABASE_URL is fine).
--
-- ---------------------------------------------------------------------------------------------------
-- A. THE DEFECT
-- ---------------------------------------------------------------------------------------------------
-- Each district holds generic 'Board Member' offices on ONE whole-district SCHOOL row (its geofence is
-- the TIGER elementary G5400 or secondary G5410 polygon; the district row itself says G5420). All 143
-- offices carry a migration-1459 backfill term (term_start/term_end NULL, precision 'unknown') for a
-- politician with data_source 'https://empowered.vote/school-district/<name>' (source 'scraped',
-- external_id -201856..-202369) -- the same unsourced generator as the 238 unified-board rows (CA_0156).
-- All 143 read is_incumbent = true, so every one displays as a CURRENT trustee. Checked against LA County
-- RR/CC: of the 143 names only 5 appear on any candidate list 2017-2026 (lavote.gov/Apps/CandidateList)
-- or in any contest 2013-2026 (results.lavote.gov, all 73 elections), and only 4 of those ever served.
-- Eight boards are also short of seats (Gorman's 3-seat board is the only one the DB sizes right).
--
-- ---------------------------------------------------------------------------------------------------
-- B. HOW THE STALE TERMS ARE ENDED -- operator decision (Chris Andrews, 2026-09-22), as CA_0143 §B
-- ---------------------------------------------------------------------------------------------------
--   * The current member is seated with essentials.seat_officeholder (two-step: the stale open term is
--     closed the day before the member's term_start). That term_end is a MODELLING CONSEQUENCE, not a
--     researched last day: the seats are generic, so which stale holder is paired with which member is
--     arbitrary. The source note on every closed row says so.
--   * how_ended 'unknown'; politicians.is_incumbent = false; is_active is left to CA_0159.
--   * EXCEPTION -- Jeff Baird (Whittier UHSD, 84c5018c) is a REAL former trustee (Dec 1997 - Dec 2022;
--     Whittier Daily News 2022-08-21; RR/CC 3752 lists him as elected incumbent in Nov 2017). He is paired
--     with a 2022 successor (Irma Rodriguez Moisa), so his term_end is month-accurate, how_ended
--     'term_expired' (CA_0145 §B / CA_0147 §B precedent).
--
-- ---------------------------------------------------------------------------------------------------
-- C. THREE STALE HOLDERS ARE REAL AND STILL SEATED -- kept, terms untouched (1546 precedent)
-- ---------------------------------------------------------------------------------------------------
--   William S. Hart UHSD, hartdistrict.org board page, each "current term 2022 - 2026":
--     d304c0d7 Bob Jensen     TA2  RR/CC won 2018 (8,874 v 8,292) and 2022 (11,639 v 5,736); not on the
--                                  Nov 2026 ballot, so he leaves in December 2026
--     41076964 Cherise Moore  TA3  RR/CC 2018 appointed incumbent [A]; won 2022 (7,355 v 4,412)
--     4cee37b3 Joe Messina    TA5  RR/CC won 2018 and 2022; on the Nov 2026 ballot
--   Only their stored party is cleared here.
--
-- ---------------------------------------------------------------------------------------------------
-- D. MISSING SEATS -- operator decision (2026-09-22): add seats to match the board
-- ---------------------------------------------------------------------------------------------------
-- 10 offices are added, each a copy of an existing seat of the same district (same chamber, district,
-- title and flags): Hughes-Elizabeth Lakes +3 (DB had 2 of 5), Wilsona +2 (3 of 5), and +1 each for
-- Centinela Valley, Eastside, Rosemead, Saugus and Hart (4 of 5). Gorman Joint has 3 trustees (district
-- page; RR/CC 2020 lists one 3-seat contest) and keeps its 3 seats. No race references any of these
-- offices (asserted below).
--
-- ---------------------------------------------------------------------------------------------------
-- E. THE CURRENT BOARDS -- each district's own board page, read 2026-09-22 (URLs in _ca0158_district)
-- ---------------------------------------------------------------------------------------------------
-- Every elected member's CURRENT term is the cycle last won per the RR/CC candidate lists (Nov 2022 =
-- 4300, Nov 2024 = 4324) and results (results.lavote.gov text results 4300 / 4324, read in a browser
-- because of Incapsula). A seat with one filer, or an at-large cycle with no more filers than seats, was
-- UNCONTESTED: appointed in lieu of election (Elections Code §10515, treated as elected). Some RR/CC list
-- names only took out papers (issued date, no filed date): Julia Ruedas (El Monte City 2022), Carlos
-- Salcedo (El Monte UHSD TA1 2024), John Quintanilla (El Monte UHSD TA3 2022), Ronald Trabanino (Garvey
-- TA3 2022), Richard Hughes (East Whittier TA2 2024), Donita Winn (AVJUHSD TA3 2024), Dozier and
-- Napolitano (Westside 2022). TERM START = December of the election year, precision 'month' (Ed. Code
-- §5017 starts the term on the second Friday in December; the MONTH is what every source agrees on).
--
-- APPOINTEES -- term starts on the sourced appointment date (the evidence is in each term's source):
--   Eastside TA3  Roger L. Price      2025-05-10 day    district profile "Provisional Appointment"
--   Eastside TA1  Wayne Kalliomaa     2026-02-04 day    district profile "Term of Office: February 4, 2026"
--   East Whittier TA4 Thomas Baird    2026-03-09 day    BoardDocs agenda 2026-04-07
--   Whittier UHSD TA5 Armando Urteaga 2026-01-17 day    Whittier Daily News 2026-02-03 (he left East Whittier
--                                                       TA4, resigned 2026-02-03; ONE politician row)
--   South Whittier TA1 Elizabeth Guillen 2025-09  month  2025-09-16 special-meeting agenda item "PROVISIONAL
--                                                       APPOINTMENT"; the minutes do not publish the day
--   Gorman  Jen Reyna Abram           2022-10-11 day    district notice; continuous service since
--   Gorman  Patricia Edwards          2024-12    month  no filer in 2024; Dec 10 2024 oath (agenda)
--   Gorman  Kelly Bailey              2026-02-10 day    minutes 2026-02-10
--   Hughes-Elizabeth Lakes TA1 Terri Moss 2025   year   Wayback: VACANT 2025-07-11, seated by 2025-10-10
--   Hughes-Elizabeth Lakes TA2 Raelyn Marshall 2024-01 month  district page "Term January 2024 - December 2026"
--   Keppel TA4 Lisa Klee              2024-12    month  no filer in 2024; appointed to the new term
--   Garvey TA3 Ronald Trabanino       2022-12    month  no filer in 2022; appointed to the new term 2022-09-27
-- Nov 2024 short-term winners first appointed mid-term are seated from their Nov 2024 term (Dec 2024):
-- Cesar Peralta (El Monte City), Vincent Titiriga (Castaic TA D), Patti Garibay (Saugus TA1), Erin Wilson
-- (Hart TA4).
--
-- ---------------------------------------------------------------------------------------------------
-- F. TWO SEATS ARE VACANT NOW -- member seated for the known term, then essentials.vacate_office
-- ---------------------------------------------------------------------------------------------------
--   Lennox       Julio C. Vargas (won Nov 2022, RR/CC 4300) resigned "effective August 31, 2026"
--                (minutes 2026-08-11, Simbli meeting 75046); first vacant day 2026-08-31. Not filled
--                before the Nov 2026 election.
--   Little Lake  Gina Almanza-Ramirez (TA5, sole filer Nov 2024, RR/CC 4324) "resigned ... on 5/11/2026"
--                (minutes 2026-05-12, Simbli meeting 65979); first vacant day 2026-05-11. The remainder is
--                on the Nov 2026 ballot (RR/CC 4348 special election).
--   Both rows get is_incumbent = false; offices.is_vacant / vacant_since are set by vacate_office.
--
-- ---------------------------------------------------------------------------------------------------
-- G. PEOPLE -- 142 new politician rows, 8 reused, 3 kept
-- ---------------------------------------------------------------------------------------------------
-- Reused confirmed LA County NetFile rows (transparent_motivations.politician_sources, source_system
-- 'la_county_netfile', research_status 'confirmed'); each name appears on RR/CC only for this board:
--   b6f8340c Jaime Lopez        "Jaime Lopez for Whittier Union High School District 2024"
--   02367a28 Marisol Cruz       "Marisol Cruz for Lennox School Board 2024"
--   a70b8120 Suzan Solomon      "Suzan Solomon 4 Newhall School District Governing Board 2024"
--   979cee67 (Katherine Cooper) "Katherine Cooper for Saugus School Board 2024, Area 3" -- its full_name
--            holds the committee name; set to Katherine Cooper (only while unedited)
--   60513074 Gloria Ramos       "COMMITTEE TO RE-ELECT GLORIA RAMOS FOR SCHOOL BOARD 2024" (the only
--            GLORIA A. RAMOS on any RR/CC list is the Centinela TA4 incumbent)
--   be76a99b Cindy Wu           "CINDY WU FOR SCHOOL BOARD 2022" (the only CINDY WU: Mountain View)
--   148e431d Hugo Rojas         "Hugo Rojas for Water Board 2024" (HUGO M. ROJAS ran for West Basin MWD
--            Div. 5 in 2020 and 2024 while a Centinela trustee -- same person)
--   00482c08 Cynthia Hernandez  "cynthia hernandez" 2024 (the only CYNTHIA HERNANDEZ on a 2024 RR/CC list
--            is the AVJUHSD TA3 member)
-- New rows: party NULL, is_active true, is_incumbent true (false for the two resigned members),
-- data_source = the district board page. Ballot-name variants go in alternate_names.
-- Robert D. Miller (Wilsona TA1) shares first+last with 6b95b80c 'Robert N. Miller', a Racine County (WI)
-- supervisor -- a DIFFERENT person, so the duplicate guard is bypassed for that one insert only.
--
-- ---------------------------------------------------------------------------------------------------
-- H. NOT DONE HERE
-- ---------------------------------------------------------------------------------------------------
--   * What the 140 stale PEOPLE are (party, is_active, disproved terms): CA_0159.
--   * Trustee-area geography: 22 of these boards elect by trustee area (Palmdale since 2024), but every seat stays on the
--     whole-district row, so an address sees all members (the unified trustee-area boards got X0002
--     sub-districts in CA_0144-CA_0154; these did not).
--   * Nov 2026 races for these 31 boards are not seeded (no race rows exist).
--   * Titles stay the generic 'Board Member'.
--
-- ROLLBACK: DELETE the 150 office_terms rows whose source starts 'CA_0158:'; DELETE the 10 offices in
--   _ca0158_newoff; for the 140 closed stale rows (source contains '| closed CA_0158') SET term_end =
--   NULL, how_ended = NULL and strip the note; set is_incumbent = true on the 140 stale politicians;
--   UPDATE offices SET is_vacant = false, vacant_since = NULL for the two vacated seats; DELETE the 142
--   new politicians (source 'CA_0158_la_elem_high_board_rosters'). The reused rows had is_incumbent
--   false, party NULL, data_source NULL, alternate_names '{}'; 979cee67 had full_name 'Area 3 Katherine
--   Cooper For Saugus School Board 2024', first_name 'Area 3', last_name 'Katherine Cooper For Saugus
--   School Board 2024'. The three kept Hart rows had party 'Nonpartisan'.
--
-- IDEMPOTENT: offices and politicians are inserted only where the id is absent; stale-source notes are
-- guarded on the tag; seat_officeholder and vacate_office are idempotent; every UPDATE is guarded on the
-- value it changes. A re-run is a no-op and the post-verify gate still passes.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _ca0158_district (geo_id text PRIMARY KEY, name text, board_url text, seats int) ON COMMIT DROP;
INSERT INTO _ca0158_district VALUES
  ('0602820','Antelope Valley Joint Union High School District','https://www.avdistrict.org/about/board-of-trustees',5),
  ('0607740','Castaic Union School District','https://www.castaicusd.com/apps/pages/index.jsp?uREC_ID=799367&type=d&pREC_ID=1188877',5),
  ('0607920','Centinela Valley Union High School District','https://www.cvuhsd.org/apps/pages/index.jsp?uREC_ID=126499&type=d&pREC_ID=1844804',5),
  ('0611850','East Whittier City School District','https://www.ewcsd.org/apps/pages/index.jsp?uREC_ID=375044&type=d&pREC_ID=858952',5),
  ('0611910','Eastside Union School District','https://www.eastsideusd.org/apps/pages/index.jsp?uREC_ID=4434428&type=d&pREC_ID=2723146',5),
  ('0612090','El Monte City School District','https://www.emcsd.org/apps/pages/index.jsp?uREC_ID=1566382&type=d&pREC_ID=2631375',5),
  ('0612120','El Monte Union High School District','https://www.emuhsd.org/meet-the-board',5),
  ('0614940','Garvey School District','https://www.garvey.k12.ca.us/board-members',5),
  ('0615600','Gorman Joint School District','https://www.gormanschool.com/apps/pages/index.jsp?uREC_ID=4436036&type=d',3),
  ('0616680','Hawthorne School District','https://www.hawthornesd.org/board/members',5),
  ('0617040','Hermosa Beach City School District','https://www.hbcsd.org/apps/pages/index.jsp?uREC_ID=2165923&type=d&pREC_ID=2175118',5),
  ('0617880','Hughes-Elizabeth Lakes Union School District','https://helus.org/board-member-terms',5),
  ('0619440','Keppel Union School District','https://www.keppelunion.org/page/board-of-trustees',5),
  ('0620880','Lancaster School District','https://www.lancsd.org/Board-of-Trustees/Meet-the-Board/index.html',5),
  ('0621210','Lawndale Elementary School District','https://www.lawndalesd.net/board/lesd-board-of-trustees',5),
  ('0621420','Lennox School District','https://www.lennox.k12.ca.us/apps/pages/index.jsp?uREC_ID=759151&type=d&pREC_ID=1165850',5),
  ('0621930','Little Lake City School District','https://www.llcsd.net/apps/pages/index.jsp?uREC_ID=4418750&type=d&pREC_ID=2652287',5),
  ('0622890','Los Nietos School District','https://www.losnietos.k12.ca.us/apps/pages/index.jsp?uREC_ID=36269&type=d',5),
  ('0626190','Mountain View School District','https://www.mtviewschools.com/boardmembers',5),
  ('0627180','Newhall School District','https://www.newhallschooldistrict.com/governing-board-members',5),
  ('0629580','Palmdale School District','https://www.palmdalesd.org/apps/pages/index.jsp?uREC_ID=4322297&type=d&pREC_ID=2531617',5),
  ('0633570','Rosemead School District','https://www.rosemead.k12.ca.us/board/our-governance-team',5),
  ('0635970','Saugus Union School District','https://www.saugususd.org/governing-board',5),
  ('0637560','South Whittier School District','https://www.swhittier.net/board-of-trustees',5),
  ('0638220','Sulphur Springs Union School District','https://www.sssd.k12.ca.us/governing-board',5),
  ('0640650','Valle Lindo School District','http://www.vallelindo.k12.ca.us/apps/pages/index.jsp?uREC_ID=1211155&type=d&pREC_ID=1447330',5),
  ('0642120','Westside Union School District','https://www.westside.k12.ca.us/trustees',5),
  ('0642450','Whittier City School District','https://www.whittiercity.net/apps/pages/index.jsp?uREC_ID=687934&type=d&pREC_ID=1127514',5),
  ('0642480','Whittier Union High School District','https://www.wuhsd.org/apps/pages/index.jsp?uREC_ID=753074&type=d&pREC_ID=1160588',5),
  ('0642510','William S. Hart Union High School District','https://www.hartdistrict.org/apps/pages/index.jsp?uREC_ID=317470&type=d&pREC_ID=725071',5),
  ('0642810','Wilsona School District','https://www.wilsonasd.org/en-US/pages/29dd1313-c957-4c75-a6e1-e994a027c62e',5);

-- action: 'replace' (stale out, member in) | 'keep' (verified stale holder stays) | 'add' (seat added here)
CREATE TEMP TABLE _ca0158_seat (
  geo_id text, office_id uuid, stale_term_id uuid, stale_pol_id uuid, stale_name text,
  new_pol_id uuid, new_name text, term_start date, start_precision text, how_started text,
  in_lieu boolean, action text, how_ended text, evidence text, stale_evidence text
) ON COMMIT DROP;
INSERT INTO _ca0158_seat VALUES
  -- Antelope Valley Joint Union High School District
  ('0602820','955d3a0a-60e8-4e2b-a389-0dc097edd092','1044197c-d736-4977-a4a1-d0d3cfa883ef','8c145930-0af7-4cfc-b959-06a2a394e11e','Dr. Kathleen Lang','6075a347-8818-5ec4-ad08-9a20518aa22b','Carla Corona','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0602820','b071d0ff-5bce-410d-bfb9-fb25246c6618','25322a68-3ada-42d2-9080-a548e3ff5a80','a7e73528-e586-479b-99b5-d5eaa0fc6f42','Lorene Reed','46a41762-434e-506a-bf5e-c003c3ab828c','Miguel Sanchez IV','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0602820','b3ad50ac-295f-4139-abfb-d1e562912a20','85b1efec-5d80-491d-90f1-6d6b4cbbf7f1','af7efbff-3408-4579-a6ba-f9c76c0590e9','Michael Layne','0a16ea62-8589-5fcb-94c9-6d94bbbdc64b','L. Rosemary Mann','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0602820','c6ff47cb-aa1e-48d0-84e0-118b802d215d','0ada1721-190b-44ee-9bc7-99132856ce9d','c965c628-5fa7-44d2-b299-59e49eff3ece','Jim Gilbert','98b2d8bf-08fa-54f4-a70a-405505259804','Charles Hughes','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0602820','e201d9e7-ce5c-41e3-9bf5-a7874fe0364f','71887a35-eae9-43c7-9611-a6ec792af185','b4a1311d-edab-44c9-81fb-05923f998753','Adyson Quashie','00482c08-b86e-4a7c-b5b8-27c9038f8fb5','Cynthia R. Hernandez','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Castaic Union School District
  ('0607740','5bb14f72-c6f8-4e3d-a11b-00b233b30312','00161d25-9ce3-4df5-852a-b43a9b75907f','2183063b-a86b-49da-bf0b-44799d0a15b1','Kimberly Tresvant','02890a06-5e9e-550f-9812-1c2af9992041','Mayreen Burk','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0607740','729710b1-9a90-4c1e-8b4b-5e5ea53304af','042f9ab6-1237-46cb-9d4a-730cb5cb3a18','bc17004c-5edb-429d-a585-182b4db29c26','Lisa Zellhart','64e9a1d2-539e-5555-9a73-4cdf9c08baaa','Fred Malcomb','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0607740','c77c38a1-0f0a-4684-9439-b70e9a990625','2ffc3fa8-c1dc-412c-84d9-b52203ada33a','f90049fb-23a9-41ad-b4da-49ef4ef518d4','Randell Herr','86d8eb68-2c79-5587-a07a-9677d779e8e2','Erik Richardson','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0607740','d673dbbc-47b5-41f5-b4c5-1a54b2feef2f','3af94df5-f4ae-4255-a127-d45356ac82a9','62eff385-96e5-4b35-8383-55bd7e2cbe28','Mindi Lauro','c8dace65-f8ae-5032-a2b7-4757a821a178','Laura Pearson','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0607740','f5a4bfa6-184e-49e8-9618-6c339fa9c3f2','c70e8470-9970-4537-91ee-288df227431d','823e3a9a-f135-4014-91cf-2b947f03f256','Colleen Hawkins','d3243df7-a7b5-5f42-b277-c51b468e303e','Vincent Titiriga','2024-12-01','month','elected',true,'replace','unknown','first appointed 2023-06-07 (Hometown Station / SCVNews); then the only filer for the Nov 2024 Trustee Area D short term (RR/CC 4324: "Unexpired term ending December 11, 2026")',NULL),
  -- Centinela Valley Union High School District
  ('0607920','6245bff0-ee6a-4991-8792-09a35ad63290','b16e9af5-f374-4cbf-961d-2be813161306','4c76e59e-fd86-4534-ac05-9281ee4aa776','Javier Gonzalez','148e431d-7313-47cc-ae4f-aadba0f7f33e','Hugo M. Rojas II','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0607920','90db7b74-576a-44fb-acda-b0b9009e7c70','de82e4f4-753c-40c9-ac7d-94b3a082fcd9','3eaa5036-ec52-48ff-8111-73347db2bb18','Sonia Campos','1d2f9313-f72f-5595-89a8-f41faa903db9','Estefany A. Castañeda','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0607920','eac642a5-df3e-4e3b-b47f-e1ee738b0824','ebc21855-dfbc-4751-92e1-b52a50be59db','9f43110f-23e1-45ab-b264-9f079720892f','Arturo Flores','fd6ce9a2-b7ef-52cb-8079-5428ad39cdab','Marisela Ruiz','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0607920','f9c43152-347a-47d7-9c1a-531eb063903e','2233d5c0-1a17-4de7-baab-3f51600e2b6f','27925c8c-5bfe-42c2-a46f-aa41352543dc','Natasha Henderson','9633065b-dfc5-59af-8cdd-49237080a670','Nohemi Ramirez','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0607920','c348a675-54c7-5b9f-9948-c60e13056f9c',NULL,NULL,NULL,'60513074-ebf1-4bd9-8a46-4feee43fcff6','Gloria A. Ramos','2024-12-01','month','elected',true,'add',NULL,NULL,NULL),
  -- East Whittier City School District
  ('0611850','15d31bfd-6619-46cf-acbc-6e58108cc2e3','f14fb864-dac9-4e95-ab5e-814ff3796d7a','c1f47e52-3f0f-4dcb-9421-a14b8daab0db','Scott Hernandez','e73183bb-8ab6-5678-8f4b-08aec556c5cb','Lisa Michelle Dabbs','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611850','1ac3d6f3-a731-448c-9517-bc730f5a1377','8ae66d52-5198-4d13-ac79-5b4865db6d88','1480a0e8-082b-4157-8ebd-4876cf5644f7','Patty Pacheco','d93d9671-cb6f-57b3-af0f-ae594d4d6a46','Carlos Aparicio','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611850','25722e8c-772f-48b3-ab79-8b226bb662d4','807a9a18-e9e9-4b07-8d2f-bf06a77c8321','db1606e1-817f-4071-85d9-7d60ff31edd1','Suzy Moore','509804f2-4813-5985-934b-c33e4eb9efbb','Wendy Carrera','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611850','82312751-ab96-4125-a208-89fca4209a34','6c3f59aa-b455-4bc7-a469-9048119b1425','421390dd-e2cf-492b-bdd7-d5053a719592','Kathleen Ruane','f71bc6eb-b367-52eb-8f5c-e2daf96add10','Christine Chacon Kennedy','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611850','936eac79-3ddb-42d3-9511-748bb5e92257','e7807999-93ca-4fbf-93d9-3aad3021dad4','d50ad38d-ed64-45ac-b3c3-cf4e0f6ac788','Andy Torres','4b0e7873-6534-5f9b-be74-db2d055874c6','Thomas Baird','2026-03-09','day','appointed',false,'replace','unknown','provisional appointment to Trustee Area 4 after Armando Urteaga resigned 2026-02-03; EWCSD BoardDocs agenda 2026-04-07: "On March 9, 2026 The Board of Education voted to appoint Mr. Thomas Baird as the provisional Board Member for Trustee Area 4"',NULL),
  -- Eastside Union School District
  ('0611910','01407d0b-414e-4ff4-b09d-30f36442dc6c','c525db6e-1592-4ba3-8062-81f3c98932c6','cccd245f-2b48-4360-b0f7-e9e2affb8921','Lupe Trujillo','66a52dda-274d-5998-b51a-0bf59b74e11e','Julie A. Bookman','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611910','656c7e5d-2376-487b-a671-f9460ad5554e','a46042d4-e12a-4ad3-8be7-a29191972361','b8e52d93-7468-4fda-ab9e-a4b0e1477255','Trina Stringer','b9479e0b-44fa-5d7e-b6a9-7f9ee87c432d','Joseph "Joe" Pincetich','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611910','89ce3183-4fe6-4c74-b174-d65cb4f35a29','0f5a7138-4b05-4032-918c-e813778cca8d','2a3f478b-74fa-4077-b13a-794b947a5f21','Monica Harmon','19c3b72e-2b96-5e30-b58f-db7869af2ac7','Roger L. Price','2025-05-10','day','appointed',false,'replace','unknown','provisional appointment to Trustee Area 3, eastsideusd.org board profile (pREC_ID=2675710): "Provisional Appointment Term of Office: May 10, 2025 through December 2026"',NULL),
  ('0611910','aeae3637-4f7a-4ea0-a042-e7c39f751871','e6ec686c-c242-4ba3-9b4c-ffb05ff580f9','235bc16f-a70d-4bbb-891c-562580540b16','Michael Lara','dfaf5da2-0b31-58b1-8302-8218f4ce8fac','Shawn Cannon II','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0611910','68b215cd-78fe-5162-845d-230e4e8d6ff4',NULL,NULL,NULL,'5c7c3ea2-02ed-5f35-8651-e7fd7e14deeb','Wayne Kalliomaa','2026-02-04','day','appointed',false,'add',NULL,'appointed to Trustee Area 1, eastsideusd.org board profile (pREC_ID=2729537): "Term of Office: February 4, 2026, through December 2026" (AV Press reports the vote the day before; the district date is used)',NULL),
  -- El Monte City School District
  ('0612090','28cb63a8-3dda-4e9b-a0ea-bbaeecd9930b','a5907cb9-c313-4dbc-a17c-b6b6609c9944','3f06b286-4c26-4a01-a29c-88a0e1145bb1','Alma Guerrero','2da3e36f-45e0-5591-a5ae-ea1dce87c5d0','Lisette Mendez Garcia','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0612090','655e9d0a-99e4-43ae-89ef-1a81f0e13fb3','0e32b675-79a5-4ab6-afb9-f622d730e58c','1b7900b6-50b5-4c43-ba3b-673fbf0fe02d','Gloria Corrales','e169f9e9-8f81-52f6-94e1-ecf5f08ebeeb','Elizabeth "Beth" Rivas','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0612090','93f28691-c942-4e32-905f-d26afcdaaa4f','c910576e-0fe0-4059-a508-aa02f2e4de7e','b27b616c-88d6-4288-afd3-80d7e60ba46b','Yvette Jimenez','c2aa3258-95ef-58cb-913c-9cf7db8b55c4','Jennifer Cobian','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0612090','9884ac4c-b91c-4d35-863d-cbf6a3f12912','b29997eb-5fae-45ff-9e29-b751c41320be','40b52e27-5ad5-48af-93dd-5d8a625746f6','Rosemarie Lopez','c4d72241-cf6d-5b5b-b3fc-7d2b6e2c8552','David Siegrist','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0612090','e9994d5a-8b43-48e4-96f6-0643116b41c2','3cf93dd0-cdb6-4206-a29c-dfab6bd9a67d','c043a9b5-ebc1-4a58-8c0d-0125744767c8','Ana Ponce','254e533d-d131-5b34-9027-99a81f545b88','Cesar Peralta','2024-12-01','month','elected',true,'replace','unknown','first appointed 2024-04-22 to the seat Christina Flores vacated (EMCSD BoardDocs minutes 2024-04-22); then the only filer for the Nov 2024 short term (RR/CC 4324: "Unexpired term ending December 11, 2026")',NULL),
  -- El Monte Union High School District
  ('0612120','23a252ac-7eed-4304-9ef4-ed388a7771e5','2bca02b0-1389-4b88-bd81-dd255736682d','c97d6025-84bf-44be-aa50-90fbe1029b4c','Ingrid González','5e847174-1790-5c61-8bc6-829da06f507e','Florencio F. Briones','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0612120','5ea819d1-4197-4295-99ec-b05ff78b451d','95e1e18e-abaf-42ae-a3c1-0661136bf484','1eb2e102-323a-4852-8366-ba68681d361c','Maria Elena Martinez','02370bdd-6b74-5814-bc64-a0b38524e23d','Luis G. Guzman','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0612120','6d497f05-0b2e-4b26-9f87-c3bfd2e77417','f189bd9f-c92a-4517-a2a6-bfe993f7ceb4','6485f5ef-6df0-48b7-8f66-8e7a53693435','Jose Lara','2d6e76cc-b283-5a84-a57d-277d1caf0038','Maritza C. Galaviz','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0612120','e0f71367-f495-4abd-8e28-d25fefa1c38d','30d0fa97-900f-4d26-b037-1e68d0cef7f4','6fab21ef-c66e-4fff-afb6-93e1ec7c5c2f','Emma Turner','2721420f-8032-5e4d-bee4-bc6795ac3b22','Qui Nguyen','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0612120','ebe4748c-0189-4d6a-a0cc-c0b83a7458a6','a644151c-b1d2-4d64-b32d-17e6de643cdd','9ce4fa5c-4884-45aa-bd8e-b0fd7257c6ee','Xochitl Flores','a64f8955-568d-5818-bc85-b95cb179b820','Ricardo Padilla','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Garvey School District
  ('0614940','17fc9282-419e-4d49-95f2-182abce3f7bd','25a3015f-dcec-4e92-a2ba-4c03fe86254f','47e3c1cf-c57e-49b6-92e7-e98fd642623e','Teresa Srisiri','378cba56-08f7-5bba-ba64-22c1f515cfb7','Andrew J. Yam','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0614940','2a138c9d-d32e-43fc-885f-02a2aabee3f6','b5f14c5a-f5ef-4675-9236-53e9666f0198','416b3a99-371f-4125-95d5-ee693877d76d','Jonathan Contreras','dd2eccee-d3d8-5198-884d-c0758beb3b20','Ronald Trabanino','2022-12-01','month','appointed',false,'replace','unknown','no candidate filed for Trustee Area 3 in Nov 2022 (RR/CC 4300 shows papers issued, none filed); the board appointed him to the new term on 2022-09-27 (Ed. Code 5328 / Elec. Code 10515, Garvey SD minutes); term begins December 2022, precision month',NULL),
  ('0614940','b454ba3a-b15c-42a9-b7a6-d7c21fc09307','4890adbc-a5e3-40d3-b533-48a281631abf','5cbff79d-99e2-4054-be57-07049ca1e3cf','Tina Lim','091e401b-e9cb-5aa1-90db-d76825b662d1','Maureen Masmela Chin','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0614940','e4400889-230e-436f-b7d5-a50b95bc5f8e','cc2e141d-50fb-462d-ba8d-039b3b450a5f','c4e6fe44-6eff-4674-b8b4-185de72a4d39','Maggie Cheung-Lim','a2021466-0387-5f9c-8dfa-39ac6ae94cdb','John H. Nuñez','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0614940','f1fab2ab-232e-4cfa-8620-fc2c3515d4ce','a719ee25-43cf-4a75-9f37-85f972a32f79','5f6d627f-0916-4b20-9d70-58923c8e344e','Kimberly Martinez','ada9a7d8-259e-5bbc-be3c-a9c911478e3e','Paul Duran','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Gorman Joint School District
  ('0615600','20b43be0-c702-45d7-9e32-8419330b6f1c','e2ab7d78-b491-44dc-9017-74b07fadc705','5562b788-c13f-4f4d-87c4-521e271059e9','Anna Wren','f3a53b20-c624-5e4b-98eb-74198f15039b','Patricia Edwards','2024-12-01','month','appointed',false,'replace','unknown','no candidate filed for Nov 2024; Gorman Joint SD agenda 2024-12-10 (4.files.edl.io/2775/09/09/25/...): "Administration of Oath of Office ... provisionally appointed by the Board of Trustees to fill the vacancy for the terms which expired December 1, 2024"',NULL),
  ('0615600','283e6e50-c272-4199-8e34-cdad494f836b','977e94d7-8b58-470e-aaa8-fde1681949c0','03d9147a-4402-474a-ac7e-8e70022f58dd','Sharon Caughey','970a9d54-7a53-5ca0-add3-d52dc8050e42','Jen Reyna Abram','2022-10-11','day','appointed',false,'replace','unknown','Gorman Joint SD notice (4.files.edl.io/74fd/06/18/25/...): "On October 11, 2022, the Gorman Joint School District Board of Education took action to unanimously appoint Ms. Jen Reyna Abram to fill the vacancy created by the resignation ..."; continuous service since',NULL),
  ('0615600','6d0b1ab4-dfd4-4f2c-b629-0db9661324b8','9bb18872-e89c-497b-8912-6bd2970f4369','26ae5f79-9ec5-4b3f-8b9e-dc2caaa71101','Crystal Sherrill','7859038c-64e3-5192-ad2d-a77562e29a18','Kelly Bailey','2026-02-10','day','appointed',false,'replace','unknown','Gorman Joint SD minutes 2026-02-10 (4.files.edl.io/5dc6/06/15/26/...): "approve the appointment of Kelly Bailey to fill the School Board vacancy" (replacing Ryan Ralphs); oath administered at that meeting',NULL),
  -- Hawthorne School District
  ('0616680','0938cb35-28b6-4feb-b945-bf18544e04d8','343e8317-b079-4f75-91c6-126d1aec793b','d3a9f508-ebc5-4a7b-ba1a-8dc71827d720','Maria Felix','14382e97-4b6f-5ab4-9bc2-2483927ca70e','Cristina Chiappe','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0616680','a9d13bfa-b87d-4484-a696-43c5fd555010','2b7547c7-64af-4a9e-bebc-8b9dab6c7a7b','ec31be2a-2151-48d8-9d40-3cf767836874','Sarah Garcia','9fa27bc9-c6a3-5e43-a632-560280f3ae56','Sergio R. Mortara','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0616680','d1493023-2c03-4438-851e-c6481ad447bd','acc37a2f-c203-4e11-bf37-fbc0c7fef23e','74257677-b02b-42db-835d-467b01112b3f','Antonio Castro','36ee4568-b12d-58f8-b642-2ea716ce9de3','Vicente Bravo','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0616680','f55cad21-3c07-4fd0-aeb6-e1b5cc4bec6b','ac94919c-d316-4f61-a62b-a3987bc6b724','ab063dea-0ed6-450e-9a19-eb3a6a6e5da9','James Moore','54a7eed3-9757-56a8-a493-5cdd4f1370a6','Luciano Aguilar','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0616680','f8f587c9-336e-4864-8b36-71db45c14736','090e1196-0782-4c9b-b2a0-9bb20e2a4aa5','201e0365-8301-40f7-83bb-2292445fcb78','Lisa Williams','43667ed4-9a14-5c58-a2ae-d6667f241ba6','Eugene Krank','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Hermosa Beach City School District
  ('0617040','2d7cb36a-c134-410d-8054-52988dfbc1a6','21d17407-6517-465e-b989-8b0a79042c11','c5a12549-9b81-4013-b747-bbc7a4fca3f3','Jeffrey Reinhart','47cc3d78-97f7-5443-91d7-5f039c27028b','Catherine Barrow','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0617040','8e3cfee0-7bdc-47b4-b52c-6540cd779a2c','3d6778c1-a90b-4304-9186-e521ea3307f4','9515abde-bac7-427b-88e9-9c866dc0a968','Thomas Bakaly','cd6bf6bf-b20a-5cbc-8eab-e5aaea8c73c5','Carol Reid Kluthe','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0617040','b9734ce2-1004-48b8-b427-cd4af0167087','87e0c470-4677-4a08-a158-f15bc1e6f9f5','3e2c9417-79c0-4666-bff1-85b9b8237631','Lea Liwanag','ebe0883c-fca2-5e9a-ac30-c3407e60a27f','Margaret Bove-LaMonica','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0617040','f453dafd-739e-40fe-9641-900a0d2d8dfb','bdab221a-023c-4dca-a2e2-b5418cf8672c','6804f05a-f30b-425f-a4e8-5919f510b024','Joanna Ruelas','1a98aa19-6dc0-5a11-8ebd-3a252517f21b','Jennifer Cole','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0617040','f78c9134-e8dd-4832-b372-618315b04984','98ee69ae-e1ed-4ef3-a135-003aeb6badca','f712f1e9-2b98-44d8-b552-917b034241c6','Kellie Kennedy','092101cb-2998-5321-bc38-21d215a3f24b','Rachel VanLandingham','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Hughes-Elizabeth Lakes Union School District
  ('0617880','05e4d7ac-b5c9-4aee-b95d-dd975004a825','88ea3d22-9a2c-4d24-9151-5732f07189d0','288499db-64df-4c1f-ada4-9b94af531a34','Dawn Snyder','33587b77-1b7d-5c6b-ae0f-f811932a027a','Terri Moss','2025-01-01','year','appointed',false,'replace','unknown','appointed to Trustee Area 1 in 2025: helus.org/board-member-terms shows "Area 1 VACANT" on the 2025-07-11 Wayback capture and "Area 1 Terri Moss, Trustee Term through - December 2026" on the 2025-10-10 capture; RR/CC 2026-11 list files her as appointed incumbent [A]; the date is not published, so precision year',NULL),
  ('0617880','fed881cc-3877-451f-a9a2-683cb213cf94','31d5dede-c7bc-4810-b73e-b6775a7695c1','d3eebfad-b395-4180-8562-941dbb8cecb0','Jeremy Williams','e4685a86-a0a7-5f9f-8a3d-53cf1865ab1e','Raelyn Marshall','2024-01-01','month','appointed',false,'replace','unknown','appointed to Trustee Area 2: helus.org/board-member-terms "Raelyn Marshall, Clerk Term January 2024 - December 2026"; RR/CC 2026-11 files her as appointed incumbent [A]; precision month',NULL),
  ('0617880','6e5126e5-1a1c-5960-806e-4a817761ffc1',NULL,NULL,NULL,'b93aaae3-4771-537f-b145-bce88f0e8dd5','Jim Wall','2024-12-01','month','elected',true,'add',NULL,NULL,NULL),
  ('0617880','3bcc28ec-597e-5d30-b69f-b3b31c946305',NULL,NULL,NULL,'51ee7915-914c-5d80-9988-a23691de7dda','Stephanie Lewis','2024-12-01','month','elected',true,'add',NULL,NULL,NULL),
  ('0617880','7fe3c13b-7cc4-5e33-8f59-815485de9c17',NULL,NULL,NULL,'40829ed9-4fed-5563-83b9-87750b90777f','Lola Skelton','2022-12-01','month','elected',false,'add',NULL,NULL,NULL),
  -- Keppel Union School District
  ('0619440','08f51570-8f4c-45a8-9588-c05f1baedf04','4b41691e-f7f8-495c-8c70-5f84df337da8','4352b2da-86fd-4435-a0f0-247972d34f38','Eloisa Lopez','c8730086-8ef0-586d-9b72-4c0a791edf3c','Blanca Nava','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0619440','0d85c456-cdb5-41f3-9ab3-1d736f3fb1fc','5839ec10-00bd-4483-ba81-1487f219bfc4','2a954d75-5a34-4753-b508-be66799bc760','Dolores Santiago','7d6c98b7-a053-55ec-b206-5fdd9d29bebd','Andrew Ramirez','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0619440','29388a67-eae8-431e-9810-0bd8e1964ee1','bb9183a8-4428-4c03-95ef-4c1115e11227','87b39a44-75b3-4395-a4a3-974b288c6047','Jose Garcia','e1b27b2b-f039-5e7c-b2b1-9668e37963e7','Alma Rodriguez','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0619440','2bd4b380-8f8c-47fb-9b66-3dddbd409656','105ea866-bb9c-4142-b85a-d398ac89d03c','8f32c725-c14c-493a-a1c8-1f03fbd7f5ad','Mark Brown','69e3d7f9-e368-5ea1-ad74-2e707cdfd233','Lisa Klee','2024-12-01','month','appointed',false,'replace','unknown','no candidate filed for Trustee Area 4 in Nov 2024 (AV Press 2024-08-28); the board appointed her to the new term (AV Press 2024-11-01); term begins December 2024, precision month',NULL),
  ('0619440','771d999a-3b93-4dbe-a74f-b70eeedbfa23','25622c4e-8a3c-43ee-b314-3a1a769a6cf4','7b02ad38-18b8-42c1-bc8a-cc94509a1252','Sandy Santos','766834d5-e806-52b9-8702-b5e243e21ed8','Felicity Teff','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Lancaster School District
  ('0620880','150bfc08-2f73-4ce5-99df-3c7020dabbd8','ceee8d16-4425-450a-ad18-3bee192b924b','1302f537-1f51-4252-8567-12098983781b','Laquita Moore','d34d8972-b563-5aef-bb04-1d3161698faa','Greg Tepe','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0620880','4575b279-838e-469c-aa7c-4b460511c7d7','de9bd119-a0c4-4b95-8f56-d1e4a73cbfcc','391778af-fd7e-4e77-9998-08af8c645a4c','Guadalupe Romero','dfa37b57-a204-5db8-9010-d68a773807fb','Keith Giles','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0620880','4e651b41-ba63-4921-a8f8-64e2c62e4ce5','47648ad6-ba4a-49bf-b09f-4cfe9690a84b','c3b5ba4c-92f1-4388-89d8-6d4ed9a1e944','Renee Garrison','ca090dea-fe42-598d-b90d-1cf441b83bf1','Jullie Eutsler','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0620880','548d38e0-55cf-40e7-b803-2a1341a54312','9add46f4-74fc-4d22-90aa-aebd46d084d2','aa1cf148-3ad0-4295-924c-11ac69157685','Joe Renteria','a47b7e2f-241c-500c-9f2e-2919ae63010a','Duane Winn','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0620880','ce7ad338-cc7f-4fac-bf9f-181b33ae5ca2','d8d4133e-011b-46c1-a4df-805d7a3d1206','589045c8-eb1e-44bc-b4f5-d4169b6892c0','Kelly Talbert','ee16f7ef-91ae-5e3e-90db-168c8e679d62','Pamela Starlson','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Lawndale Elementary School District
  ('0621210','050ab901-607b-424f-86f5-5fe01ad8d869','eaa0a39a-adc7-44c3-9b26-8bf207d1e247','9d32e71f-4a9b-4adc-9b9f-15679e4841aa','Robert Sherrill','080c8e8c-4d3f-53c6-b101-7f57a780d0bf','Cathy Burris','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621210','099eecaf-9190-4e83-878b-8aba5a695749','03463682-d616-4574-9e0c-d6c8af9a27db','76e70bf9-f53e-4fcc-95c5-e0e268b318c1','Diana Hernandez','41c5f927-42c8-5310-b7ac-c17634ca5b19','Bonnie J. Coronado','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621210','466a3b7d-0caa-4f9d-8405-708804d2cfa4','829bfe3f-67da-4c28-aeeb-00201180a99b','f0fbf466-3a1e-4a8d-be0f-d22fffbce140','Paula Maybury','1275ebdd-c7ab-5b41-8932-143ada0bb53e','Ann M. Phillips','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621210','57d5e5d7-2266-419b-ac61-1f1316e57485','ac28be3d-645c-4202-b41b-873955c5d6b3','6be2af76-7c14-4a06-a207-736df411221d','Randolph Love','6257be6e-b8c4-50be-8aa9-d825d778c0a2','Shirley Rudolph','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621210','c70db79c-30f1-4f19-a6e4-cfef5eada2d3','cbb4c662-945c-413c-90a4-02fa73c70610','716a22b3-5726-4147-92f1-5e6c44c84d81','Robert Pulley','7cf4f305-0105-5a66-8ea6-6714424cc23d','Adim Morales','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Lennox School District
  ('0621420','04f8783a-3549-4b04-a486-63c77d5c1b13','984da669-18ec-45d8-a276-4ca644b4680b','7a441141-a7bc-430f-8a0a-a87773a49368','Carlos Cuevas','1baf211d-d0c6-5447-9abf-fb97442a2e73','Angeles Gonzalez','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621420','1802d82f-6370-4072-a61b-914a19bf35e8','73e30efc-628d-4264-9053-7e7e49af1176','5d970ad1-ab54-4927-843d-de7c92539b8e','Ana Paula Cruz','ac5d3733-1925-5de1-a2b5-3385385185ff','Karina Cordero','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621420','24d66a4c-5fce-401c-a3ca-896d79765be0','026e2539-ac5b-4c0b-b005-86ab0794bf48','c123ba35-f671-4e76-82bd-f90ae5aabfa0','Alberto Guerrero','e35d9352-c929-553c-bfde-4e1994cb2c10','Angela Fajardo','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621420','2da2f7cd-85e6-42aa-9ffa-5225bbd4f4ab','8cbfd749-cab9-4f10-9242-0f556366fd2c','be22dba0-3dcd-49ad-92e5-a0c4326f0f4a','Guadalupe Guzmán-Guerrero','02367a28-601c-402a-94d0-9a5552d8c0b1','Marisol Cruz','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0621420','ba0547da-8034-4e08-a0eb-63ee861e7457','8a8b6b71-0a58-43c9-8812-bf069a61143a','acef6548-15ea-42fd-b9a4-7fb772929634','Yahaira Rodriguez','9c217f95-ba7f-5f01-84c8-289c8b16281d','Julio C. Vargas','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Little Lake City School District
  ('0621930','206c06a9-3414-4c57-b2ae-11a0467e571f','8fb29cc6-312f-4b51-86eb-251629a4accb','836583ca-b6cd-4871-a341-cb8fa5ecf64b','Tony Oseguera','92db81fd-0ef1-5b1f-aa9f-7f4b1c57474d','Jasmine Sanchez','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621930','5b68a7cc-24b3-4c50-a680-f84cc22bf8f7','852b8401-dff1-4d0e-95d8-715294d39250','c83403a8-2c30-4b6e-a97c-1faf8aebf43f','Margarita Rios','683a42f2-4fbd-53b5-88f7-0214c0347acc','Hilda Zamora','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621930','76c05fa3-4e9b-4346-8273-85377e1ac702','720d7114-aac7-4bfe-94f9-17c8ee1c6af2','3e899452-b609-4aee-97ca-e5544a76c708','Joe Zertuche','aa4efe30-541b-55e8-84fe-802376088173','Lisa Chavarria','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621930','8c6a0ac9-047d-463a-937a-c1c7bcb24577','e8fe7ce3-c274-4ea0-adfd-720cb2e9a81a','a1643116-8ce4-495a-bcf0-2a967e17230f','Claudia Hernandez','55ea6eb6-100c-5dc0-ae78-cb251a8f4e0e','Manuel Cantu','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0621930','be269633-0bb3-4d19-a57e-9e5226dba12c','9d81f00c-6b8d-4346-9b4b-370bb7a856f8','65ad8e41-d69f-4c8d-a612-7083afe8cf5f','Elias Gonzalez','81917154-ced7-5743-8d63-f2ecfb15c29d','Gina Almanza-Ramirez','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Los Nietos School District
  ('0622890','5d6c83e8-721c-4a68-93ab-844a4d617dfc','4362d094-f12d-45c2-bd12-8fa690eb25f1','0e7799b3-1ecd-4252-808a-10691f3cb5e3','Tonia Moats-Mendez','b39ba0bd-c8f8-5c52-ad58-794c9a875ac0','Maritza Nieves','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0622890','84c5d6a1-54c4-4d2b-ae6a-59f12dfce150','6fb7d20c-39e8-4696-bc06-f83c8ea2ca9e','3d8bb339-b2d0-471d-a169-62713d1eb8a6','Maria Carmona','e9e76dc1-89b2-5022-9673-2324f398c892','Emilio Sosa','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0622890','a7b7d3af-7e6a-4588-abc7-c52400053232','5a627732-c674-405d-8db9-f7e71cf1418b','61082cd9-f3ad-4179-ab00-2535a6b5f64a','Saul Zavala','2340b80f-7e56-509a-a787-8bd5ee332293','Edith Marcel','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0622890','aafb5ed7-f658-47f5-9376-aa76bc0d668e','34456e3a-72a9-40b4-bcd0-f8ebe9d1109c','f6a42150-82ed-4416-a3c6-fd8331324889','Stacy Harris','de280cd0-7351-5719-91be-8b372e3d1dd9','Catherine Martinez','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0622890','ca770ab5-cb99-4279-98f0-3e04e5677d68','04489b76-a99b-426e-bcad-50a46855823a','d44a17ee-02e2-42e2-89ae-9da222037dd1','Irma Herrera','3a463055-4b42-503b-b7cb-ce116cc9ceb5','Evelyn Avdalyan','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Mountain View School District
  ('0626190','00df3089-87c8-4c15-bbdc-1393aba30219','86478dd3-c673-48b3-98cd-e7e9b193e3dd','91b3fdfd-9908-495e-86c6-e2d523982e15','David Aguirre','641c4da7-9ff4-5003-a7cc-a581d0948ff9','Jacqueline Saldaña','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0626190','647be738-b2dd-4460-877d-c0ba8417c3fb','fbf08df7-9a6c-4e7e-899e-9252d8e942be','851b6001-b75d-4c50-82af-a7b9b816bb04','Maria Beasley','c3f6a27c-8462-5ddf-bbea-9000e33a3ce2','Adam Carranza','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0626190','7ef4e9c5-cae7-4dd0-a651-e7be0e410264','30503204-4aba-4fa9-9d1d-78ed25aa0af0','ddc4b4df-7744-4ce2-8620-db2faeea86f2','Steve Pena','71ba46a1-2bb4-5864-94d6-4547969b7fe3','Veronica Sifuentes','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0626190','9567c7fc-8fce-40d2-9180-14cefde082b4','7b3230cf-1726-48cb-9fab-3da25c46fde9','97ce03cc-d559-40b0-ad60-e088b6628411','Karla Ruiz','2fd1dcb3-07dc-5960-a7cc-431fd32bf031','Christian Diaz','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0626190','de3edbbe-e858-4a1e-a689-ab40bb89483e','4983284a-24c1-4eea-98bb-50c974c576da','093326fa-cf2e-4c6c-9522-66f7381b9e49','Rosario Guzman','be76a99b-a702-4318-9efd-a9e9e4790193','Cindy Wu','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Newhall School District
  ('0627180','082dc9f0-d88e-43cd-8f3d-68f836901447','e6099e82-a953-40b9-b5c6-bf554fb7f0b2','4e1915ca-20d8-49e0-aa5d-af15a5e85f44','Deb Hartwell','3ae27906-e072-532a-86a8-c73c2654ed08','Rachelle Haddoak','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0627180','2c87e1b5-fe57-41d8-a7a6-3c7b60f2d05a','6627b786-a7ae-4878-8942-ce9c00bb2ead','59874680-6d08-41e5-a87f-9f946ec98b35','Lindsey Cardenas','a70b8120-b081-4826-8c6a-40bdd6229843','Suzan T. Solomon','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0627180','a9600dbf-2466-4346-bad2-80f1ff665367','84aa6478-c973-4626-897f-b21574f90e64','6c9abc89-f26c-4ead-a98c-abcc2abe5c50','Jeff Hearn','e0e73c33-420f-595a-ac95-de66ef20db1c','Isaiah Talley','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0627180','b53f0e78-928b-4677-bb10-a9a6085d79f1','7aad6a20-3063-4d2b-88ec-ffb4234a799d','c909d75a-7da3-4679-b360-b68d3d2c38f9','Ryan Sherring','a73b1ee5-a786-5c8d-bbde-6f3fd84f10a2','Donna Robert','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0627180','da853ec8-4d7a-42be-a419-c98a1197ca9d','298efa34-bada-434b-af50-987cb90ded9c','7cdc98c6-a511-487d-a641-1c2b1aeee8ba','Janet Zappone','4eeda961-af9c-587c-a277-32a6d4f02a72','Ernesto Smith','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Palmdale School District
  ('0629580','451800ee-8520-48b8-a13b-bdac15d8d047','f07469f0-2bd6-458f-beba-fbe46c42e692','8a0d4875-70b5-4678-badb-4e1b8caa432c','Claudia Valenzuela','96edb270-97e5-5187-8165-a73125ddecfc','Ralph Velador','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0629580','5397d39a-8aee-48df-8f46-b4786d887373','2cb0993f-ff92-45ea-a152-c1c2a1f1fee9','a6c61934-8f51-44f2-946b-7df4d1ba31d2','Yvonne Ghandchi','9cbad854-899a-57f8-90a0-129d94a45394','Simone Zulu Diol','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0629580','66391b14-6109-4a11-991e-237a0a82a22f','47ff56b1-51f9-42c9-bf52-fe56bb13052d','2376dcb8-0374-49de-b041-88035ed3c9f4','Angela Portillo','01b4cba2-5c61-5cdd-a05f-2dcc12095fca','Anthony Hunt','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0629580','a8d1293a-d399-4085-b0e0-59d77cbe663e','8603ff6b-bde7-42c2-b2a3-2cf2770d78c5','ccf4cf8f-30b7-48ba-a610-07ccd10a6e78','Maria Garcia','af91eaa9-e54b-5020-b476-a1dca7fe1168','Sharon Vega','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0629580','ff919e44-e0b1-4741-ab3d-0d63a87f0f72','90d8b26e-2da8-4ad3-9e2b-71e25859b232','6dab5ac4-59ef-47c3-8b38-9fa416831041','Stephanie Davis','85aa8840-af89-5c69-9e10-5aaceff28bd2','Nancy Smith','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Rosemead School District
  ('0633570','2519c262-33a0-491c-9501-d7febd5bf6c6','77d1a11b-df4f-4f20-a95f-eae6cb23430b','e771a832-0b22-4788-8c40-d314898dfeeb','Sandra Herrera','1a89b575-d545-5ded-ba93-ffbd439eaab4','Nancy Armenta','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0633570','2ef6db4b-6db6-420d-986d-eb217f37771f','75739ab2-dde3-4bdb-81a3-4a17b0d9fdff','ee672e7d-063a-4803-a7cc-96522e2529ab','Teresa Pimentel','5cea1999-7a2b-5791-9e50-f2ea8b108216','Ronald Esquivel','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0633570','7a3428e7-cb67-46a5-9677-233c7b942ac7','2e9f57cf-a24e-44d2-bd14-7febea190a4d','3ed8f158-6f91-4e96-9181-09e4783c010c','Jay Imperial','33d6a647-d1e1-516a-bf84-2806857f86fb','Veronica Pena','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0633570','85f26636-6fd0-4a35-85dc-423218301b4d','1a204190-5f95-4927-a4d0-e3d35f853c36','3548fca1-d0d3-402c-a69b-4292382dc6cf','Tara Ly','a5a53805-85fe-5b01-8990-dcaab536afde','John Quintanilla','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0633570','7527f0d7-7e62-55eb-9b97-fa61bfc3b98b',NULL,NULL,NULL,'dee8de05-2cab-50ca-aecb-0d66360676fd','Diane Benitez','2022-12-01','month','elected',false,'add',NULL,NULL,NULL),
  -- Saugus Union School District
  ('0635970','312d93b8-4f6a-4bbe-a76d-b21fb51c5bf9','d68dc406-c860-4bfc-8214-8f71abc4c0d9','713aba1d-06cc-4631-97b5-de89302df717','Lance Christensen','9c85286e-c5b9-5ac9-9981-ff29bcf9bb34','Matthew Watson','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0635970','662daa30-10af-497e-8910-9a1973125e67','d6d814fb-e57b-457d-9500-1c9b0598e379','b12d15ac-a768-4aca-a4d2-4377eabbab1b','Steve Summy','979cee67-5f7f-4e00-946e-6bd6191e9f20','Katherine Cooper','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0635970','9d264e21-571e-477b-bce5-3ebaa60e4ed8','63bb7eb3-2829-4e31-996e-151f1196795f','c471d672-413b-42ef-862b-2acf76e8c000','Gale Reyes','73441e1a-c37d-507d-bb11-a9e9c07ed0c5','Patti Garibay','2024-12-01','month','elected',true,'replace','unknown','first appointed 2023 (Ballotpedia); then the only filer for the Nov 2024 Trustee Area 1 short term (RR/CC 4324: "Unexpired term ending December 11, 2026")',NULL),
  ('0635970','e2ca6246-1dae-43ed-81a1-e0ea42cdc202','c083db64-aa3f-4910-becf-16912e179449','d6e8aae4-9dca-4594-9caf-03c374092d47','Doree Frome','90b09547-711f-55aa-8e0a-c0eeefe46827','Anna Griese','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0635970','c44b3d8b-18b2-5ff8-9765-4c8d21e28b1a',NULL,NULL,NULL,'e009e833-974a-57ce-a7ee-32bd4f284181','Christopher Trunkey','2022-12-01','month','elected',false,'add',NULL,NULL,NULL),
  -- South Whittier School District
  ('0637560','21bafe9c-c44a-4c43-add7-7d9dd0dc211e','7d6b28ff-73dc-4365-9553-2a920ddd2d3b','b7e2ec3f-d1e8-44c9-94d6-7d89c5daaf54','Santos Garcia','3c06bce9-b009-548d-a695-f783a0a1abfa','Natalia Barajas','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0637560','5af17e10-b7fb-4071-a935-8b12c6e84a87','3d495a41-3190-44ad-ad6a-4b341682fb01','5622c1c2-3ba1-4695-a691-7c564af304d0','Norma Lopez','88c7fe00-467f-54ee-aa7e-ea051112a20a','Elias Alvarado','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0637560','93b3e1ff-33a9-4dcc-8d26-cea444f07334','65d3adbf-eba7-4b98-99d3-02a9c93e5f35','9c4191fc-8460-43ca-9a18-29c4251abba9','Raymond Cazarez','96147ed0-0184-5255-875e-2425508bce20','Sylvia V. Macias','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0637560','974a5638-0aec-4f36-b413-d8dfee2119e9','a59e210c-8f11-49db-badc-9cb6f67b2764','0ae3edf9-e0ce-43b2-8950-3ec5de00e43e','Monica Hernandez','64faacf6-4f6a-59e6-9c30-0461cec53584','Elizabeth Guillen','2025-09-01','month','appointed',false,'replace','unknown','provisional appointment to Trustee Area 1 after Francisco Santana died (Aug 2025); applications closed 2025-08-29 (swhittier.k12.ca.us/162184_3), she is absent from the 2025-09-09 roll call, the 2025-09-16 special meeting agenda (Simbli MID 45050) carries "PROVISIONAL APPOINTMENT" and "OATH OF OFFICE" for Trustee Area 1, and the 2025-10-21 minutes call it her first meeting; the day is not published in the minutes, so precision month',NULL),
  ('0637560','b871fa71-23b3-4eec-8b10-13dad70b131a','b0feb918-01d9-4416-9616-73d7ca85168d','aa99212b-41fc-484a-a7cd-20b65c1ed751','Gloria Ornelas','c45d6990-0775-585e-8afe-21f6500e2557','Jan Baird','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Sulphur Springs Union School District
  ('0638220','1148a626-5f57-4909-821a-00c495523c8f','93e6a9f3-2b7d-4111-b1cb-d1d9b5629f55','1d5c3afc-9614-4090-b083-3458f334a9be','Mary Chadwick','0e75d5f3-de3a-5d99-a3c3-c9559d1f5966','Shelley Weinstein','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0638220','1b70d3d4-d3b6-4aa8-934e-91812be9ff08','ca8c1b81-1353-4cd7-85d7-a7730043ea8d','38066707-6a62-40b8-a749-a94823c58326','Melissa Linton','02c8d4a7-63ee-5965-9b37-121087b67380','Ken Chase','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0638220','2c7f54da-7532-4e50-8e1d-569862aa67d2','18e4f96d-81f6-4cb5-8d39-6652dd3ed0b4','c5a9c6f7-c0f1-477f-b078-23bf17e54709','Danielle Zefferino','8263026b-8e62-5673-b484-6dee1e417215','Denis DeFigueiredo','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0638220','b3349ce4-1d63-439f-be50-eb0ae9eac959','84a04e44-9747-4179-b301-e97248ad717d','265f1d35-3b92-48b3-b68d-fc34b0681f96','Judy Fearing','d7e65bfb-5cb4-545b-a961-3dba3531beaf','Lori MacDonald','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0638220','ec1e490c-6ce7-4b7a-924c-be2fa974cc7a','e1a3ebf5-6aa6-43f1-8de8-9dbf84fa9b34','d46e969c-5a86-4a9f-aa58-6bbc633a2d92','Marty Steckel','a545cd9e-d294-5bef-9a09-b6ce31a39a20','Paola Jellings','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Valle Lindo School District
  ('0640650','51857320-ec95-485e-990e-9892ce099723','83410cb3-f32d-47fe-b740-122ee2c359a2','0e216216-3902-4217-944e-01defde50d1b','Margarita Lopez','f3eb5137-822f-5007-b242-5dd383bc485e','Veronica Lauria','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0640650','572a42ad-7320-4c5d-902c-b9d2e8694e2a','4fe90299-6fd5-43d6-84db-c5354ff3579f','6b5b7342-cb31-4e47-9367-97cc363acd1f','Adela Martinez','58c035bb-582e-529c-a73a-ee4ae2d74532','Jacqueline Rubio','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0640650','59f1b46b-dc9d-40ee-8e6b-2633bb8daa5c','82716934-d814-477c-8a96-076bc5b1c8e9','f1a78f8e-85b9-459c-91b1-0091dc6cfb27','Guillermo Gutierrez','99b82306-74b6-546d-808c-30aa7b757b18','Veronica Castillo','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0640650','9076ca91-7cb2-4e9c-9dae-59f92a5288ad','b8f2be3f-d75b-4767-b2c1-6351baa2f40b','b1078a3e-d578-49a4-a3b9-88e7fc97df2d','Jose Rios','82052a2d-7702-5722-b5ef-b5911af785aa','Ruby Rose Yepez','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0640650','d0bbd636-7ab3-486a-be75-30299ca20319','73a8046c-de36-42c4-b9fb-a45028adfc5f','84bd92c2-dd7a-470a-a6d1-d4b6f4808842','Monica Torres','40f14ef7-a963-5f9d-8724-c2e1369437fc','Rudy Martinez','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Westside Union School District
  ('0642120','00d4c7a1-bc0a-4277-bb7a-e4049466100c','3a3dfcae-a233-49c5-85f7-f0b80f7b0305','a4af047c-985c-4deb-9718-d4bfce2871a0','John Valles','9ee35644-a523-59a0-bc3a-2551d7423e3b','Andrew Rowe','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642120','04a7b55a-c3ef-4c88-ae34-ffc7d9e0a465','ef48daeb-e414-4c4e-86bf-e4642428cfb0','12c889ee-fe4c-4f02-aba8-54f27476ce45','Sandy Derrick','caf0babc-cc93-5e4d-9358-5259f37f0f7a','John Curiel','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642120','9fb32ef4-90c9-4f38-b371-3d821168cc39','95cf0d90-d239-4b39-a20c-575663c09b69','81f85c7b-7abf-4b9e-80f0-38daf0d48fba','Joseph Crawford','0949b0ec-9f4d-526f-a939-5ccb3ff157c5','Christopher Grado','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642120','c61efa65-95cf-4b35-a6bb-2e7f4d4cef41','69396113-1dd8-4986-91a5-4d6d3ffb7398','c3c75a0a-6555-4058-a75f-cd14132c8d7a','Kelly Kizer','33423034-becb-58d2-b1e2-78eb79d6038f','Jennifer Navarro','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642120','ff691b1c-7d46-4051-abc5-6adcc2ab8a9a','2799876e-8cc2-4ca7-aa91-5b4fadac4500','b615a7a7-443f-4490-84a5-040116bd1708','Cassie Thomas','7ec8f79d-3f5b-5596-a72b-ae0e5e07501b','Steve DeMarzio','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  -- Whittier City School District
  ('0642450','29f8892a-3f92-4fce-a4a9-7e1fb40603e9','f8131e92-7564-4ed7-94ce-8ff49df3c7e5','c3dc758d-378f-4867-91c1-00422760ef54','Danny Argueta','f0afac39-cab0-5b7a-84f8-8a3c0ac90e1e','Jennifer De Baca Sandoval','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642450','2f8d919a-3b94-46b9-96cc-a3cc27e075ef','6fa0a0b2-7725-44ce-9950-97018f40d8ed','247a40d7-e641-4e90-9110-67c311c6d3f4','Joe Ramos','1f3c5428-2f6f-5d78-a44e-8351c73b85c9','Richard Hever','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642450','3caeaa85-422a-4559-a0ba-ccaa30ebe3cf','41ffbe71-8d1d-42bc-95d1-3f0d3a3a87d2','7fda4a85-279d-4fa1-b941-dfa98097a3c5','Mary Pinkney','dd13028e-833d-52bf-a0a0-9ee6a6a45621','Elizabeth Leon','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642450','5e48aa34-ecdf-456b-830d-b4c1f522c115','af0e3d64-cb33-4270-a42f-30bb5835e890','fb8d85f1-105d-453b-beda-fed70bde0cac','Felipe Moran','ea58986b-933c-53f6-bfd2-f1e27c86166c','Caro Jauregui','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642450','e54393ad-c9e1-47db-9ca6-e8e1d620af25','cccdf663-7459-450a-8f93-71645cd683d5','242c68a1-7d99-4a0f-83b3-878b145f2522','Monica Ayala','122b6d4c-c851-580e-9b43-fe0e2f96ee80','Linda Small','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  -- Whittier Union High School District
  ('0642480','099677aa-53f4-4714-b408-b82189203bc5','49372c46-fec7-4308-bbdf-fb13fbcb29d4','84c5018c-bd47-41df-8192-64d1ace15712','Jeff Baird','4e444a1b-187f-5f22-8f6e-56508f5237c4','Irma Rodríguez Moisa','2022-12-01','month','elected',false,'replace','term_expired',NULL,'real former trustee (Dec 1997 - Dec 2022): Whittier Daily News 2022-08-21 "in the November 1997 election, challengers Leighton Anderson, Jeff Baird and Alex Morales were elected ... Anderson and Baird have remained on the board, but that changes this fall, with their decision not to seek re-election"; RR/CC 3752 (Nov 2017) lists JEFF BAIRD as elected incumbent; so the term expired in December 2022 (paired with a 2022 successor on this generic seat)'),
  ('0642480','42248683-bf61-4754-a9f0-daabe7f78741','29664d23-452f-41df-b012-be032cd6eddd','5db21599-5f8e-4f08-b2e9-edbeb012add7','Carole Hussey','a8a5def3-8ce6-5a5a-b355-4ca27b94308c','Russell Castañeda Calleros','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642480','5f7f2d2e-d47f-4900-9b56-5cd3526c4483','7d5f878c-8d1c-465c-8e73-16ebfb11b940','228d3acd-75db-44cc-bef9-06f448f94a21','Sergio Garcia','b6f8340c-37a6-486d-97cd-41ab2dcaa477','Jaime Lopez','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642480','709daeb2-6941-45b4-b50e-a2c8b037e6e0','65cdb173-3aed-470d-8b58-f5975cd00ca1','1729fc7b-9a35-4dda-9276-12b6123bc1d8','Joe Torres','83daf8b2-59bb-5513-8ea6-315fdf5cb6a1','Josefina E. Canchola','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642480','fac57bb5-e0e5-4f28-8b9e-2bdcdda4be21','1117100a-77e2-4c42-adec-7483896d9b8e','a2ea72fc-4c80-4e3f-b72b-e584e3c81a7d','Maria Mendez','19a80e5e-8d92-5aca-9b33-5ac57b9f81ca','Armando Urteaga','2026-01-17','day','appointed',false,'replace','unknown','appointed to Trustee Area 5 after Gary Mendez resigned 2025-12-09; Whittier Daily News 2026-02-03: "The appointment was approved at a special board meeting Jan. 17. Urteaga will serve the remainder of the term through November."',NULL),
  -- William S. Hart Union High School District
  ('0642510','76ba2797-ae0e-454a-bff5-2df6d8b3e482','9c1e011c-c80d-484a-b9f2-5c9e2314f2a7','d304c0d7-f0ad-49fd-8252-87e86ca93c53','Bob Jensen','d304c0d7-f0ad-49fd-8252-87e86ca93c53','Bob Jensen',NULL,NULL,NULL,NULL,'keep',NULL,NULL,NULL),
  ('0642510','c4159526-076e-4cb8-9845-b2b1e9f9aab2','5bc35444-869d-430d-954b-209ae592c335','41076964-edd9-4e7b-866f-79680545bb2c','Cherise Moore','41076964-edd9-4e7b-866f-79680545bb2c','Cherise Moore',NULL,NULL,NULL,NULL,'keep',NULL,NULL,NULL),
  ('0642510','d1152eb6-ddeb-4067-bea2-f9d5312c5252','4dde344e-90e2-4b24-91b2-99ea41f5ea8d','4cee37b3-76a5-40f8-ad03-f30be18886aa','Joe Messina','4cee37b3-76a5-40f8-ad03-f30be18886aa','Joe Messina',NULL,NULL,NULL,NULL,'keep',NULL,NULL,NULL),
  ('0642510','f3b3e90c-16dc-48ef-80db-fc191e4b333d','882d703c-2f39-43d6-9e2a-887005ad1df0','f5638f34-de59-4b45-890b-b59414aaf4de','Jim Lecithin','30c5e92b-cbce-581f-94a2-e842a71343c1','Aakash Ahuja','2024-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642510','580a635e-2a11-5aab-a839-c33b47c7c94c',NULL,NULL,NULL,'15f10a3a-07dd-564f-b3e6-7ce593c837e8','Erin Wilson','2024-12-01','month','elected',false,'add',NULL,'first appointed 2023 to Trustee Area 4 (Ballotpedia); then won Nov 2024 (RR/CC 4324 results: Erin Wilson 14,837, Eric Anderson 8,201)',NULL),
  -- Wilsona School District
  ('0642810','4f7c7b15-69b8-4bb7-aef2-fa97c50348a6','cf9acca9-f5df-4af6-8443-fc094ad87dc8','40b39473-5ed1-41b6-85c6-6d1aff569464','Tina Huber','8d7aaefc-1b95-5214-b0b3-371a5f483dea','Daniela Sanchez','2022-12-01','month','elected',false,'replace','unknown',NULL,NULL),
  ('0642810','5cdadc12-668f-4616-85f8-2f244481500c','7d09abab-821e-4da2-94cb-fecae9d0e71b','fce14caa-e78a-4538-ae4f-8657f53430ed','Linda Miller','6cc9f634-de00-5ff6-ae80-7a1dd7699bac','Anne Misicka','2022-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642810','a8c03eb9-665a-41d1-9603-1e3a5546a2a7','b9c8d869-be4d-44b3-87de-28fe544c457f','ceec8e87-b495-4430-ba59-dc202a982ffd','Mike Diaz','21d26b66-89de-55f5-87a0-79098e389d7d','Laura Samano','2024-12-01','month','elected',true,'replace','unknown',NULL,NULL),
  ('0642810','b81d7eff-3327-51e1-8a72-d0f0fa399cc9',NULL,NULL,NULL,'425e83e1-bea3-5f5c-9950-c3923ded40fa','Vladimir Gomez','2024-12-01','month','elected',true,'add',NULL,NULL,NULL),
  ('0642810','2df78c91-3f8b-58cb-bcf2-38120ecebcee',NULL,NULL,NULL,'0acea6a3-2323-5423-a922-f5a71a0e9660','Robert D. Miller','2022-12-01','month','elected',true,'add',NULL,NULL,NULL);

CREATE TEMP TABLE _ca0158_newoff (id uuid PRIMARY KEY, geo_id text, template_id uuid) ON COMMIT DROP;
INSERT INTO _ca0158_newoff VALUES
  ('c348a675-54c7-5b9f-9948-c60e13056f9c','0607920','6245bff0-ee6a-4991-8792-09a35ad63290'),
  ('68b215cd-78fe-5162-845d-230e4e8d6ff4','0611910','01407d0b-414e-4ff4-b09d-30f36442dc6c'),
  ('6e5126e5-1a1c-5960-806e-4a817761ffc1','0617880','05e4d7ac-b5c9-4aee-b95d-dd975004a825'),
  ('3bcc28ec-597e-5d30-b69f-b3b31c946305','0617880','05e4d7ac-b5c9-4aee-b95d-dd975004a825'),
  ('7fe3c13b-7cc4-5e33-8f59-815485de9c17','0617880','05e4d7ac-b5c9-4aee-b95d-dd975004a825'),
  ('7527f0d7-7e62-55eb-9b97-fa61bfc3b98b','0633570','2519c262-33a0-491c-9501-d7febd5bf6c6'),
  ('c44b3d8b-18b2-5ff8-9765-4c8d21e28b1a','0635970','312d93b8-4f6a-4bbe-a76d-b21fb51c5bf9'),
  ('580a635e-2a11-5aab-a839-c33b47c7c94c','0642510','76ba2797-ae0e-454a-bff5-2df6d8b3e482'),
  ('b81d7eff-3327-51e1-8a72-d0f0fa399cc9','0642810','4f7c7b15-69b8-4bb7-aef2-fa97c50348a6'),
  ('2df78c91-3f8b-58cb-bcf2-38120ecebcee','0642810','4f7c7b15-69b8-4bb7-aef2-fa97c50348a6');

-- New people. dup_ok = a DIFFERENT person shares first+last with an active row (duplicate guard bypassed for that row only).
CREATE TEMP TABLE _ca0158_newpol (
  id uuid PRIMARY KEY, geo_id text, full_name text, first_name text, last_name text,
  preferred_name text, alternate_names text[], dup_ok boolean
) ON COMMIT DROP;
INSERT INTO _ca0158_newpol VALUES
  ('6075a347-8818-5ec4-ad08-9a20518aa22b','0602820','Carla Corona','Carla','Corona',NULL,'{}',false),
  ('46a41762-434e-506a-bf5e-c003c3ab828c','0602820','Miguel Sanchez IV','Miguel','Sanchez',NULL,'{"Miguel Sanchez"}',false),
  ('0a16ea62-8589-5fcb-94c9-6d94bbbdc64b','0602820','L. Rosemary Mann','Rosemary','Mann',NULL,'{}',false),
  ('98b2d8bf-08fa-54f4-a70a-405505259804','0602820','Charles Hughes','Charles','Hughes',NULL,'{"Charles F. Hughes"}',false),
  ('02890a06-5e9e-550f-9812-1c2af9992041','0607740','Mayreen Burk','Mayreen','Burk',NULL,'{}',false),
  ('64e9a1d2-539e-5555-9a73-4cdf9c08baaa','0607740','Fred Malcomb','Fred','Malcomb',NULL,'{"Frederick David Malcomb","Frederick D. Malcomb Jr."}',false),
  ('86d8eb68-2c79-5587-a07a-9677d779e8e2','0607740','Erik Richardson','Erik','Richardson',NULL,'{"Erik L. Richardson"}',false),
  ('c8dace65-f8ae-5032-a2b7-4757a821a178','0607740','Laura Pearson','Laura','Pearson',NULL,'{"Laura Lynn Pearson"}',false),
  ('d3243df7-a7b5-5f42-b277-c51b468e303e','0607740','Vincent Titiriga','Vincent','Titiriga',NULL,'{"Vincent Andrew Titiriga"}',false),
  ('1d2f9313-f72f-5595-89a8-f41faa903db9','0607920','Estefany A. Castañeda','Estefany','Castañeda',NULL,'{"Estefany Alejandra Castaneda","Estefany Castaneda"}',false),
  ('fd6ce9a2-b7ef-52cb-8079-5428ad39cdab','0607920','Marisela Ruiz','Marisela','Ruiz',NULL,'{}',false),
  ('9633065b-dfc5-59af-8cdd-49237080a670','0607920','Nohemi Ramirez','Nohemi','Ramirez',NULL,'{"Nohemi G. Ramirez"}',false),
  ('e73183bb-8ab6-5678-8f4b-08aec556c5cb','0611850','Lisa Michelle Dabbs','Lisa','Dabbs',NULL,'{}',false),
  ('d93d9671-cb6f-57b3-af0f-ae594d4d6a46','0611850','Carlos Aparicio','Carlos','Aparicio',NULL,'{}',false),
  ('509804f2-4813-5985-934b-c33e4eb9efbb','0611850','Wendy Carrera','Wendy','Carrera',NULL,'{}',false),
  ('f71bc6eb-b367-52eb-8f5c-e2daf96add10','0611850','Christine Chacon Kennedy','Christine','Kennedy',NULL,'{"Christine Chacon Sullivan"}',false),
  ('4b0e7873-6534-5f9b-be74-db2d055874c6','0611850','Thomas Baird','Thomas','Baird',NULL,'{}',false),
  ('66a52dda-274d-5998-b51a-0bf59b74e11e','0611910','Julie A. Bookman','Julie','Bookman',NULL,'{"Julie Ann Bookman"}',false),
  ('b9479e0b-44fa-5d7e-b6a9-7f9ee87c432d','0611910','Joseph "Joe" Pincetich','Joseph','Pincetich','Joe','{"Joe Pincetich"}',false),
  ('19c3b72e-2b96-5e30-b58f-db7869af2ac7','0611910','Roger L. Price','Roger','Price',NULL,'{}',false),
  ('dfaf5da2-0b31-58b1-8302-8218f4ce8fac','0611910','Shawn Cannon II','Shawn','Cannon',NULL,'{}',false),
  ('5c7c3ea2-02ed-5f35-8651-e7fd7e14deeb','0611910','Wayne Kalliomaa','Wayne','Kalliomaa',NULL,'{"Wayne M. Kalliomaa"}',false),
  ('2da3e36f-45e0-5591-a5ae-ea1dce87c5d0','0612090','Lisette Mendez Garcia','Lisette','Mendez Garcia',NULL,'{"Lisette Idalia Mendez","Lisette Mendez"}',false),
  ('e169f9e9-8f81-52f6-94e1-ecf5f08ebeeb','0612090','Elizabeth "Beth" Rivas','Elizabeth','Rivas','Beth','{"Beth Rivas"}',false),
  ('c2aa3258-95ef-58cb-913c-9cf7db8b55c4','0612090','Jennifer Cobian','Jennifer','Cobian',NULL,'{}',false),
  ('c4d72241-cf6d-5b5b-b3fc-7d2b6e2c8552','0612090','David Siegrist','David','Siegrist',NULL,'{"David Stephen Siegrist","David S. Siegrist"}',false),
  ('254e533d-d131-5b34-9027-99a81f545b88','0612090','Cesar Peralta','Cesar','Peralta',NULL,'{}',false),
  ('5e847174-1790-5c61-8bc6-829da06f507e','0612120','Florencio F. Briones','Florencio','Briones',NULL,'{}',false),
  ('02370bdd-6b74-5814-bc64-a0b38524e23d','0612120','Luis G. Guzman','Luis','Guzman',NULL,'{}',false),
  ('2d6e76cc-b283-5a84-a57d-277d1caf0038','0612120','Maritza C. Galaviz','Maritza','Galaviz',NULL,'{}',false),
  ('2721420f-8032-5e4d-bee4-bc6795ac3b22','0612120','Qui Nguyen','Qui','Nguyen',NULL,'{"Qui D. Nguyen","Qui Dang Nguyen"}',false),
  ('a64f8955-568d-5818-bc85-b95cb179b820','0612120','Ricardo Padilla','Ricardo','Padilla',NULL,'{}',false),
  ('378cba56-08f7-5bba-ba64-22c1f515cfb7','0614940','Andrew J. Yam','Andrew','Yam','Andy','{"Andrew \"Andy\" Yam","Andrew Justin Yam"}',false),
  ('dd2eccee-d3d8-5198-884d-c0758beb3b20','0614940','Ronald Trabanino','Ronald','Trabanino',NULL,'{"Ronald B. Trabanino"}',false),
  ('091e401b-e9cb-5aa1-90db-d76825b662d1','0614940','Maureen Masmela Chin','Maureen','Chin',NULL,'{"Maureen Chin"}',false),
  ('a2021466-0387-5f9c-8dfa-39ac6ae94cdb','0614940','John H. Nuñez','John','Nuñez',NULL,'{"John H. Nunez"}',false),
  ('ada9a7d8-259e-5bbc-be3c-a9c911478e3e','0614940','Paul Duran','Paul','Duran',NULL,'{"Paul M. Duran","Paul Michael Duran"}',false),
  ('f3a53b20-c624-5e4b-98eb-74198f15039b','0615600','Patricia Edwards','Patricia','Edwards',NULL,'{"Patricia A. Edwards"}',false),
  ('970a9d54-7a53-5ca0-add3-d52dc8050e42','0615600','Jen Reyna Abram','Jen','Reyna Abram',NULL,'{}',false),
  ('7859038c-64e3-5192-ad2d-a77562e29a18','0615600','Kelly Bailey','Kelly','Bailey',NULL,'{}',false),
  ('14382e97-4b6f-5ab4-9bc2-2483927ca70e','0616680','Cristina Chiappe','Cristina','Chiappe',NULL,'{}',false),
  ('9fa27bc9-c6a3-5e43-a632-560280f3ae56','0616680','Sergio R. Mortara','Sergio','Mortara',NULL,'{"Sergio Roberto Mortara"}',false),
  ('36ee4568-b12d-58f8-b642-2ea716ce9de3','0616680','Vicente Bravo','Vicente','Bravo',NULL,'{"Vicente P. Bravo"}',false),
  ('54a7eed3-9757-56a8-a493-5cdd4f1370a6','0616680','Luciano Aguilar','Luciano','Aguilar',NULL,'{"Luciano Alfredo Aguilar"}',false),
  ('43667ed4-9a14-5c58-a2ae-d6667f241ba6','0616680','Eugene Krank','Eugene','Krank',NULL,'{"Eugene M. Krank"}',false),
  ('47cc3d78-97f7-5443-91d7-5f039c27028b','0617040','Catherine Barrow','Catherine','Barrow',NULL,'{}',false),
  ('cd6bf6bf-b20a-5cbc-8eab-e5aaea8c73c5','0617040','Carol Reid Kluthe','Carol','Kluthe',NULL,'{"Carol Reid"}',false),
  ('ebe0883c-fca2-5e9a-ac30-c3407e60a27f','0617040','Margaret Bove-LaMonica','Margaret','Bove-LaMonica','Maggie','{"Maggie Bove-LaMonica"}',false),
  ('1a98aa19-6dc0-5a11-8ebd-3a252517f21b','0617040','Jennifer Cole','Jennifer','Cole','Jen','{"Jen Cole"}',false),
  ('092101cb-2998-5321-bc38-21d215a3f24b','0617040','Rachel VanLandingham','Rachel','VanLandingham',NULL,'{"Rachel E. VanLandingham"}',false),
  ('33587b77-1b7d-5c6b-ae0f-f811932a027a','0617880','Terri Moss','Terri','Moss',NULL,'{}',false),
  ('e4685a86-a0a7-5f9f-8a3d-53cf1865ab1e','0617880','Raelyn Marshall','Raelyn','Marshall',NULL,'{}',false),
  ('b93aaae3-4771-537f-b145-bce88f0e8dd5','0617880','Jim Wall','Jim','Wall',NULL,'{}',false),
  ('51ee7915-914c-5d80-9988-a23691de7dda','0617880','Stephanie Lewis','Stephanie','Lewis',NULL,'{}',false),
  ('40829ed9-4fed-5563-83b9-87750b90777f','0617880','Lola Skelton','Lola','Skelton',NULL,'{}',false),
  ('c8730086-8ef0-586d-9b72-4c0a791edf3c','0619440','Blanca Nava','Blanca','Nava',NULL,'{}',false),
  ('7d6c98b7-a053-55ec-b206-5fdd9d29bebd','0619440','Andrew Ramirez','Andrew','Ramirez',NULL,'{"Andrew Steven Ramirez"}',false),
  ('e1b27b2b-f039-5e7c-b2b1-9668e37963e7','0619440','Alma Rodriguez','Alma','Rodriguez',NULL,'{"Alma I. Rodriguez"}',false),
  ('69e3d7f9-e368-5ea1-ad74-2e707cdfd233','0619440','Lisa Klee','Lisa','Klee',NULL,'{}',false),
  ('766834d5-e806-52b9-8702-b5e243e21ed8','0619440','Felicity Teff','Felicity','Teff',NULL,'{}',false),
  ('d34d8972-b563-5aef-bb04-1d3161698faa','0620880','Greg Tepe','Greg','Tepe',NULL,'{}',false),
  ('dfa37b57-a204-5db8-9010-d68a773807fb','0620880','Keith Giles','Keith','Giles',NULL,'{}',false),
  ('ca090dea-fe42-598d-b90d-1cf441b83bf1','0620880','Jullie Eutsler','Jullie','Eutsler',NULL,'{"Jullie A. Eutsler"}',false),
  ('a47b7e2f-241c-500c-9f2e-2919ae63010a','0620880','Duane Winn','Duane','Winn',NULL,'{"Duane G. Winn"}',false),
  ('ee16f7ef-91ae-5e3e-90db-168c8e679d62','0620880','Pamela Starlson','Pamela','Starlson',NULL,'{}',false),
  ('080c8e8c-4d3f-53c6-b101-7f57a780d0bf','0621210','Cathy Burris','Cathy','Burris',NULL,'{}',false),
  ('41c5f927-42c8-5310-b7ac-c17634ca5b19','0621210','Bonnie J. Coronado','Bonnie','Coronado',NULL,'{}',false),
  ('1275ebdd-c7ab-5b41-8932-143ada0bb53e','0621210','Ann M. Phillips','Ann','Phillips',NULL,'{}',false),
  ('6257be6e-b8c4-50be-8aa9-d825d778c0a2','0621210','Shirley Rudolph','Shirley','Rudolph',NULL,'{}',false),
  ('7cf4f305-0105-5a66-8ea6-6714424cc23d','0621210','Adim Morales','Adim','Morales',NULL,'{}',false),
  ('1baf211d-d0c6-5447-9abf-fb97442a2e73','0621420','Angeles Gonzalez','Angeles','Gonzalez',NULL,'{"Maria de los Angeles Gonzalez"}',false),
  ('ac5d3733-1925-5de1-a2b5-3385385185ff','0621420','Karina Cordero','Karina','Cordero',NULL,'{}',false),
  ('e35d9352-c929-553c-bfde-4e1994cb2c10','0621420','Angela Fajardo','Angela','Fajardo',NULL,'{"Angela C. Fajardo"}',false),
  ('9c217f95-ba7f-5f01-84c8-289c8b16281d','0621420','Julio C. Vargas','Julio','Vargas',NULL,'{"Julio Cesar Vargas"}',false),
  ('92db81fd-0ef1-5b1f-aa9f-7f4b1c57474d','0621930','Jasmine Sanchez','Jasmine','Sanchez',NULL,'{"Jasmine E. Sanchez"}',false),
  ('683a42f2-4fbd-53b5-88f7-0214c0347acc','0621930','Hilda Zamora','Hilda','Zamora',NULL,'{"Hilda A. Zamora"}',false),
  ('aa4efe30-541b-55e8-84fe-802376088173','0621930','Lisa Chavarria','Lisa','Chavarria',NULL,'{}',false),
  ('55ea6eb6-100c-5dc0-ae78-cb251a8f4e0e','0621930','Manuel Cantu','Manuel','Cantu',NULL,'{"Manuel F. Cantu"}',false),
  ('81917154-ced7-5743-8d63-f2ecfb15c29d','0621930','Gina Almanza-Ramirez','Gina','Almanza-Ramirez',NULL,'{"Gina Ramirez","Gina L. Almanza-Ramirez"}',false),
  ('b39ba0bd-c8f8-5c52-ad58-794c9a875ac0','0622890','Maritza Nieves','Maritza','Nieves',NULL,'{}',false),
  ('e9e76dc1-89b2-5022-9673-2324f398c892','0622890','Emilio Sosa','Emilio','Sosa',NULL,'{}',false),
  ('2340b80f-7e56-509a-a787-8bd5ee332293','0622890','Edith Marcel','Edith','Marcel',NULL,'{}',false),
  ('de280cd0-7351-5719-91be-8b372e3d1dd9','0622890','Catherine Martinez','Catherine','Martinez','Cathy','{"Catherine (Cathy) Martinez","Cathy Martinez"}',false),
  ('3a463055-4b42-503b-b7cb-ce116cc9ceb5','0622890','Evelyn Avdalyan','Evelyn','Avdalyan',NULL,'{"Evelyn Mendez Avdalyan"}',false),
  ('641c4da7-9ff4-5003-a7cc-a581d0948ff9','0626190','Jacqueline Saldaña','Jacqueline','Saldaña',NULL,'{"Jacqueline Saldana"}',false),
  ('c3f6a27c-8462-5ddf-bbea-9000e33a3ce2','0626190','Adam Carranza','Adam','Carranza',NULL,'{"Adam C. Carranza"}',false),
  ('71ba46a1-2bb4-5864-94d6-4547969b7fe3','0626190','Veronica Sifuentes','Veronica','Sifuentes',NULL,'{}',false),
  ('2fd1dcb3-07dc-5960-a7cc-431fd32bf031','0626190','Christian Diaz','Christian','Diaz',NULL,'{}',false),
  ('3ae27906-e072-532a-86a8-c73c2654ed08','0627180','Rachelle Haddoak','Rachelle','Haddoak',NULL,'{}',false),
  ('e0e73c33-420f-595a-ac95-de66ef20db1c','0627180','Isaiah Talley','Isaiah','Talley',NULL,'{}',false),
  ('a73b1ee5-a786-5c8d-bbde-6f3fd84f10a2','0627180','Donna Robert','Donna','Robert',NULL,'{"Donna Michelle Robert"}',false),
  ('4eeda961-af9c-587c-a277-32a6d4f02a72','0627180','Ernesto Smith','Ernesto','Smith',NULL,'{"Ernesto A. Smith"}',false),
  ('96edb270-97e5-5187-8165-a73125ddecfc','0629580','Ralph Velador','Ralph','Velador',NULL,'{}',false),
  ('9cbad854-899a-57f8-90a0-129d94a45394','0629580','Simone Zulu Diol','Simone','Zulu Diol',NULL,'{"Simone Zulu","Simone N. Zulu"}',false),
  ('01b4cba2-5c61-5cdd-a05f-2dcc12095fca','0629580','Anthony Hunt','Anthony','Hunt',NULL,'{"Anthony L. Hunt"}',false),
  ('af91eaa9-e54b-5020-b476-a1dca7fe1168','0629580','Sharon Vega','Sharon','Vega',NULL,'{}',false),
  ('85aa8840-af89-5c69-9e10-5aaceff28bd2','0629580','Nancy Smith','Nancy','Smith',NULL,'{"Nancy K. Smith"}',false),
  ('1a89b575-d545-5ded-ba93-ffbd439eaab4','0633570','Nancy Armenta','Nancy','Armenta',NULL,'{}',false),
  ('5cea1999-7a2b-5791-9e50-f2ea8b108216','0633570','Ronald Esquivel','Ronald','Esquivel','Ron','{"Ron Esquivel"}',false),
  ('33d6a647-d1e1-516a-bf84-2806857f86fb','0633570','Veronica Pena','Veronica','Pena',NULL,'{}',false),
  ('a5a53805-85fe-5b01-8990-dcaab536afde','0633570','John Quintanilla','John','Quintanilla',NULL,'{}',false),
  ('dee8de05-2cab-50ca-aecb-0d66360676fd','0633570','Diane Benitez','Diane','Benitez',NULL,'{}',false),
  ('9c85286e-c5b9-5ac9-9981-ff29bcf9bb34','0635970','Matthew Watson','Matthew','Watson',NULL,'{}',false),
  ('73441e1a-c37d-507d-bb11-a9e9c07ed0c5','0635970','Patti Garibay','Patricia','Garibay','Patti','{"Patricia Garibay"}',false),
  ('90b09547-711f-55aa-8e0a-c0eeefe46827','0635970','Anna Griese','Anna','Griese',NULL,'{}',false),
  ('e009e833-974a-57ce-a7ee-32bd4f284181','0635970','Christopher Trunkey','Christopher','Trunkey',NULL,'{}',false),
  ('3c06bce9-b009-548d-a695-f783a0a1abfa','0637560','Natalia Barajas','Natalia','Barajas',NULL,'{}',false),
  ('88c7fe00-467f-54ee-aa7e-ea051112a20a','0637560','Elias Alvarado','Elias','Alvarado',NULL,'{}',false),
  ('96147ed0-0184-5255-875e-2425508bce20','0637560','Sylvia V. Macias','Sylvia','Macias',NULL,'{}',false),
  ('64faacf6-4f6a-59e6-9c30-0461cec53584','0637560','Elizabeth Guillen','Elizabeth','Guillen',NULL,'{}',false),
  ('c45d6990-0775-585e-8afe-21f6500e2557','0637560','Jan Baird','Jan','Baird',NULL,'{}',false),
  ('0e75d5f3-de3a-5d99-a3c3-c9559d1f5966','0638220','Shelley Weinstein','Rochelle','Weinstein','Shelley','{"Rochelle \"Shelley\" Weinstein"}',false),
  ('02c8d4a7-63ee-5965-9b37-121087b67380','0638220','Ken Chase','Ken','Chase',NULL,'{}',false),
  ('8263026b-8e62-5673-b484-6dee1e417215','0638220','Denis DeFigueiredo','Denis','DeFigueiredo',NULL,'{"Denis F. DeFigueiredo","Denis De Figueiredo"}',false),
  ('d7e65bfb-5cb4-545b-a961-3dba3531beaf','0638220','Lori MacDonald','Lori','MacDonald',NULL,'{}',false),
  ('a545cd9e-d294-5bef-9a09-b6ce31a39a20','0638220','Paola Jellings','Paola','Jellings',NULL,'{"Paola Trinidad Jellings"}',false),
  ('f3eb5137-822f-5007-b242-5dd383bc485e','0640650','Veronica Lauria','Veronica','Lauria',NULL,'{}',false),
  ('58c035bb-582e-529c-a73a-ee4ae2d74532','0640650','Jacqueline Rubio','Jacqueline','Rubio',NULL,'{"Jacqueline J. Rubio"}',false),
  ('99b82306-74b6-546d-808c-30aa7b757b18','0640650','Veronica Castillo','Veronica','Castillo',NULL,'{}',false),
  ('82052a2d-7702-5722-b5ef-b5911af785aa','0640650','Ruby Rose Yepez','Ruby','Yepez',NULL,'{}',false),
  ('40f14ef7-a963-5f9d-8724-c2e1369437fc','0640650','Rudy Martinez','Rudy','Martinez',NULL,'{"Rudy T. Martinez"}',false),
  ('9ee35644-a523-59a0-bc3a-2551d7423e3b','0642120','Andrew Rowe','Andrew','Rowe',NULL,'{"Andrew J. Rowe"}',false),
  ('caf0babc-cc93-5e4d-9358-5259f37f0f7a','0642120','John Curiel','John','Curiel',NULL,'{"John Kenneth Curiel","John K. Curiel"}',false),
  ('0949b0ec-9f4d-526f-a939-5ccb3ff157c5','0642120','Christopher Grado','Christopher','Grado','Chris','{"Chris Grado"}',false),
  ('33423034-becb-58d2-b1e2-78eb79d6038f','0642120','Jennifer Navarro','Jennifer','Navarro',NULL,'{}',false),
  ('7ec8f79d-3f5b-5596-a72b-ae0e5e07501b','0642120','Steve DeMarzio','Steve','DeMarzio',NULL,'{"Steven Peter De Marzio","Steven P. DeMarzio"}',false),
  ('f0afac39-cab0-5b7a-84f8-8a3c0ac90e1e','0642450','Jennifer De Baca Sandoval','Jennifer','De Baca Sandoval',NULL,'{}',false),
  ('1f3c5428-2f6f-5d78-a44e-8351c73b85c9','0642450','Richard Hever','Richard','Hever','Rick','{"Richard John Hever","Richard (Rick) Hever"}',false),
  ('dd13028e-833d-52bf-a0a0-9ee6a6a45621','0642450','Elizabeth Leon','Elizabeth','Leon',NULL,'{}',false),
  ('ea58986b-933c-53f6-bfd2-f1e27c86166c','0642450','Caro Jauregui','Caro','Jauregui',NULL,'{}',false),
  ('122b6d4c-c851-580e-9b43-fe0e2f96ee80','0642450','Linda Small','Linda','Small',NULL,'{"Linda Lee Ann Small","Linda L. Small"}',false),
  ('4e444a1b-187f-5f22-8f6e-56508f5237c4','0642480','Irma Rodríguez Moisa','Irma','Rodríguez Moisa',NULL,'{"Irma Rodriguez Moisa"}',false),
  ('a8a5def3-8ce6-5a5a-b355-4ca27b94308c','0642480','Russell Castañeda Calleros','Russell','Castañeda Calleros',NULL,'{"Russell A. Castañeda Calleros","Russell Castaneda Calleros"}',false),
  ('83daf8b2-59bb-5513-8ea6-315fdf5cb6a1','0642480','Josefina E. Canchola','Josefina','Canchola',NULL,'{"Josefina Elizabeth Canchola"}',false),
  ('19a80e5e-8d92-5aca-9b33-5ac57b9f81ca','0642480','Armando Urteaga','Armando','Urteaga',NULL,'{}',false),
  ('30c5e92b-cbce-581f-94a2-e842a71343c1','0642510','Aakash Ahuja','Aakash','Ahuja',NULL,'{}',false),
  ('15f10a3a-07dd-564f-b3e6-7ce593c837e8','0642510','Erin Wilson','Erin','Wilson',NULL,'{}',false),
  ('8d7aaefc-1b95-5214-b0b3-371a5f483dea','0642810','Daniela Sanchez','Daniela','Sanchez','Dani','{"Daniela \"Dani\" Sanchez"}',false),
  ('6cc9f634-de00-5ff6-ae80-7a1dd7699bac','0642810','Anne Misicka','Anne','Misicka',NULL,'{"Anne E. Misicka"}',false),
  ('21d26b66-89de-55f5-87a0-79098e389d7d','0642810','Laura Samano','Laura','Samano',NULL,'{"Laura Christine Samano"}',false),
  ('425e83e1-bea3-5f5c-9950-c3923ded40fa','0642810','Vladimir Gomez','Vladimir','Gomez',NULL,'{}',false),
  ('0acea6a3-2323-5423-a922-f5a71a0e9660','0642810','Robert D. Miller','Robert','Miller',NULL,'{"Robert Miller"}',true);

-- Reused rows (confirmed LA County NetFile committee rows); ballot-name variants added.
CREATE TEMP TABLE _ca0158_reused (id uuid PRIMARY KEY, geo_id text, name text, add_alternate text[]) ON COMMIT DROP;
INSERT INTO _ca0158_reused VALUES
  ('00482c08-b86e-4a7c-b5b8-27c9038f8fb5','0602820','Cynthia R. Hernandez','{"Cynthia R. Hernandez","Cynthia Rachel Hernandez"}'),
  ('148e431d-7313-47cc-ae4f-aadba0f7f33e','0607920','Hugo M. Rojas II','{"Hugo M. Rojas II","Hugo M. Rojas"}'),
  ('60513074-ebf1-4bd9-8a46-4feee43fcff6','0607920','Gloria A. Ramos','{"Gloria A. Ramos"}'),
  ('02367a28-601c-402a-94d0-9a5552d8c0b1','0621420','Marisol Cruz','{}'),
  ('be76a99b-a702-4318-9efd-a9e9e4790193','0626190','Cindy Wu','{}'),
  ('a70b8120-b081-4826-8c6a-40bdd6229843','0627180','Suzan T. Solomon','{"Suzan T. Solomon","Sue Solomon"}'),
  ('979cee67-5f7f-4e00-946e-6bd6191e9f20','0635970','Katherine Cooper','{}'),
  ('b6f8340c-37a6-486d-97cd-41ab2dcaa477','0642480','Jaime Lopez','{}');

-- Seats vacated after the seated member resigned (vacate_office: first vacant day).
CREATE TEMP TABLE _ca0158_vac (office_id uuid, politician_id uuid, name text, first_vacant_day date, how_ended text, evidence text) ON COMMIT DROP;
INSERT INTO _ca0158_vac VALUES
  ('ba0547da-8034-4e08-a0eb-63ee861e7457','9c217f95-ba7f-5f01-84c8-289c8b16281d','Julio C. Vargas','2026-08-31','resigned','Lennox SD minutes 2026-08-11 (Simbli, meeting 75046): Superintendent Tavitian "recognized Board Clerk Julio Cesar Vargas for his service ... from 2022 to 2026 and announced his resignation, effective August 31, 2026 ... the vacant seat will not be filled before the election"; first vacant day taken as the effective date'),
  ('be269633-0bb3-4d19-a57e-9e5226dba12c','81917154-ced7-5743-8d63-f2ecfb15c29d','Gina Almanza-Ramirez','2026-05-11','resigned','Little Lake City SD minutes 2026-05-12 (Simbli, meeting 65979): "It was announced during the meeting that Ms. Ramirez resigned form her position on the Board of education on 5/11/2026"; the TA5 remainder is on the Nov 2026 ballot (RR/CC 4348 special election, "Unexpired term ending December 12, 2028")');

-- ─── Pre-flight: derive-then-verify every identifier ─────────────────────────────────────────────
DO $$
DECLARE v_n int; v_added int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0158_seat;
  IF v_n <> 153 THEN RAISE EXCEPTION 'PRE: seat map has % rows, expected 153', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_seat WHERE action = 'replace';
  IF v_n <> 140 THEN RAISE EXCEPTION 'PRE: % replace rows, expected 140', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_seat WHERE action = 'add';
  IF v_n <> 10 THEN RAISE EXCEPTION 'PRE: % add rows, expected 10', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_seat WHERE action = 'keep';
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % keep rows, expected 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_district;
  IF v_n <> 31 THEN RAISE EXCEPTION 'PRE: % districts, expected 31', v_n; END IF;
  SELECT count(*) INTO v_n FROM (SELECT geo_id FROM _ca0158_seat GROUP BY geo_id) x
    JOIN _ca0158_district d USING (geo_id)
   WHERE d.seats <> (SELECT count(*) FROM _ca0158_seat s WHERE s.geo_id = d.geo_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % district seat counts disagree with the seat map', v_n; END IF;

  -- a re-run finds the 10 added offices already present; a first run finds none
  SELECT count(*) INTO v_added FROM essentials.offices WHERE id IN (SELECT id FROM _ca0158_newoff);
  IF v_added NOT IN (0, 10) THEN RAISE EXCEPTION 'PRE: % of 10 added offices exist (partial earlier run?)', v_added; END IF;

  -- each district is ONE SCHOOL row whose existing offices are exactly the recorded 'Board Member' seats
  SELECT count(*) INTO v_n FROM _ca0158_district x
   WHERE (SELECT count(*) FROM essentials.districts d WHERE d.geo_id = x.geo_id AND d.district_type = 'SCHOOL') <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % district(s) do not resolve to exactly one SCHOOL row', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_seat s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = s.geo_id AND d.district_type = 'SCHOOL' AND o.title = 'Board Member';
  IF v_n <> 143 + v_added THEN RAISE EXCEPTION 'PRE: % seat offices resolve to their SCHOOL district, expected %', v_n, 143 + v_added; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'SCHOOL' AND d.geo_id IN (SELECT geo_id FROM _ca0158_district);
  IF v_n <> 143 + v_added THEN RAISE EXCEPTION 'PRE: the 31 districts hold % offices, expected %', v_n, 143 + v_added; END IF;
  SELECT count(*) INTO v_n FROM _ca0158_newoff n JOIN essentials.offices o ON o.id = n.template_id
    JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = n.geo_id;
  IF v_n <> 10 THEN RAISE EXCEPTION 'PRE: % of 10 template offices are seats of the same district', v_n; END IF;

  -- no race references any of these seats (adding/re-seating cannot move a race)
  SELECT count(*) INTO v_n FROM essentials.races r WHERE r.office_id IN (SELECT office_id FROM _ca0158_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race(s) reference these seats', v_n; END IF;

  -- every stale term is (id, office, politician, name) as recorded, the scraped placeholder, and open --
  -- or closed by THIS file, or archived by CA_0159 after this file ran
  SELECT count(*) INTO v_n FROM _ca0158_seat s
   WHERE s.action IN ('replace','keep')
     AND ( EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.politicians p ON p.id = t.politician_id
                    WHERE t.id = s.stale_term_id AND t.office_id = s.office_id AND t.politician_id = s.stale_pol_id
                      AND p.full_name = s.stale_name AND p.source = 'scraped'
                      AND p.data_source LIKE 'https://empowered.vote/school-district/%'
                      AND t.term_start IS NULL
                      AND (t.term_end IS NULL
                           OR (s.action = 'replace' AND t.term_end = s.term_start - 1 AND t.source LIKE '%| closed CA_0158%')))
        OR EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed a
                    WHERE a.id = s.stale_term_id AND a.reason LIKE 'CA_0159%'));
  IF v_n <> 143 THEN RAISE EXCEPTION 'PRE: % of 143 stale terms match the recorded (id, office, politician, name)', v_n; END IF;

  -- the 143 are exactly the placeholder population of these boards
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.data_source LIKE 'https://empowered.vote/school-district/%' AND p.data_source NOT LIKE '%unified'
     AND p.id NOT IN (SELECT stale_pol_id FROM _ca0158_seat WHERE stale_pol_id IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % placeholder elementary/high row(s) are not in the seat map', v_n; END IF;

  -- a closed stale row must hold no stance data (nothing to orphan)
  SELECT count(*) INTO v_n FROM inform.politician_answers a WHERE a.politician_id IN (SELECT stale_pol_id FROM _ca0158_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % stance answers', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c WHERE c.politician_id IN (SELECT stale_pol_id FROM _ca0158_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % politician_context rows', v_n; END IF;

  -- no stale holder sits on any other office (closing this term must not unseat something else)
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT stale_pol_id FROM _ca0158_seat)
     AND t.id NOT IN (SELECT stale_term_id FROM _ca0158_seat WHERE stale_term_id IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders hold % other office_terms', v_n; END IF;

  -- the three kept Hart holders are the recorded people
  SELECT count(*) INTO v_n FROM _ca0158_seat s JOIN essentials.politicians p ON p.id = s.new_pol_id
   WHERE s.action = 'keep' AND s.geo_id = '0642510' AND p.full_name IN ('Bob Jensen','Cherise Moore','Joe Messina');
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 kept Hart holders match', v_n; END IF;

  -- reused rows: the recorded people, confirmed NetFile committees, and no term except this file's
  SELECT count(*) INTO v_n FROM _ca0158_reused r JOIN essentials.politicians p ON p.id = r.id
   WHERE p.full_name IN (r.name, 'Area 3 Katherine Cooper For Saugus School Board 2024')
      OR (r.name = 'Hugo M. Rojas II'      AND p.full_name = 'Hugo Rojas')
      OR (r.name = 'Gloria A. Ramos'       AND p.full_name = 'Gloria Ramos')
      OR (r.name = 'Suzan T. Solomon'      AND p.full_name = 'Suzan Solomon')
      OR (r.name = 'Cynthia R. Hernandez'  AND p.full_name = 'Cynthia Hernandez');
  IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: % of 8 reused politician rows match', v_n; END IF;
  SELECT count(DISTINCT ps.essentials_politician_id) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system = 'la_county_netfile' AND ps.research_status = 'confirmed'
     AND ps.essentials_politician_id IN (SELECT id FROM _ca0158_reused);
  IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: % of 8 reused rows carry a confirmed NetFile committee', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT id FROM _ca0158_reused) AND t.source NOT LIKE 'CA_0158:%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: reused rows hold % unexpected office_terms', v_n; END IF;

  -- new ids are free, or were created by this file
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id IN (SELECT id FROM _ca0158_newpol) AND p.source IS DISTINCT FROM 'CA_0158_la_elem_high_board_rosters';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % new politician id(s) already used by another row', v_n; END IF;

  -- the only first+last collision with an ACTIVE row is the recorded different person
  SELECT count(*) INTO v_n FROM _ca0158_newpol n
   WHERE NOT n.dup_ok
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians x WHERE x.id = n.id)
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE p.is_active AND lower(btrim(p.first_name)) = lower(n.first_name)
                    AND lower(btrim(p.last_name)) = lower(n.last_name));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % new row(s) collide with an active namesake (decide: same person or not)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '6b95b80c-22bd-4176-8346-4c5459b5a090' AND p.full_name = 'Robert N. Miller';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the recorded namesake 6b95b80c (Robert N. Miller, Racine County) is not as recorded'; END IF;
END $$;

-- ─── 1. Added seats (copies of a seat of the same district) ──────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
   faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT n.id, o.chamber_id, o.district_id, o.title, o.representing_state, o.representing_city, o.description, o.seats,
       o.normalized_position_name, o.partisan_type, o.salary, o.is_appointed_position, false, NULL,
       o.faces_retention_vote, o.role_canonical, o.voting_powers, o.representation_note
  FROM _ca0158_newoff n JOIN essentials.offices o ON o.id = n.template_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices x WHERE x.id = n.id);

-- ─── 2. New politician rows (142) ─────────────────────────────────────────────────────────────────
-- NOT EXISTS rather than ON CONFLICT: the BEFORE INSERT duplicate guard fires before a conflict is seen.
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, preferred_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.alternate_names,
       true, false, n.id NOT IN (SELECT politician_id FROM _ca0158_vac), NULL, d.board_url,
       'CA_0158_la_elem_high_board_rosters'
  FROM _ca0158_newpol n JOIN _ca0158_district d ON d.geo_id = n.geo_id
 WHERE NOT n.dup_ok
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians x WHERE x.id = n.id);

-- A genuinely different person with an active namesake (§G): bypass the guard for this insert only.
SELECT set_config('essentials.allow_duplicate_name', 'on', true);
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, preferred_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.alternate_names,
       true, false, true, NULL, d.board_url, 'CA_0158_la_elem_high_board_rosters'
  FROM _ca0158_newpol n JOIN _ca0158_district d ON d.geo_id = n.geo_id
 WHERE n.dup_ok
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians x WHERE x.id = n.id);
SELECT set_config('essentials.allow_duplicate_name', 'off', true);

-- ─── 3. Reused and kept rows: seated -> incumbent, no stored party ───────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = true, party = NULL, data_source = COALESCE(p.data_source, d.board_url),
       alternate_names = ARRAY(SELECT DISTINCT unnest(p.alternate_names || r.add_alternate))
  FROM _ca0158_reused r JOIN _ca0158_district d ON d.geo_id = r.geo_id
 WHERE p.id = r.id
   AND (p.is_incumbent IS DISTINCT FROM true OR p.party IS NOT NULL OR p.data_source IS NULL
        OR NOT p.alternate_names @> r.add_alternate);

UPDATE essentials.politicians
   SET full_name = 'Katherine Cooper', first_name = 'Katherine', last_name = 'Cooper'
 WHERE id = '979cee67-5f7f-4e00-946e-6bd6191e9f20'
   AND full_name = 'Area 3 Katherine Cooper For Saugus School Board 2024' AND NOT full_name_manual_override;

UPDATE essentials.politicians p
   SET party = NULL, is_incumbent = true
 WHERE p.id IN (SELECT new_pol_id FROM _ca0158_seat WHERE action = 'keep')
   AND (p.party IS NOT NULL OR NOT p.is_incumbent);

-- ─── 4. Tag the 140 stale terms before they are closed (operator decision §B) ────────────────────
UPDATE essentials.office_terms t
   SET source = t.source || ' | closed CA_0158 (2026-09-22): holder is not on the verified current '
                || d.name || ' board (' || d.board_url || '); '
                || COALESCE(s.stale_evidence,
                            'actual last day NOT researched -- term_end is the day before the successor on this generic seat took office')
  FROM _ca0158_seat s JOIN _ca0158_district d ON d.geo_id = s.geo_id
 WHERE t.id = s.stale_term_id
   AND s.action = 'replace'
   AND t.term_end IS NULL
   AND t.source NOT LIKE '%| closed CA_0158%';

-- ─── 5. Seat the 150 members (140 replacements + 10 added seats) -- two-step via seat_officeholder ─
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT s.office_id, s.new_pol_id, s.term_start, s.how_started, s.start_precision, COALESCE(s.how_ended, 'unknown') AS how_ended_prev,
           'CA_0158: ' || d.name || ' board roster, ' || d.board_url || ' (read 2026-09-22); '
           || CASE WHEN s.how_started = 'appointed' THEN s.evidence
                   ELSE 'current term won Nov ' || extract(year FROM s.term_start)::int
                        || ' per LA County RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id='
                        || CASE extract(year FROM s.term_start)::int WHEN 2022 THEN '4300' ELSE '4324' END
                        || CASE WHEN s.in_lieu THEN ' (uncontested; appointed in lieu of election, Elec. Code 10515)' ELSE '' END
                        || '; term begins December ' || extract(year FROM s.term_start)::int || ' (Ed. Code 5017), month precision'
                        || COALESCE('; ' || s.evidence, '')
              END
           || CASE WHEN s.action = 'add' THEN '; seated on a seat added by CA_0158 (the DB had fewer seats than the board)' ELSE '' END
           AS src
      FROM _ca0158_seat s JOIN _ca0158_district d ON d.geo_id = s.geo_id
     WHERE s.action IN ('replace','add')
     ORDER BY s.geo_id, s.office_id
  LOOP
    PERFORM essentials.seat_officeholder(r.office_id, r.new_pol_id, r.term_start, r.src,
                                         r.how_started, r.start_precision, r.how_ended_prev);
  END LOOP;
END $$;

-- ─── 6. The two seats vacated by resignation (§F) ────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM _ca0158_vac LOOP
    PERFORM essentials.vacate_office(r.office_id, r.first_vacant_day, 'CA_0158: ' || r.evidence, r.how_ended);
  END LOOP;
END $$;

-- ─── 7. Stale holders are no longer incumbents (only where they hold no current seat) ────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.id IN (SELECT stale_pol_id FROM _ca0158_seat WHERE action = 'replace')
   AND p.is_incumbent
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  -- every non-vacated seat's current holder is exactly the intended member (148 re-seated + 3 kept)
  SELECT count(*) INTO v_n FROM _ca0158_seat s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id AND och.politician_id = s.new_pol_id
   WHERE s.office_id NOT IN (SELECT office_id FROM _ca0158_vac);
  IF v_n <> 151 THEN RAISE EXCEPTION 'POST: % of 151 seats resolve to the intended current member', v_n; END IF;

  -- the two vacated seats: no current holder, flagged vacant from the sourced day, member closed the day before
  SELECT count(*) INTO v_n FROM _ca0158_vac v
    JOIN essentials.offices o ON o.id = v.office_id AND o.is_vacant AND o.vacant_since::date = v.first_vacant_day
    JOIN essentials.office_terms t ON t.office_id = v.office_id AND t.politician_id = v.politician_id
                                  AND t.term_end = v.first_vacant_day - 1 AND t.how_ended = v.how_ended
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = v.office_id AND och.politician_id IS NOT NULL);  -- the view keeps a NULL-holder row for a vacant seat
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 vacated seats are closed and flagged as intended', v_n; END IF;

  -- per district: the right number of offices and of distinct active incumbent holders; nothing else vacant
  SELECT count(*) INTO v_bad FROM (
    SELECT x.geo_id, x.seats
      FROM _ca0158_district x
      JOIN essentials.districts d ON d.geo_id = x.geo_id AND d.district_type = 'SCHOOL'
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
     GROUP BY x.geo_id, x.seats
    HAVING count(DISTINCT o.id) <> x.seats
        OR count(DISTINCT p.id) <> x.seats - (SELECT count(*) FROM _ca0158_vac v JOIN _ca0158_seat s ON s.office_id = v.office_id WHERE s.geo_id = x.geo_id)
        OR bool_or(o.is_vacant AND o.id NOT IN (SELECT office_id FROM _ca0158_vac))) z;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) do not show the expected active incumbent holders', v_bad; END IF;

  -- seated people: no stored party; each current one holds exactly one current seat
  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT new_pol_id FROM _ca0158_seat) AND p.party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) carry a stored party', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     WHERE och.politician_id IN (SELECT new_pol_id FROM _ca0158_seat)
     GROUP BY 1 HAVING count(*) <> 1) z;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) hold <> 1 current seat', v_bad; END IF;

  -- new terms: the intended start, precision and how_started; open unless vacated
  SELECT count(*) INTO v_n FROM _ca0158_seat s JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.politician_id = s.new_pol_id
   WHERE s.action IN ('replace','add')
     AND t.term_start = s.term_start AND t.start_precision = s.start_precision AND t.how_started = s.how_started
     AND t.source LIKE 'CA_0158:%'
     AND (t.term_end IS NULL OR s.office_id IN (SELECT office_id FROM _ca0158_vac));
  IF v_n <> 150 THEN RAISE EXCEPTION 'POST: % of 150 new terms have the expected shape', v_n; END IF;

  -- stale terms: closed the day before the successor, how_ended as intended, annotated
  -- (a term CA_0159 later archived counts as done)
  SELECT count(*) INTO v_n FROM _ca0158_seat s
   WHERE s.action = 'replace'
     AND ( EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.id = s.stale_term_id AND t.term_end = s.term_start - 1
                      AND t.how_ended = COALESCE(s.how_ended, 'unknown') AND t.source LIKE '%| closed CA_0158%')
        OR EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed a WHERE a.id = s.stale_term_id AND a.reason LIKE 'CA_0159%'));
  IF v_n <> 140 THEN RAISE EXCEPTION 'POST: % of 140 stale terms closed as intended', v_n; END IF;

  -- kept: the three Hart terms are untouched and still open
  SELECT count(*) INTO v_n FROM _ca0158_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'keep' AND t.term_start IS NULL AND t.term_end IS NULL AND t.source NOT LIKE '%CA_0158%';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 kept Hart terms untouched', v_n; END IF;

  -- stale people: not current anywhere, not incumbents
  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT stale_pol_id FROM _ca0158_seat WHERE action = 'replace')
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % stale holder(s) still current or incumbent', v_bad; END IF;

  -- no seat is left invisible (every office has a term row)
  SELECT count(*) INTO v_bad FROM _ca0158_seat s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = s.office_id);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seat(s) have no office_terms row', v_bad; END IF;

  -- the duplicate-guard bypass did not leak past its one insert
  IF COALESCE(NULLIF(current_setting('essentials.allow_duplicate_name', true), ''), 'off') <> 'off' THEN
    RAISE EXCEPTION 'POST: essentials.allow_duplicate_name is still on';
  END IF;

  -- END TO END: an interior point of each district's own geofence reaches the expected number of active
  -- incumbent holders on that district, through the same MTFCC mapping the address lookup uses
  SELECT count(*) INTO v_bad FROM _ca0158_district x
   WHERE (SELECT count(DISTINCT p.id)
            FROM essentials.geofence_boundaries me
            JOIN essentials.geofence_boundaries gb
              ON public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry))
             AND gb.mtfcc IN ('G5400','G5410','G5420')
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL'
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id
            JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
           WHERE me.geo_id = x.geo_id AND me.mtfcc IN ('G5400','G5410') AND d.geo_id = x.geo_id)
         <> x.seats - (SELECT count(*) FROM _ca0158_vac v JOIN _ca0158_seat s ON s.office_id = v.office_id WHERE s.geo_id = x.geo_id);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) not reached from inside their own polygon', v_bad; END IF;

  RAISE NOTICE 'CA_0158 applied: 31 boards / 153 seats -- 150 members seated (140 replacing a stale holder, 10 on added seats), 2 of them since resigned (seats vacated), 3 stale holders kept; 140 stale terms closed; 142 politicians created, 8 reused';
END $$;

COMMIT;
