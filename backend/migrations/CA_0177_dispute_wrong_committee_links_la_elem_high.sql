-- CA_0177_dispute_wrong_committee_links_la_elem_high.sql
-- Mark 180 WRONG campaign-finance committee links as 'disputed'. Each sits on one of the 135 placeholder politician
-- rows that CA_0159 found NO EVIDENCE for (LA County elementary and high school district boards; seeded by the
-- unsourced school-district pass, deactivated by CA_0159) and was auto-linked by SURNAME, so the committee belongs to
-- someone else. Follow-up to CA_0166 (the four confirmed links on these rows) and the same method as CA_0174.
--
-- SCOPE: every 'needs_research' link on the 135 rows -- 181 links on 36 of the rows (measured 2026-09-23). No link on
-- these rows is 'confirmed': CA_0166 already disputed the four that were. 180 are disputed here; 1 is left as it is
-- (below). The 4 CA_0166 'disputed' links and the 555 'not_applicable' links on these rows are untouched. The disputed
-- links were made by confirm-cal-access.ts (176 cal_access) and relink-socrata-skipped.ts (4 la_socrata), on the
-- surname alone (174) or on the full name with nothing else (6).
--
-- Per-link table, with the official committee name, filer area code, status, basis, reason and any name-only lead:
--   data/roster-audits/2026-09-23-la-elem-high-committee-links-CA_0177.csv
--
-- EVIDENCE (fetched 2026-09-23):
--   * Cal-Access committee detail page for all 177 cal_access filers: official name, filer phone, status.
--     Control filer 1414018 returned "NEWSOM FOR CALIFORNIA GOVERNOR 2022" before and after the run.
--   * LA City Ethics contributions dataset (data.lacity.org m6g2-gc6c) cand_name / seat_desc for the 4 la_socrata links:
--     Addie Miller (LA Mayor 2005), Nichelle Henderson (LAUSD BD7 2020), Nick Pacheco (LA CD14 2005),
--     Christian Guzman (LA CD15 2022).
--   * LA County RR/CC school-board candidate lists 2017-2026, which cover every one of the 20 districts involved.
--   * Secretary of State 1998 general-election candidate list (vigarchive.sos.ca.gov) for Jay T. Imperial.
--
-- BASIS (the CSV column 'basis'):
--   A   24  the committee names another person, or the "surname" hit is a place name (Imperial County, the Imperial
--              Irrigation District, Imperial Beach, Imperial Valley; Rancho Santiago CCD; the Reed Union School District).
--   B  145  the committee is for another office or another named district (council, Assembly, supervisor, judge, a
--              different school district, a college or water board, a recall or ballot-initiative committee ...), not
--              for the row's board. Includes the 4 la_socrata links, whose candidates LA City Ethics names.
--   C   11  a school-board or unnamed committee that the evidence places elsewhere: the filer is outside LA County
--              (area codes 408, 530, 619, 831, 925, 949, 951, 209) and nothing ties it to the row, and/or the county
--              candidate list for the row's district and year names other people (Garvey 2022, Los Nietos 2024 and 2026,
--              Centinela Valley 2026).
--
-- LEFT ALONE -- 1 link: cal_access 1222359 "PORTILLO, NEIGHBORS FOR" on Angela Portillo (Palmdale SD) stays
-- 'needs_research'. The committee has no given name, no office and no electronic filing, and terminated in 2000. Its
-- filer area code (818, San Fernando Valley) is not Palmdale's, but it is inside LA County, so nothing shows it belongs
-- elsewhere. It carries no money.
--
-- NAME-ONLY LEADS (recorded in the CSV, not acted on): some committees carry the row's full name for another office --
-- Jay Imperial (1277545, a committee to RECALL Rosemead City Council members Jay Imperial and Gary Taylor; the 1998 SOS
-- candidate list gives Jay T. Imperial as "Council Member, Rosemead City"), Jonathan Contreras (1301029, Valley County
-- Water District 2011), Lance Christensen (Superintendent of Public Instruction 2022/2026), Mike Layne (Redlands City
-- Council 2010/2012). None is evidence for the row's seat, and each committee is still not the row's. Separately,
-- 1475601 "GUZMAN FOR HIGH SCHOOL BOARD 2024" is probably Luis G. Guzman's (the only 2024 LA County high-school-board
-- candidate surnamed Guzman; he holds El Monte Union HSD Trustee Area 2 on an active row with no committee link). That
-- re-link needs its own evidence and is not made here. These go to the same operator ruling as CA_0169's and CA_0174's.
--
-- WHY 'disputed' AND NOT DELETE OR RE-POINT: 'disputed' is the admin API's own value for a wrong link
-- (campaignFinanceAdmin.ts), as in CA_0166 and CA_0174. Every read path and the ingestion scheduler require
-- research_status = 'confirmed' and nothing reads 'needs_research' (migration 1792), so all 180 links were already
-- inert: disputing them changes the record, so the next research pass does not confirm them, not the display. No money
-- moves: the 181 links carry 0 contributions and 0 contribution_summary_agg rows. Nothing is deleted: 25
-- ingestion_runs (on 9 of the links) keep their source.
--
-- NOTES FORMAT: none of the 180 notes is a JSON object. Each carries "<json> | UNVERIFIED (migration 1792 ...)" (176)
-- or "<json> | sweep 1664: ..." (4), so each gets the same " | "-joined suffix those migrations used:
-- " | DISPUTED by CA_0177 (2026-09-23): <reason>". The IS JSON OBJECT branch is kept from CA_0174 so the file stays
-- correct if a note is rewritten before it runs. politician_sources is public-read, so no reason carries a phone number.
--
-- OVERLAP CHECKED: CA_0166's four links on these rows are 'disputed' and are not in this file. CA_0174 works on the
-- CA_0156 rows; no row carries both markers. No other migration on master or on any unmerged branch writes
-- politician_sources on these rows.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 (operator-approved). Before: BEGIN...ROLLBACK dry run reverted (md5 snapshot of
-- every link on the 135 rows identical before and after); a double run in one transaction gave UPDATE 0 on the second
-- pass; a planted needs_research link tripped the completeness gate. After: 184 disputed / 1 needs_research (PORTILLO) /
-- 555 not_applicable / 0 confirmed on the 135 rows; a second run gave UPDATE 0.
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'needs_research',
--          notes = CASE WHEN notes IS JSON OBJECT THEN (notes::jsonb - 'disputed_by' - 'disputed_reason')::text
--                       ELSE left(notes, strpos(notes, ' | DISPUTED by CA_0177 (2026-09-23): ') - 1) END
--    WHERE research_status = 'disputed' AND strpos(notes, 'CA_0177 (2026-09-23)') > 0;
-- IDEMPOTENT: the update is guarded on each link's prior status; a re-run is a no-op and every gate still passes.

BEGIN;

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, politician_id uuid, source_system text, external_id text,
                         prior_status text, committee text, reason text) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('ff3c9631-ad71-4d5e-ac41-141be3378730','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1263805','needs_research',
   'VALENZUELA FOR ASSEMBLY, COMMITTEE TO ELECT',
   'surname-only auto-link: Cal-Access 1263805 "VALENZUELA FOR ASSEMBLY, COMMITTEE TO ELECT" -- a campaign for the State Assembly, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('e73d7327-eb67-4d72-84c7-07133f8cba71','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1273117','needs_research',
   'VALENZUELA FOR COVINA COUNCIL, COMMITTEE TO ELECT',
   'surname-only auto-link: Cal-Access 1273117 "VALENZUELA FOR COVINA COUNCIL, COMMITTEE TO ELECT" -- a campaign for a city council, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('e3808893-1b93-4a72-bd86-84757de0e7ae','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1304963','needs_research',
   'VALENZUELA FOR SUPERVISOR',
   'surname-only auto-link: Cal-Access 1304963 "VALENZUELA FOR SUPERVISOR" -- a campaign for a county board of supervisors, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('3616280c-bc54-4fef-add8-5c1de332ad1c','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1332892','needs_research',
   'VALENZUELA FOR CALEXICO SCHOOL BOARD 2010 COMMITTEE.',
   'surname-only auto-link: Cal-Access 1332892 "VALENZUELA FOR CALEXICO SCHOOL BOARD 2010 COMMITTEE." -- a campaign for the board of a different school district, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('1b032403-b7b8-4efe-8bfe-13c5ab8468f1','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1335741','needs_research',
   'VALENZUELA FOR COUNCIL 2011',
   'surname-only auto-link: Cal-Access 1335741 "VALENZUELA FOR COUNCIL 2011" -- a campaign for a city council, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('89ee3f4d-2ded-48ed-bad9-008176436356','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1340827','needs_research',
   'VALENZUELA FOR CITY CLERK 2011',
   'surname-only auto-link: Cal-Access 1340827 "VALENZUELA FOR CITY CLERK 2011" -- a campaign for city clerk, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('014af8be-d906-4f6d-b860-80e42c512117','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1356282','needs_research',
   'VALENZUELA FOR OXNARD CITY COUNCIL 2013, A J',
   'surname-only auto-link: Cal-Access 1356282 "VALENZUELA FOR OXNARD CITY COUNCIL 2013, A J" -- a campaign for a city council (A J Valenzuela, Oxnard), not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('53b23959-4ae9-435d-8ef8-8ee141513ec5','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1423895','needs_research',
   'VALENZUELA, VANG AND LANDEROS FOR CITY COUNCIL 2020, SPONSORED BY LABOR AND COMMUNITY ORGANIZATIONS; SACRAMENTO WORKING FAMILIES SUPPORTING',
   'surname-only auto-link: Cal-Access 1423895 "VALENZUELA, VANG AND LANDEROS FOR CITY COUNCIL 2020, SPONSORED BY LABOR AND COMMUNITY ORGANIZATIONS; SACRAMENTO WORKING FAMILIES SUPPORTING" -- a campaign for a city council (Sacramento), not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('6d42b496-1a0f-4bce-8a0f-b64a4c314843','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1451676','needs_research',
   'VALENZUELA FOR CITY TREASURER 2022',
   'surname-only auto-link: Cal-Access 1451676 "VALENZUELA FOR CITY TREASURER 2022" -- a campaign for city treasurer, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('c29a23e8-9aab-4537-a3a2-169b3abb8dd9','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1467094','needs_research',
   'VALENZUELA FOR SACRAMENTO CITY COUNCIL 2024; EAST SACRAMENTO LABOR AND COMMUNITY COALITION TO SUPPORT',
   'surname-only auto-link: Cal-Access 1467094 "VALENZUELA FOR SACRAMENTO CITY COUNCIL 2024; EAST SACRAMENTO LABOR AND COMMUNITY COALITION TO SUPPORT" -- a campaign for a city council (Sacramento), not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('883f4de5-475e-4341-9402-bdff8cf983cf','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1474844','needs_research',
   'VALENZUELA FOR CITY COUNCIL 2024',
   'surname-only auto-link: Cal-Access 1474844 "VALENZUELA FOR CITY COUNCIL 2024" -- a campaign for a city council, not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('b73eab2c-5cfa-477b-904a-ead2849f2647','8a0d4875-70b5-4678-badb-4e1b8caa432c','cal_access','1489427','needs_research',
   'VALENZUELA FOR ESCONDIDO CITY COUNCIL 2026',
   'surname-only auto-link: Cal-Access 1489427 "VALENZUELA FOR ESCONDIDO CITY COUNCIL 2026" -- a campaign for a city council (Escondido), not for the Palmdale SD board; this row is a CA_0159 no-evidence Palmdale SD placeholder (deactivated)'),
  ('c9aa0521-e78a-4668-85d0-5f06d6da080d','91b3fdfd-9908-495e-86c6-e2d523982e15','cal_access','1041795','needs_research',
   'AGUIRRE, CITIZENS FOR',
   'surname-only auto-link: Cal-Access 1041795 "AGUIRRE, CITIZENS FOR MIKE" (stored as "AGUIRRE, CITIZENS FOR") -- names a different person (Mike Aguirre; filer area code 619, San Diego); this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('1ac08264-3af4-4319-b070-623834c83966','91b3fdfd-9908-495e-86c6-e2d523982e15','cal_access','1313439','needs_research',
   'AGUIRRE FOR GOVERNOR CAMPAIGN',
   'surname-only auto-link: Cal-Access 1313439 "AGUIRRE FOR GOVERNOR 2010 CAMPAIGN" (stored as "AGUIRRE FOR GOVERNOR CAMPAIGN") -- a campaign for Governor, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('055752de-f755-4799-98ff-d4de59718055','91b3fdfd-9908-495e-86c6-e2d523982e15','cal_access','1365702','needs_research',
   'AGUIRRE FOR GOVERNOR 2014',
   'surname-only auto-link: Cal-Access 1365702 "AGUIRRE FOR GOVERNOR 2014" -- a campaign for Governor, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('f1e5832a-3fcd-4e93-8d03-ebc2a85f3365','91b3fdfd-9908-495e-86c6-e2d523982e15','cal_access','1409690','needs_research',
   'AGUIRRE BOARD MEMBER 2018; ELECTION COMMITTEE OF CYNTHIA',
   'surname-only auto-link: Cal-Access 1409690 "AGUIRRE BOARD MEMBER 2018; ELECTION COMMITTEE OF CYNTHIA" -- names a different person (Cynthia Aguirre; filer area code 831, Central Coast); this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('3a980508-66f1-40bf-a124-7594d2a1e72f','91b3fdfd-9908-495e-86c6-e2d523982e15','cal_access','1478238','needs_research',
   'AGUIRRE FOR SUPERVISOR 2025, SPONSORED BY LABORERS'' INTERNATIONAL UNION OF NORTH AMERICA, LOCAL 89; SAN DIEGO WORKING FAMILIES AGAINST PALOMA',
   'surname-only auto-link: Cal-Access 1478238 "AGUIRRE FOR SUPERVISOR 2025, SPONSORED BY LABORERS'' INTERNATIONAL UNION OF NORTH AMERICA, LOCAL 89; SAN DIEGO WORKING FAMILIES AGAINST PALOMA" -- a campaign for a county board of supervisors, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('f1be3d2f-b7fe-4f22-8ba2-d912cae9faa1','288499db-64df-4c1f-ada4-9b94af531a34','cal_access','1348422','needs_research',
   'SNYDER FOR SCHOOL BOARD 2012',
   'surname-only auto-link: Cal-Access 1348422 "SNYDER FOR SCHOOL BOARD 2012" -- a Santa Clara County committee (filer area code 408); nothing ties it to a Dawn Snyder or to Hughes-Elizabeth Lakes Union SD; this row is a CA_0159 no-evidence Hughes-Elizabeth Lakes Union SD placeholder (deactivated)'),
  ('4b405910-e315-4242-90f7-b9e17c8278fe','288499db-64df-4c1f-ada4-9b94af531a34','cal_access','1362008','needs_research',
   'SNYDER FOR MERCED COUNTY SUPERVISOR 2014',
   'surname-only auto-link: Cal-Access 1362008 "SNYDER FOR MERCED COUNTY SUPERVISOR 2014" -- a campaign for a county board of supervisors, not for the Hughes-Elizabeth Lakes Union SD board; this row is a CA_0159 no-evidence Hughes-Elizabeth Lakes Union SD placeholder (deactivated)'),
  ('13437cc6-dd2f-4816-991d-44f32ca13600','288499db-64df-4c1f-ada4-9b94af531a34','cal_access','1402883','needs_research',
   'SNYDER FOR ASSEMBLY 2018',
   'surname-only auto-link: Cal-Access 1402883 "SNYDER FOR ASSEMBLY 2018" -- a campaign for the State Assembly, not for the Hughes-Elizabeth Lakes Union SD board; this row is a CA_0159 no-evidence Hughes-Elizabeth Lakes Union SD placeholder (deactivated)'),
  ('235ffc89-f249-4847-8bb1-1ffeb6c72087','288499db-64df-4c1f-ada4-9b94af531a34','cal_access','1453684','needs_research',
   'SNYDER FOR SCOTTS VALLEY UNIFIED SCHOOL BOARD 2022',
   'surname-only auto-link: Cal-Access 1453684 "SNYDER FOR SCOTTS VALLEY UNIFIED SCHOOL BOARD 2022" -- a campaign for the board of a different school district, not for the Hughes-Elizabeth Lakes Union SD board; this row is a CA_0159 no-evidence Hughes-Elizabeth Lakes Union SD placeholder (deactivated)'),
  ('e8f9ff6d-a708-43a4-a4d1-d0164aee931a','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1365764','needs_research',
   'LABRADO FOR RANCHO SANTIAGO COLLEGE BOARD 2014',
   'surname-only auto-link: Cal-Access 1365764 "LABRADO FOR RANCHO SANTIAGO COLLEGE BOARD 2014" -- the match is on the district name Rancho Santiago (an Orange County community college district), not the surname; it names a different person (Labrado); this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('7616abe7-1b87-44f5-8f0c-d9fbf320aabd','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1389486','needs_research',
   'AGUINAGA FOR RANCHO SANTIAGO COMMUNITY COLLEGE DISTRICT 2016',
   'surname-only auto-link: Cal-Access 1389486 "AGUINAGA FOR RANCHO SANTIAGO COMMUNITY COLLEGE DISTRICT 2016" -- the match is on the district name Rancho Santiago (an Orange County community college district), not the surname; it names a different person (Aguinaga); this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('752f41b7-e166-4402-a9f0-a2eabb8ebfed','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1414642','needs_research',
   'SANTIAGO FOR ASSEMBLY 2020',
   'surname-only auto-link: Cal-Access 1414642 "SANTIAGO FOR ASSEMBLY 2020" -- a campaign for the State Assembly, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('6b22aea0-bb71-436d-8be7-eace7d633261','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1435164','needs_research',
   'SANTIAGO FOR ASSEMBLY 2022',
   'surname-only auto-link: Cal-Access 1435164 "SANTIAGO FOR ASSEMBLY 2022" -- a campaign for the State Assembly, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('1dca1914-301d-4dfd-b627-d5d8d7f97487','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1466414','needs_research',
   'SANTIAGO FOR LOS ANGELES CITY COUNCIL 2024, SPONSORED BY WESTERN STATES REGIONAL COUNCIL OF CARPENTERS; BUILDING A STRONGER CALIFORNIA SUPPORTING MIGUEL',
   'surname-only auto-link: Cal-Access 1466414 "SANTIAGO FOR LOS ANGELES CITY COUNCIL 2024, SPONSORED BY WESTERN STATES REGIONAL COUNCIL OF CARPENTERS; BUILDING A STRONGER CALIFORNIA SUPPORTING MIGUEL" -- a campaign for a city council (Miguel Santiago, Los Angeles), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('f76ff98d-4bca-4c81-97ac-5fd50cace6fc','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1469411','needs_research',
   'SANTIAGO FOR ASSEMBLY 2030',
   'surname-only auto-link: Cal-Access 1469411 "SANTIAGO FOR ASSEMBLY 2030" -- a campaign for the State Assembly, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('1ea91ecb-f5ad-42c5-919b-078140575a04','2a954d75-5a34-4753-b508-be66799bc760','cal_access','1474864','needs_research',
   'NOJI; AUDREY NOJI RANCHO SANTIAGO COMMUNITY DISTRICT WARD 3 GOVERNING BOARD 2024; PARENTS AND EDUCATORS FOR DR',
   'surname-only auto-link: Cal-Access 1474864 "NOJI; AUDREY NOJI RANCHO SANTIAGO COMMUNITY DISTRICT WARD 3 GOVERNING BOARD 2024; PARENTS AND EDUCATORS FOR DR" -- the match is on the district name Rancho Santiago (an Orange County community college district), not the surname; it names a different person (Dr. Audrey Noji); this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('b50fa0e1-eddf-42b5-90a6-9f807eb4f0d3','8c145930-0af7-4cfc-b959-06a2a394e11e','cal_access','1050484','needs_research',
   'LANG FOR ASSEMBLY - 1990',
   'surname-only auto-link: Cal-Access 1050484 "LANG FOR ASSEMBLY - 1990" -- a campaign for the State Assembly, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('31ddedfd-1603-49e6-8d02-c2d0f982ee02','8c145930-0af7-4cfc-b959-06a2a394e11e','cal_access','1071593','needs_research',
   'LANG FOR MAYOR',
   'surname-only auto-link: Cal-Access 1071593 "LANG FOR MAYOR" -- a campaign for mayor, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('a550caf1-28e0-4dd7-8f26-8ed96cc0ee78','8c145930-0af7-4cfc-b959-06a2a394e11e','cal_access','1341096','needs_research',
   'LANG FOR FAIRFAX TOWN COUNCIL 2011, (FRIENDS OF CHRIS LANG)',
   'surname-only auto-link: Cal-Access 1341096 "LANG FOR FAIRFAX TOWN COUNCIL 2011, (FRIENDS OF CHRIS LANG)" -- a campaign for a town council (Chris Lang, Fairfax), not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('7c73ad13-a27e-4dcd-a978-92a909b19273','8c145930-0af7-4cfc-b959-06a2a394e11e','cal_access','1474349','needs_research',
   'MEADOWS, WEINBERG, AND LANG FOR COUNCIL 2024; FORMER MAYORS OF LOS ALTOS FOR',
   'surname-only auto-link: Cal-Access 1474349 "MEADOWS, WEINBERG, AND LANG FOR COUNCIL 2024; FORMER MAYORS OF LOS ALTOS FOR" -- a campaign for a city council (Los Altos), not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('8905f1b5-247f-4546-9c7a-2b097160fa76','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1338445','needs_research',
   'REYES FOR RIO HONDO COLLEGE 2011',
   'surname-only auto-link: Cal-Access 1338445 "REYES FOR RIO HONDO COLLEGE 2011" -- a campaign for a community college board, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('8ba48613-931a-478a-8f73-b95df5f568e7','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1368503','needs_research',
   'REYES FOR CVESD TRUSTEE 2014',
   'surname-only auto-link: Cal-Access 1368503 "REYES FOR CVESD TRUSTEE 2014" -- a campaign for the board of a different school district, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('9f582581-12f9-410b-a055-6aa2fd8f999b','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1368896','needs_research',
   'REYES FOR HUSD SCHOOL BOARD 2014',
   'surname-only auto-link: Cal-Access 1368896 "REYES FOR HUSD SCHOOL BOARD 2014" -- a campaign for the board of a different school district, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('ea516b76-ed91-4c0a-9cee-bc1802c01e92','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1412730','needs_research',
   'HIGH DESERT CITIZENS FOR PROGRESS SUPPORTING REYES FOR MAYOR OF ADELANTO 2018',
   'surname-only auto-link: Cal-Access 1412730 "HIGH DESERT CITIZENS FOR PROGRESS SUPPORTING REYES FOR MAYOR OF ADELANTO 2018" -- a campaign for mayor (Adelanto), not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('616e9375-69da-45cc-b645-2875e04c48cf','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1419690','needs_research',
   'REYES FOR WHITTIER MAYOR 2020',
   'surname-only auto-link: Cal-Access 1419690 "REYES FOR WHITTIER MAYOR 2020" -- a campaign for mayor, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('20a2a9ee-4efa-47c7-a6d4-36af592e797a','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1421149','needs_research',
   'REYES 2020; RETAIN JUDGE BENJAMIN',
   'surname-only auto-link: Cal-Access 1421149 "REYES 2020; RETAIN JUDGE BENJAMIN" -- a campaign for a judgeship (Benjamin Reyes), not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('dd882602-91cf-408c-ad09-4dd1b59e2363','c471d672-413b-42ef-862b-2acf76e8c000','cal_access','1452223','needs_research',
   'REYES FOR DISTRICT 5 CITY COUNCIL 2022',
   'surname-only auto-link: Cal-Access 1452223 "REYES FOR DISTRICT 5 CITY COUNCIL 2022" -- a campaign for a city council, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('07fbe6ed-9d3e-4927-8910-46c1e5bfa459','1b7900b6-50b5-4c43-ba3b-673fbf0fe02d','cal_access','1386830','needs_research',
   'CORRALES FOR PALMDALE CITY COUNCIL 2016',
   'surname-only auto-link: Cal-Access 1386830 "CORRALES FOR PALMDALE CITY COUNCIL 2016" -- a campaign for a city council, not for the El Monte City SD board; this row is a CA_0159 no-evidence El Monte City SD placeholder (deactivated)'),
  ('b615af38-a077-40b5-9b5c-a58b1a4a1462','aa99212b-41fc-484a-a7cd-20b65c1ed751','cal_access','1384642','needs_research',
   'ORNELAS FOR DEMOCRATIC CENTRAL COMMITTEE 51ST AD 2016',
   'surname-only auto-link: Cal-Access 1384642 "ORNELAS FOR DEMOCRATIC CENTRAL COMMITTEE 51ST AD 2016" -- a campaign for a party central committee, not for the South Whittier SD board; this row is a CA_0159 no-evidence South Whittier SD placeholder (deactivated)'),
  ('f3c7b62f-d130-41b8-a036-6c6d05393f51','aa99212b-41fc-484a-a7cd-20b65c1ed751','cal_access','1404024','needs_research',
   'ORNELAS FOR WATER BOARD 2018',
   'surname-only auto-link: Cal-Access 1404024 "ORNELAS FOR WATER BOARD 2018" -- a campaign for a water district board, not for the South Whittier SD board; this row is a CA_0159 no-evidence South Whittier SD placeholder (deactivated)'),
  ('b0254007-8c42-442b-a223-64e127a5708e','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1023395','needs_research',
   'SUITT, IMPERIAL COUNTY FRIENDS OR TOM',
   'surname-only auto-link: Cal-Access 1023395 "SUITT, IMPERIAL COUNTY FRIENDS OR TOM" -- the match is on Imperial County, not the surname; it names a different person (Tom Suitt); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('d5afbeb4-d9e3-43c3-9119-87db9304a844','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1252430','needs_research',
   'GARRIE, DIRECTOR, IMPERIAL IRRIGATION DISTRICT - DIST. 2.  COMMITTEE TO ELECT: RONNIE',
   'surname-only auto-link: Cal-Access 1252430 "GARRIE, DIRECTOR, IMPERIAL IRRIGATION DISTRICT - DIST. 2.  COMMITTEE TO ELECT: RONNIE" -- the match is on the Imperial Irrigation District, not the surname; it names a different person (Ronnie Garrie); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('618a51a1-0521-43b2-a06e-f38821b5ce2a','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1277545','needs_research',
   'SOC - TO SUPPORT RECALL OF JAY IMPERIAL AND GARY TAYLOR',
   'name-only auto-link: Cal-Access 1277545 "SOC - TO SUPPORT RECALL OF JAY IMPERIAL AND GARY TAYLOR" -- a committee supporting the recall of Jay Imperial and Gary Taylor, both then Rosemead City Council members (the 1998 Secretary of State candidate list gives Jay T. Imperial as "Council Member, Rosemead City"; filer area code 626) -- a committee against the officeholder, never his own, and about a city council seat, not the Rosemead SD board; this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('b19b67b6-83ff-4b9c-a809-a0d88eccab1a','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1291676','needs_research',
   'TOM 4 IMPERIAL BEACH',
   'surname-only auto-link: Cal-Access 1291676 "TOM 4 IMPERIAL BEACH" -- the match is on the city name Imperial Beach, not the surname; this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('88c3cc24-e423-4bc6-8668-1ee7f99f3188','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1299923','needs_research',
   'RESIDENTS FOR A BETTER IMPERIAL, A COMMITTEE TO RECALL LARRY GROGAN, WALLY LEIMGRUBER, JOE MARUCA & GARY WYATT, SPONSORED BY CALIFORNIA UNITED HOMECARE WORKERS',
   'surname-only auto-link: Cal-Access 1299923 "RESIDENTS FOR A BETTER IMPERIAL, A COMMITTEE TO RECALL LARRY GROGAN, WALLY LEIMGRUBER, JOE MARUCA & GARY WYATT, SPONSORED BY CALIFORNIA UNITED HOMECARE WORKERS" -- the match is on the city name Imperial, not the surname (a committee to recall other officials); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('8b85f525-3a75-42ea-96eb-0901d33a7d54','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1326377','needs_research',
   'MALDONADO FOR (IID) IMPERIAL IRRIGATION DISTRICT DIRECTOR, DIVISION 1, 2010',
   'surname-only auto-link: Cal-Access 1326377 "MALDONADO FOR (IID) IMPERIAL IRRIGATION DISTRICT DIRECTOR, DIVISION 1, 2010" -- the match is on the Imperial Irrigation District, not the surname (a campaign by Maldonado); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('d14a9166-555b-4502-bb4a-6056a5f8bc3f','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1345339','needs_research',
   'IMPERIAL VALLEY FIRST',
   'surname-only auto-link: Cal-Access 1345339 "IMPERIAL VALLEY FIRST" -- the match is on the place name Imperial Valley, not the surname; this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('3357d568-88f1-44bd-a4d1-4838ba712beb','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1346892','needs_research',
   'CASAREZ TO IMPERIAL IRRIGATION DISTRICT DIRECTOR DIVISION 2, 2012; COMMITTEE TO ELECT RUBEN "WATCHDOG"',
   'surname-only auto-link: Cal-Access 1346892 "CASAREZ TO IMPERIAL IRRIGATION DISTRICT DIRECTOR DIVISION 2, 2012; COMMITTEE TO ELECT RUBEN "WATCHDOG"" -- the match is on the Imperial Irrigation District, not the surname (a campaign by Ruben Casarez); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('803f8e7b-8118-49de-af24-7ac6cfb64d31','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1348538','needs_research',
   'LEIMGRUBER FOR IMPERIAL IRRIGATION DISTRICT 2012',
   'surname-only auto-link: Cal-Access 1348538 "LEIMGRUBER FOR IMPERIAL IRRIGATION DISTRICT 2012" -- the match is on the Imperial Irrigation District, not the surname (a campaign by Leimgruber); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('62f20410-3128-4419-ab45-181af4afaff7','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1364036','needs_research',
   'LOWERY FOR IMPERIAL BEACH COUNCIL 2014',
   'surname-only auto-link: Cal-Access 1364036 "LOWERY FOR IMPERIAL BEACH COUNCIL 2014" -- the match is on the city name Imperial Beach, not the surname (a campaign by Lowery); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('75e08954-6472-4c86-9c7b-411b3db93f56','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1383833','needs_research',
   'ORTEGA FOR IMPERIAL IRRIGATION DISTRICT 2016',
   'surname-only auto-link: Cal-Access 1383833 "ORTEGA FOR IMPERIAL IRRIGATION DISTRICT 2016" -- the match is on the Imperial Irrigation District, not the surname (a campaign by Ortega); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('31c7a40b-5f43-4982-ad89-5ccf51912595','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1394682','needs_research',
   'SNIVELY IMPERIAL IRRIGATION DISTRICT DIRECTOR DIVISION 1 2017; COMMITTEE TO ELECT JOHN EDGAR "ED"',
   'surname-only auto-link: Cal-Access 1394682 "SNIVELY IMPERIAL IRRIGATION DISTRICT DIRECTOR DIVISION 1 2017; COMMITTEE TO ELECT JOHN EDGAR "ED"" -- the match is on the Imperial Irrigation District, not the surname (a campaign by John Edgar "Ed" Snively); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('a7e84474-bcb5-4811-9282-bdddf149f1ce','3ed8f158-6f91-4e96-9181-09e4783c010c','cal_access','1405181','needs_research',
   'ESCOBAR IMPERIAL COUNTY SUPERVISOR DIST 1 2022; CMTE TO ELECT',
   'surname-only auto-link: Cal-Access 1405181 "ESCOBAR IMPERIAL COUNTY SUPERVISOR DIST 1 2022; CMTE TO ELECT" -- the match is on Imperial County, not the surname (a campaign for its board of supervisors); this row is a CA_0159 no-evidence Rosemead SD placeholder (deactivated)'),
  ('39b514d8-2895-4fd8-99a3-45b79d91bb50','c5a12549-9b81-4013-b747-bbc7a4fca3f3','cal_access','1287873','needs_research',
   'REINHART FOR IRWD BOARD OF DIRECTORS - 2022',
   'surname-only auto-link: Cal-Access 1287873 "REINHART FOR IRWD BOARD OF DIRECTORS - 2022" -- a campaign for a water district board, not for the Hermosa Beach City SD board; this row is a CA_0159 no-evidence Hermosa Beach City SD placeholder (deactivated)'),
  ('a1f470cb-b0fd-4987-8642-99a8582e21a2','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1025868','needs_research',
   'GILBERT INITIATIVE, CITIZENS FOR THE',
   'surname-only auto-link: Cal-Access 1025868 "GILBERT INITIATIVE, CITIZENS FOR THE" -- a ballot-initiative committee (the Gilbert Initiative), not a campaign for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('af8b6a89-a971-4af3-a1f9-6cbc982ec06c','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1026330','needs_research',
   'MARIJUANA P.O.W.''S FOR THE GILBERT INITIATIVE',
   'surname-only auto-link: Cal-Access 1026330 "MARIJUANA P.O.W.''S FOR THE GILBERT INITIATIVE" -- a ballot-initiative committee (the Gilbert Initiative), not a campaign for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('9c8df304-285d-4ead-9c59-a56cfd7b7c89','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1041463','needs_research',
   'GILBERT -- SUPERIOR COURT, RETAIN JUDGE ROGER',
   'surname-only auto-link: Cal-Access 1041463 "GILBERT -- SUPERIOR COURT, RETAIN JUDGE ROGER" -- a campaign for a judgeship (Roger Gilbert), not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('2e591184-a32c-4b83-bcf9-16fe2de3219f','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1072291','needs_research',
   'GILBERT FOR SUPERVISOR',
   'surname-only auto-link: Cal-Access 1072291 "GILBERT FOR SUPERVISOR" -- a campaign for a county board of supervisors, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('7472aea2-6a2e-4c19-a82f-ab429f755445','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1349875','needs_research',
   'GILBERT FOR CITY COUNCIL 2012',
   'surname-only auto-link: Cal-Access 1349875 "GILBERT FOR CITY COUNCIL 2012" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('fa73c2b1-15c8-4a9c-a68d-c3003d06f13b','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1383144','needs_research',
   'GILBERT 4 COUNCIL 2016',
   'surname-only auto-link: Cal-Access 1383144 "GILBERT 4 COUNCIL 2016" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('c7e37e37-7556-41e4-ae7d-ffe336875c77','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1391347','needs_research',
   'GILBERT FOR CITY COUNCIL 2016',
   'surname-only auto-link: Cal-Access 1391347 "GILBERT FOR CITY COUNCIL 2016" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('809ac13a-66ed-4dc8-8142-9f148ef8e5db','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1426072','needs_research',
   'GILBERT FOR DHS COUNCIL 2020',
   'surname-only auto-link: Cal-Access 1426072 "GILBERT FOR DHS COUNCIL 2020" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('82dcba5c-2718-47ac-834c-56070a20dc3e','c965c628-5fa7-44d2-b299-59e49eff3ece','cal_access','1446378','needs_research',
   'GILBERT FOR CLERK 2022',
   'surname-only auto-link: Cal-Access 1446378 "GILBERT FOR CLERK 2022" -- a campaign for city clerk, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('4db29186-92e1-4964-8f79-32b81bb57706','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1360693','needs_research',
   'RENTERIA FOR LYNWOOD SCHOOL BOARD 2013',
   'surname-only auto-link: Cal-Access 1360693 "RENTERIA FOR LYNWOOD SCHOOL BOARD 2013" -- a campaign for the board of a different school district, not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('61b2e578-04b5-4909-8411-72174dd2278b','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1402592','needs_research',
   'RENTERIA FOR GOVERNOR 2018',
   'surname-only auto-link: Cal-Access 1402592 "RENTERIA FOR GOVERNOR 2018" -- a campaign for Governor, not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('d9b02fc3-ad18-487c-95e9-ab6ca5ed88de','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1444470','needs_research',
   'RENTERIA FOR CITY COUNCIL 2022',
   'surname-only auto-link: Cal-Access 1444470 "RENTERIA FOR CITY COUNCIL 2022" -- a campaign for a city council, not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('edc4e222-8f14-4f66-b8a0-34dfe21c2cc4','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1462448','needs_research',
   'RENTERIA FOR CITY COUNCIL 2024',
   'surname-only auto-link: Cal-Access 1462448 "RENTERIA FOR CITY COUNCIL 2024" -- a campaign for a city council, not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('86fcac43-00fa-43bc-a2df-8c93903a31a9','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1471156','needs_research',
   'RENTERIA FOR FREMONT UNION HIGH SCHOOL BOARD 2024',
   'surname-only auto-link: Cal-Access 1471156 "RENTERIA FOR FREMONT UNION HIGH SCHOOL BOARD 2024" -- a campaign for the board of a different school district, not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('7460b8ab-c0fb-4ede-9d18-065aa56049f2','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1476063','needs_research',
   'VERA, DENICE RENTERIA AND JEANNINE WISNOSKY STEHLIN FOR CITY COUNCIL 2024, SPONSORED BY BIZFED PAC, A PROJECT OF LOS ANGELES COUNTY BUSINESS FEDERATION; CULVER CITY FIRENDS AND NEIGHBORS SUPPORTING AL',
   'surname-only auto-link: Cal-Access 1476063 "VERA, DENICE RENTERIA AND JEANNINE WISNOSKY STEHLIN FOR CITY COUNCIL 2024, SPONSORED BY BIZFED PAC, A PROJECT OF LOS ANGELES COUNTY BUSINESS FEDERATION; CULVER CITY FIRENDS AND NEIGHBORS SUPPORTING AL" -- a campaign for a city council (Culver City; Denice Renteria), not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('39d7d98d-2b7e-4970-839c-9cb2cd8cd6d9','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1476210','needs_research',
   'VERA AND DENICE RENTERIA FOR CITY COUNCIL 2024; OUR CULVER CITY IN SUPPORT OF AL',
   'surname-only auto-link: Cal-Access 1476210 "VERA, DENICE RENTERIA AND JEANNINE WISNOSKY STELIN FOR CITY COUNCIL 2024; OUR CULVER CITY IN SUPPORT OF AL" (stored as "VERA AND DENICE RENTERIA FOR CITY COUNCIL 2024; OUR CULVER CITY IN SUPPORT OF AL") -- a campaign for a city council (Culver City; Denice Renteria), not for the Lancaster SD board; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('1d6eff69-bba9-41d0-b99e-69df2546b475','a4af047c-985c-4deb-9718-d4bfce2871a0','cal_access','1408447','needs_research',
   'VALLES FOR COUNCIL 2018',
   'surname-only auto-link: Cal-Access 1408447 "VALLES FOR COUNCIL 2018" -- a campaign for a city council, not for the Westside Union SD board; this row is a CA_0159 no-evidence Westside Union SD placeholder (deactivated)'),
  ('b98eb792-67a5-42c1-844b-f16639b68e9e','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1071114','needs_research',
   'CONTRERAS, ELECT ALFONSO "AL"',
   'surname-only auto-link: Cal-Access 1071114 "CONTRERAS, ELECT ALFONSO "AL"" -- names a different person (Alfonso "Al" Contreras); this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('2b87508a-880c-494b-8f85-6fbb17259ea0','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1238088','needs_research',
   'CONTRERAS, ELECT ALFONSO "AL"',
   'surname-only auto-link: Cal-Access 1238088 "CONTRERAS, ELECT ALFONSO "AL"" -- names a different person (Alfonso "Al" Contreras); this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('ef3f41d7-2e1d-4bd4-80c5-6ba96fea377e','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1291375','needs_research',
   'CONTRERAS FOR CITY COUNCIL',
   'surname-only auto-link: Cal-Access 1291375 "CONTRERAS FOR CITY COUNCIL" -- a campaign for a city council, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('77bfd2bc-67c8-4bd3-a195-1cadbffa76bd','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1301029','needs_research',
   'CONTRERAS, COMMITTEE TO ELECT JONATHAN',
   'name-only auto-link: Cal-Access 1301029 "CONTRERAS FOR VALLEY COUNTY WATER DISTRICT 2011" (stored as "CONTRERAS, COMMITTEE TO ELECT JONATHAN") -- a campaign for a water district board, not for the Garvey SD board; no evidence its candidate ever sought or held a Garvey SD seat; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('d1948404-d870-4e99-9897-dd4c5c17a39e','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1360941','needs_research',
   'CONTRERAS 2013 VALLEY COUNTY WATER DISTRICT BOARD, ELECT ALFONSO "AL"',
   'surname-only auto-link: Cal-Access 1360941 "CONTRERAS 2013 VALLEY COUNTY WATER DISTRICT BOARD, ELECT ALFONSO "AL"" -- a campaign for a water district board (Alfonso "Al" Contreras), not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('764569b1-e60e-4bee-b4df-ee82dda03d56','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1390737','needs_research',
   'CONTRERAS FOR WATER BOARD 2016, ELECT ALFONSO "AL"',
   'surname-only auto-link: Cal-Access 1390737 "CONTRERAS FOR WATER BOARD 2020, ELECT ALFONSO "AL"" (stored as "CONTRERAS FOR WATER BOARD 2016, ELECT ALFONSO "AL"") -- a campaign for a water district board (Alfonso "Al" Contreras), not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('a0cb8702-6a78-4a8b-b466-21a80cf1ab1e','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1406247','needs_research',
   'CONTRERAS FOR LEMON GROVE CITY COUNCIL 2018',
   'surname-only auto-link: Cal-Access 1406247 "CONTRERAS FOR LEMON GROVE CITY COUNCIL 2018" -- a campaign for a city council (Lemon Grove), not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('7e38af2b-a19f-4b5a-951e-d5a1780847c6','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1428963','needs_research',
   'CONTRERAS FOR CITY COUNCIL 2020',
   'surname-only auto-link: Cal-Access 1428963 "CONTRERAS FOR CITY COUNCIL 2020" -- a campaign for a city council, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('ee1eb428-1674-4a17-a133-282227a757b0','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1435421','needs_research',
   'CONTRERAS FOR ASSEMBLY 2021',
   'surname-only auto-link: Cal-Access 1435421 "CONTRERAS FOR ASSEMBLY 2021" -- a campaign for the State Assembly, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('8b05ac3c-4c38-4159-881c-13d37fed6ace','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1442314','needs_research',
   'CONTRERAS FOR COUNCIL 2022',
   'surname-only auto-link: Cal-Access 1442314 "CONTRERAS FOR COUNCIL 2022" -- a campaign for a city council, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('25fd2f31-e5f1-4d84-bf5c-f64534b90d33','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1445436','needs_research',
   'CONTRERAS FOR CITY COUNCIL 2022',
   'surname-only auto-link: Cal-Access 1445436 "CONTRERAS FOR CITY COUNCIL 2022" -- a campaign for a city council, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('5fe0a0e4-d97c-45c7-97b3-b393438e590c','416b3a99-371f-4125-95d5-ee693877d76d','cal_access','1450418','needs_research',
   'CONTRERAS FOR SCHOOL BOARD 2022',
   'surname-only auto-link: Cal-Access 1450418 "CONTRERAS FOR SCHOOL BOARD 2022" -- the 2022 LA County candidates for Garvey SD were Paul M. Duran, Ronald Trabanino and Andrew "Andy" Yam (RR/CC list); nothing ties it to a Jonathan Contreras or to Garvey SD; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('8c1a1cb4-0ffe-4279-91de-602455393395','81f85c7b-7abf-4b9e-80f0-38daf0d48fba','cal_access','1075870','needs_research',
   'CRAWFORD FOR SUPERVISOR COMMITTEE',
   'surname-only auto-link: Cal-Access 1075870 "CRAWFORD FOR SUPERVISOR COMMITTEE" -- a campaign for a county board of supervisors, not for the Westside Union SD board; this row is a CA_0159 no-evidence Westside Union SD placeholder (deactivated)'),
  ('fe9f27e2-9aa3-4ed0-a5c4-2277549ec178','81f85c7b-7abf-4b9e-80f0-38daf0d48fba','cal_access','1230098','needs_research',
   'CRAWFORD FOR CITY COUNCIL',
   'surname-only auto-link: Cal-Access 1230098 "CRAWFORD FOR CITY COUNCIL" -- a campaign for a city council, not for the Westside Union SD board; this row is a CA_0159 no-evidence Westside Union SD placeholder (deactivated)'),
  ('d23ea6c4-fce1-4f1f-8bdf-770c9351b11d','81f85c7b-7abf-4b9e-80f0-38daf0d48fba','cal_access','1315260','needs_research',
   'CRAWFORD SR., COMMITTEE TO ELECT REV. WESLEY',
   'surname-only auto-link: Cal-Access 1315260 "CRAWFORD SR., COMMITTEE TO ELECT REV. WESLEY" -- names a different person (Rev. Wesley Crawford Sr.); this row is a CA_0159 no-evidence Westside Union SD placeholder (deactivated)'),
  ('c8268408-7e60-4ccc-8c38-d750c5b5f4e6','81f85c7b-7abf-4b9e-80f0-38daf0d48fba','cal_access','1325386','needs_research',
   'CRAWFORD FOR JUDGE 2010',
   'surname-only auto-link: Cal-Access 1325386 "CRAWFORD FOR JUDGE 2010" -- a campaign for a judgeship, not for the Westside Union SD board; this row is a CA_0159 no-evidence Westside Union SD placeholder (deactivated)'),
  ('60efa62b-51c7-44d8-a740-e4b15728ea40','421390dd-e2cf-492b-bdd7-d5053a719592','cal_access','1320511','needs_research',
   'RUANE FOR MAYOR OF SAN BRUNO 2009',
   'surname-only auto-link: Cal-Access 1320511 "RUANE FOR MAYOR OF SAN BRUNO 2009" -- a campaign for mayor (San Bruno), not for the East Whittier City SD board; this row is a CA_0159 no-evidence East Whittier City SD placeholder (deactivated)'),
  ('abdfa6a3-e0c3-41e1-9f0b-4c84e1ae9802','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1342382','needs_research',
   'CHRISTENSEN FOR CITY COUNCIL 2012, CITIZENS FOR',
   'surname-only auto-link: Cal-Access 1342382 "CHRISTENSEN FOR CITY COUNCIL 2012, CITIZENS FOR" -- a campaign for a city council, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('17211610-c868-427f-803a-0166bfed6d0f','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1374912','needs_research',
   'CHRISTENSEN FOR SUPERVISOR 2015',
   'surname-only auto-link: Cal-Access 1374912 "CHRISTENSEN FOR SUPERVISOR 2015" -- a campaign for a county board of supervisors, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('0f23c210-5239-49ac-9e1a-b0c2f3f17476','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1378512','needs_research',
   'CHRISTENSEN FOR SUPERVISOR 2016',
   'surname-only auto-link: Cal-Access 1378512 "CHRISTENSEN FOR SUPERVISOR 2016" -- a campaign for a county board of supervisors, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('8c3c4e2e-b57d-4a3b-b0be-be007f029161','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1402755','needs_research',
   'CHRISTENSEN FOR AUDITOR 2018',
   'surname-only auto-link: Cal-Access 1402755 "CHRISTENSEN FOR AUDITOR 2018" -- a campaign for auditor, not for the Saugus Union SD board; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('7c0ad43a-bcde-4935-8924-a108aa6db598','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1446110','needs_research',
   'CHRISTENSEN FOR SUPERINTENDENT OF PUBLIC INSTRUCTION 2022; LANCE',
   'name-only auto-link: Cal-Access 1446110 "CHRISTENSEN FOR SUPERINTENDENT OF PUBLIC INSTRUCTION 2022; LANCE" -- a campaign for Superintendent of Public Instruction, not for the Saugus Union SD board; no evidence its candidate ever sought or held a Saugus Union SD seat; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('9b60ed73-49bf-4195-ac9c-99fcaf98c223','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1462631','needs_research',
   'CHRISTENSEN FOR SUPERINTENDENT OF PUBLIC INSTRUCTION 2026 EXPLORATORY COMMITTEE; LANCE',
   'name-only auto-link: Cal-Access 1462631 "CHRISTENSEN FOR SUPERINTENDENT OF PUBLIC INSTRUCTION 2026 EXPLORATORY COMMITTEE; LANCE" -- a campaign for Superintendent of Public Instruction, not for the Saugus Union SD board; no evidence its candidate ever sought or held a Saugus Union SD seat; this row is a CA_0159 no-evidence Saugus Union SD placeholder (deactivated)'),
  ('85734a74-5f13-4291-83b0-1185b2e0e1ac','fce14caa-e78a-4538-ae4f-8657f53430ed','la_socrata','1262901','needs_research',
   'Miller for Mayor',
   'surname-only auto-link: LA City committee "Miller for Mayor" -- LA City Ethics records the candidate as Addie Miller, Mayor of Los Angeles (2005); this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('2363ec12-55be-40a4-b01b-c7f0e40b6ad4','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1022479','needs_research',
   'REED FOR ASSEMBLY',
   'surname-only auto-link: Cal-Access 1022479 "REED FOR ASSEMBLY" -- a campaign for the State Assembly, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('47b1f7b5-a5f9-4915-ad4f-e32f549c5b94','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1065884','needs_research',
   'REED 1996, LARRY K., MEMBER OF THE STATE ASSEMBLY, DISTRICT 64',
   'surname-only auto-link: Cal-Access 1065884 "REED 1996, LARRY K., MEMBER OF THE STATE ASSEMBLY, DISTRICT 64" -- a campaign for the State Assembly (Larry K. Reed, District 64), not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('5962674e-ad62-43a0-9217-8edf20537442','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1227647','needs_research',
   'REED CITIZENS FOR',
   'surname-only auto-link: Cal-Access 1227647 "REED CITIZENS FOR" -- an Orange County committee (filer area code 949, terminated 2000); nothing ties it to a Lorene Reed or to Antelope Valley Joint Union HSD; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('98f7f68f-d21e-4a30-8d66-1ca3acbfeee2','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1238811','needs_research',
   'REED FOR SCHOOL BOARD',
   'surname-only auto-link: Cal-Access 1238811 "REED FOR SCHOOL BOARD" -- a Central Coast committee (filer area code 831); nothing ties it to a Lorene Reed or to Antelope Valley Joint Union HSD; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('e460bced-8a62-4cb3-a257-7827a923e349','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1250974','needs_research',
   'CITIZENS FOR REED SCHOOLS',
   'surname-only auto-link: Cal-Access 1250974 "CITIZENS FOR REED SCHOOLS" -- a Marin County committee (filer area code 415) whose name matches the Reed Union School District (Tiburon), not a person; nothing ties it to a Lorene Reed or to Antelope Valley Joint Union HSD; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('e987524c-544f-4c24-bee0-d73ed5ea5347','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1319525','needs_research',
   'REED FOR SCHOOL BOARD 09',
   'surname-only auto-link: Cal-Access 1319525 "REED FOR SCHOOL BOARD 09" -- a Central Valley committee (filer area code 209); nothing ties it to a Lorene Reed or to Antelope Valley Joint Union HSD; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('c781abdf-ffd7-4041-8cf7-16d20c15b884','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1345026','needs_research',
   'REED FOR CITY COUNCIL 2012',
   'surname-only auto-link: Cal-Access 1345026 "REED FOR CITY COUNCIL 2012" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('c0ff890e-f383-42ee-94af-5f2cf31c821a','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1347711','needs_research',
   'REED FOR COUNCIL 2012',
   'surname-only auto-link: Cal-Access 1347711 "REED FOR COUNCIL 2012" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('e77e79e9-f93c-4384-80c8-5a0949d91cce','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1369522','needs_research',
   'REED FOR COUNCIL 2022',
   'surname-only auto-link: Cal-Access 1369522 "REED FOR COUNCIL 2022" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('f28f08e1-d835-4a6b-93f1-756e2eb2c4bc','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1435617','needs_research',
   'REED FOR SANTA BARBARA CITY COUNCIL 2021',
   'surname-only auto-link: Cal-Access 1435617 "REED FOR SANTA BARBARA CITY COUNCIL 2021" -- a campaign for a city council (Santa Barbara), not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('6996bf05-2220-4eb3-bf12-9533a0b25f16','a7e73528-e586-479b-99b5-d5eaa0fc6f42','cal_access','1453983','needs_research',
   'REED FOR ATWATER ELEMENTARY SCHOOL BOARD - AREA 5 - 2022',
   'surname-only auto-link: Cal-Access 1453983 "REED FOR ATWATER ELEMENTARY SCHOOL BOARD - AREA 5 - 2022" -- a campaign for the board of a different school district, not for the Antelope Valley Joint Union HSD board; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('99c3a659-b13c-4ae9-aa89-5796083f243a','851b6001-b75d-4c50-82af-a7b9b816bb04','cal_access','1365047','needs_research',
   'BEASLEY FOR SUPERVISOR 2014',
   'surname-only auto-link: Cal-Access 1365047 "BEASLEY FOR SUPERVISOR 2014" -- a campaign for a county board of supervisors, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('e5cd47bf-daba-40d7-ae87-4d21f69897b5','d3a9f508-ebc5-4a7b-ba1a-8dc71827d720','cal_access','1310002','needs_research',
   'FELIX FOR SEASIDE COUNCIL',
   'surname-only auto-link: Cal-Access 1310002 "FELIX FOR SEASIDE COUNCIL" -- a campaign for a city council, not for the Hawthorne SD board; this row is a CA_0159 no-evidence Hawthorne SD placeholder (deactivated)'),
  ('c35e07f3-ebd8-42a8-b976-1c1dcb56da06','1d5c3afc-9614-4090-b083-3458f334a9be','cal_access','1241184','needs_research',
   'CHADWICK FOR JUDGE',
   'surname-only auto-link: Cal-Access 1241184 "CHADWICK FOR JUDGE" -- a campaign for a judgeship, not for the Sulphur Springs Union SD board; this row is a CA_0159 no-evidence Sulphur Springs Union SD placeholder (deactivated)'),
  ('25735a87-bb92-4444-a41b-72608948cd54','1d5c3afc-9614-4090-b083-3458f334a9be','cal_access','1244863','needs_research',
   'CHADWICK FOR PALOMAR COLLEGE GOVERNING BOARD 2012',
   'surname-only auto-link: Cal-Access 1244863 "CHADWICK FOR PALOMAR COLLEGE GOVERNING BOARD 2012" -- a campaign for a community college board, not for the Sulphur Springs Union SD board; this row is a CA_0159 no-evidence Sulphur Springs Union SD placeholder (deactivated)'),
  ('e21c5e75-ad45-4bfe-b173-799e7ec9534c','af7efbff-3408-4579-a6ba-f9c76c0590e9','cal_access','1331044','needs_research',
   'LAYNE FOR REDLANDS CITY COUNCIL 2010, MIKE',
   'name-only auto-link: Cal-Access 1331044 "LAYNE FOR REDLANDS CITY COUNCIL 2010, MIKE" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; no evidence its candidate ever sought or held an Antelope Valley Joint Union HSD seat; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('ea6bbecc-2078-481a-9998-15ec09551c04','af7efbff-3408-4579-a6ba-f9c76c0590e9','cal_access','1350760','needs_research',
   'LAYNE REDLANDS CITY COUNCIL 2012, COMMITTEE TO ELECT MIKE',
   'name-only auto-link: Cal-Access 1350760 "LAYNE REDLANDS CITY COUNCIL 2012, COMMITTEE TO ELECT MIKE" -- a campaign for a city council, not for the Antelope Valley Joint Union HSD board; no evidence its candidate ever sought or held an Antelope Valley Joint Union HSD seat; this row is a CA_0159 no-evidence Antelope Valley Joint Union HSD placeholder (deactivated)'),
  ('1ad15962-c5d7-4272-b9a0-c8b86d72bb64','2a3f478b-74fa-4077-b13a-794b947a5f21','cal_access','1283288','needs_research',
   'HARMON FOR SUPERVISOR DISTRICT 4',
   'surname-only auto-link: Cal-Access 1283288 "HARMON FOR SUPERVISOR DISTRICT 4" -- a campaign for a county board of supervisors, not for the Eastside Union SD board; this row is a CA_0159 no-evidence Eastside Union SD placeholder (deactivated)'),
  ('f2408643-d058-475e-8c95-c87576df11c7','2a3f478b-74fa-4077-b13a-794b947a5f21','cal_access','1288894','needs_research',
   'HARMON FOR SIERRA COLLEGE TRUSTEE',
   'surname-only auto-link: Cal-Access 1288894 "HARMON FOR SIERRA COLLEGE TRUSTEE" -- a campaign for a community college board, not for the Eastside Union SD board; this row is a CA_0159 no-evidence Eastside Union SD placeholder (deactivated)'),
  ('79e3dbf1-f3a6-4775-9d4a-e52952467a54','2a3f478b-74fa-4077-b13a-794b947a5f21','cal_access','1343275','needs_research',
   'HARMON FOR JUDGE 2012, DEPUTY D.A. ERIC',
   'surname-only auto-link: Cal-Access 1343275 "HARMON FOR JUDGE 2012, DEPUTY D.A. ERIC" -- a campaign for a judgeship (Eric Harmon), not for the Eastside Union SD board; this row is a CA_0159 no-evidence Eastside Union SD placeholder (deactivated)'),
  ('a0d15a79-9cf4-45f8-ad55-f35cab293e4f','2a3f478b-74fa-4077-b13a-794b947a5f21','cal_access','1382576','needs_research',
   'HARMON FOR COUNCIL 2016',
   'surname-only auto-link: Cal-Access 1382576 "HARMON FOR COUNCIL 2016" -- a campaign for a city council, not for the Eastside Union SD board; this row is a CA_0159 no-evidence Eastside Union SD placeholder (deactivated)'),
  ('d4a7fa6d-6da4-45ef-949b-481cf62958ec','27925c8c-5bfe-42c2-a46f-aa41352543dc','la_socrata','1416375','needs_research',
   'HENDERSON FOR LAUSD BOARD 2020',
   'surname-only auto-link: LA City committee "HENDERSON FOR LAUSD BOARD 2020" -- LA City Ethics records the candidate as Nichelle Henderson, LAUSD Board District 7 (2020); this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('06de137f-2717-400d-8e96-49ce5cb5fb7c','1480a0e8-082b-4157-8ebd-4876cf5644f7','la_socrata','1277206','needs_research',
   'Pacheco for City Council',
   'surname-only auto-link: LA City committee "Pacheco for City Council" -- LA City Ethics records the candidate as Nick Pacheco, Los Angeles City Council District 14 (2005 special election); this row is a CA_0159 no-evidence East Whittier City SD placeholder (deactivated)'),
  ('fbc50064-feee-42cd-a84a-5f9cf3b7875c','c3b5ba4c-92f1-4388-89d8-6d4ed9a1e944','cal_access','1274779','needs_research',
   'GARRISON, PEOPLE FOR PAUL',
   'surname-only auto-link: Cal-Access 1274779 "GARRISON, PEOPLE FOR PAUL" -- names a different person (Paul Garrison; filer area code 510, East Bay); this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('541903c2-63a1-49b8-843d-c13442889b71','093326fa-cf2e-4c6c-9522-66f7381b9e49','cal_access','1323317','needs_research',
   'GUZMAN FOR DISTRICT ATTORNEY - 2010',
   'surname-only auto-link: Cal-Access 1323317 "GUZMAN FOR DISTRICT ATTORNEY - 2010" -- a campaign for district attorney, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('cd4964bd-1505-4659-95f8-72d7aa7c315e','093326fa-cf2e-4c6c-9522-66f7381b9e49','cal_access','1352742','needs_research',
   'GUZMAN 4 SCHOOL BOARD 2012',
   'surname-only auto-link: Cal-Access 1352742 "GUZMAN 4 SCHOOL BOARD 2012" -- a Riverside County committee (filer area code 951); nothing ties it to a Rosario Guzman or to Mountain View SD; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('8cc29c23-88a3-4e85-804d-9ad547c0b0c7','093326fa-cf2e-4c6c-9522-66f7381b9e49','cal_access','1359935','needs_research',
   'GUZMAN FOR TRUSTEE AREA NO. 5 2013, COMMUNITY MEMBERS FOR GUADALUPE',
   'surname-only auto-link: Cal-Access 1359935 "GUZMAN FOR TRUSTEE AREA NO. 5 2013, COMMUNITY MEMBERS FOR GUADALUPE" -- names a different person (Guadalupe Guzman; filer area code 831, Central Coast); this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('796c2c32-5213-4420-866d-9305ea0a2fdf','093326fa-cf2e-4c6c-9522-66f7381b9e49','cal_access','1475601','needs_research',
   'GUZMAN FOR HIGH SCHOOL BOARD 2024',
   'surname-only auto-link: Cal-Access 1475601 "GUZMAN FOR HIGH SCHOOL BOARD 2024" -- a campaign for a high school board, not for the Mountain View SD board (an elementary district); the only 2024 LA County high-school-board candidate surnamed Guzman was Luis G. Guzman (El Monte Union HSD, Trustee Area 2; RR/CC list); this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('b090af2d-322f-4bf7-a5ee-423e62532311','093326fa-cf2e-4c6c-9522-66f7381b9e49','la_socrata','1438114','needs_research',
   'Christian L. Guzman for City Council 2022',
   'surname-only auto-link: LA City committee "Christian L. Guzman for City Council 2022" -- LA City Ethics records the candidate as Christian Guzman, Los Angeles City Council District 15 (2022); this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('1931a579-c41b-48b5-b2fa-e0ab61c53469','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1073615','needs_research',
   'SANTOS FOR BOARD OF EQUALIZATION',
   'surname-only auto-link: Cal-Access 1073615 "SANTOS FOR BOARD OF EQUALIZATION" -- a campaign for the State Board of Equalization, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('aebb177d-bdba-472f-85bf-abeea88ccc84','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1228325','needs_research',
   'SANTOS 4 SCHOOLS',
   'surname-only auto-link: Cal-Access 1228325 "SANTOS 4 SCHOOLS" -- a San Diego committee (filer area code 619); nothing ties it to a Sandy Santos or to Keppel Union SD; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('dde5f779-5d9e-43b2-ba0a-15cdc1b2416e','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1238251','needs_research',
   'SANTOS FOR BOARD OF EQUALIZATION 2002',
   'surname-only auto-link: Cal-Access 1238251 "SANTOS FOR BOARD OF EQUALIZATION 2002" -- a campaign for the State Board of Equalization, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('7bc13d62-66c1-4beb-818b-3219324dd6ca','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1249643','needs_research',
   'SANTOS FOR SCUSD',
   'surname-only auto-link: Cal-Access 1249643 "SANTOS FOR SCUSD" -- a campaign for the board of a different school district (SCUSD), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('d6653398-4688-4d6d-8886-d3a88b8191cc','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1281589','needs_research',
   'SANTOS FOR MAYOR',
   'surname-only auto-link: Cal-Access 1281589 "SANTOS MAYOR 2010, COMMITTEE TO RE-ELECT TONY" (stored as "SANTOS FOR MAYOR") -- a campaign for mayor (Tony Santos), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('26617cdf-cf55-4404-b99e-554a8da209ec','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1300685','needs_research',
   'SANTOS PARA BASSETT SCHOOL BOARD, FAMILIAS POR LAURA',
   'surname-only auto-link: Cal-Access 1300685 "SANTOS PARA BASSETT SCHOOL BOARD, FAMILIAS POR LAURA" -- a campaign for the board of a different school district (Bassett; Laura Santos), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('85261ca7-8e51-490e-9a6c-2caca419d3ee','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1333272','needs_research',
   'SANTOS FOR MAYOR 2010, COMMITTEE TO ELECT J. "CHAKA"',
   'surname-only auto-link: Cal-Access 1333272 "SANTOS FOR LATHROP MAYOR 2012, J. "CHAKA"" (stored as "SANTOS FOR MAYOR 2010, COMMITTEE TO ELECT J. "CHAKA"") -- a campaign for mayor (Lathrop), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('f06b2429-5c2e-4267-aa6a-7fc644fd3bb2','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1358657','needs_research',
   'SANTOS FOR MT SAC BOARD 2013',
   'surname-only auto-link: Cal-Access 1358657 "SANTOS FOR MT SAC BOARD 2013" -- a campaign for a community college board, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('2dcbb198-e664-43d4-83e1-629efae957d8','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1392773','needs_research',
   'SANTOS, OID DIVISION 4 DIRECTOR; COMMITTEE TO RECALL LINDA',
   'surname-only auto-link: Cal-Access 1392773 "SANTOS, OID DIVISION 4 DIRECTOR; COMMITTEE TO RECALL LINDA" -- a recall committee (to recall Linda Santos, an OID Division 4 director), not a campaign for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('eb7d6f14-2103-4cc0-9023-e2f97fc354d8','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1408713','needs_research',
   'SANTOS 4 MADERA CITY COUNCIL 2018',
   'surname-only auto-link: Cal-Access 1408713 "SANTOS 4 MADERA CITY COUNCIL 2018" -- a campaign for a city council (Madera), not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('bacba066-6593-4744-8282-5c3dce52113a','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1426721','needs_research',
   'SANTOS FOR WATER DISTRICT BOARD 2020',
   'surname-only auto-link: Cal-Access 1426721 "SANTOS FOR WATER DISTRICT BOARD 2020" -- a campaign for a water district board, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('e2bac141-35b7-4222-bfc9-d59fe3d4cf88','7b02ad38-18b8-42c1-bc8a-cc94509a1252','cal_access','1463182','needs_research',
   'SANTOS FOR WATER DISTRICT BOARD 2024',
   'surname-only auto-link: Cal-Access 1463182 "SANTOS FOR WATER DISTRICT BOARD 2024" -- a campaign for a water district board, not for the Keppel Union SD board; this row is a CA_0159 no-evidence Keppel Union SD placeholder (deactivated)'),
  ('4742d355-77b5-41dd-a5a5-587aae4f1616','61082cd9-f3ad-4179-ab00-2535a6b5f64a','cal_access','1324525','needs_research',
   'ZAVALA FOR COUNCIL 2010',
   'surname-only auto-link: Cal-Access 1324525 "ZAVALA FOR COUNCIL 2010" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('fd7ba9aa-2737-4abe-920d-806b1df229cc','61082cd9-f3ad-4179-ab00-2535a6b5f64a','cal_access','1403264','needs_research',
   'BAUTISTA ZAVALA FOR SCHOOL BOARD 2026',
   'surname-only auto-link: Cal-Access 1403264 "BAUTISTA ZAVALA FOR SCHOOL BOARD 2026" -- a Northern California committee (filer area code 530); the 2026 LA County candidates for Los Nietos SD are Evelyn Mendez Avdalyan, Bryan Galarza, Christian Ibarra, Catherine Martinez and Maritza Nieves (RR/CC list); nothing ties it to a Saul Zavala; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('3f5e437b-f014-4d91-bac1-6b404b8c62bf','61082cd9-f3ad-4179-ab00-2535a6b5f64a','cal_access','1458710','needs_research',
   'ZAVALA FOR CITY COUNCIL 2024',
   'surname-only auto-link: Cal-Access 1458710 "ZAVALA FOR CITY COUNCIL 2024" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('581e93a0-f9e0-404f-a7ce-e0fda620c251','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1073109','needs_research',
   'CAMPOS FOR SUPERVISOR 2010',
   'surname-only auto-link: Cal-Access 1073109 "CAMPOS FOR SUPERVISOR 2010" -- a campaign for a county board of supervisors, not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('e64b34f7-1ae7-44c5-9297-77af512bb9f0','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1272193','needs_research',
   'CAMPOS FOR CITY CLERK',
   'surname-only auto-link: Cal-Access 1272193 "CAMPOS FOR CITY CLERK" -- a campaign for city clerk, not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('dccf9abc-c270-4114-b2b1-503115b09f15','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1343996','needs_research',
   'CAMPOS FOR SUPERVISOR - 2012, COMMITTEE TO REELECT DAVID',
   'surname-only auto-link: Cal-Access 1343996 "CAMPOS FOR SUPERVISOR - 2012, COMMITTEE TO REELECT DAVID" -- a campaign for a county board of supervisors (David Campos), not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('323b60f6-85f0-4c15-902c-55b1eb180b07','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1365924','needs_research',
   'CARRASCO AND OPPOSING XAVIER CAMPOS FOR CITY COUNCIL 2014, SILICON VALLEY FRATERNAL ORDER OF POLICE SUPPORTING MAGDALENA',
   'surname-only auto-link: Cal-Access 1365924 "CARRASCO AND OPPOSING XAVIER CAMPOS FOR CITY COUNCIL 2014, SILICON VALLEY FRATERNAL ORDER OF POLICE SUPPORTING MAGDALENA" -- a campaign for a city council (Xavier Campos, opposed), not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('bda05179-8d43-4081-9061-aa980cd64d69','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1444025','needs_research',
   'CAMPOS FOR ASSEMBLY 2022, SPONSORED BY THE CALIFORNIA ASSOCIATION OF REALTORS; SAN FRANCISCANS FOR AFFORDABLE HOUSING AND SAFE STREETS OPPOSING',
   'surname-only auto-link: Cal-Access 1444025 "CAMPOS FOR ASSEMBLY 2022, SPONSORED BY THE CALIFORNIA ASSOCIATION OF REALTORS; SAN FRANCISCANS FOR AFFORDABLE HOUSING AND SAFE STREETS OPPOSING" -- a campaign for the State Assembly, not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('32b345c7-9d03-495a-bc32-92806cd5dafa','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1446415','needs_research',
   'CAMPOS FOR ASSEMBLY 2022',
   'surname-only auto-link: Cal-Access 1446415 "CAMPOS FOR ASSEMBLY 2022" -- a campaign for the State Assembly, not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('6240cbbc-b3da-4853-a0e2-ec9f472bb2ec','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1450255','needs_research',
   'CAMPOS FOR COUNCIL DISTRICT 1 2022; POLITICAL CANDIDATE ELECTION.ORG LIZ',
   'surname-only auto-link: Cal-Access 1450255 "CAMPOS FOR COUNCIL DISTRICT 1 2022; POLITICAL CANDIDATE ELECTION.ORG LIZ" -- a campaign for a city council (Liz Campos), not for the Centinela Valley Union HSD board; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('4914d5a7-d103-400e-aec6-263084daed20','3eaa5036-ec52-48ff-8111-73347db2bb18','cal_access','1450986','needs_research',
   'CAMPOS FOR TRUSTEE 2026',
   'surname-only auto-link: Cal-Access 1450986 "CAMPOS FOR TRUSTEE 2026" -- the 2026 LA County candidates for Centinela Valley Union HSD are Estefany Alejandra Castaneda, Hugo M. Rojas and Marisela Ruiz (RR/CC list); filer area code 909, not the Centinela Valley area; nothing ties it to a Sonia Campos; this row is a CA_0159 no-evidence Centinela Valley Union HSD placeholder (deactivated)'),
  ('39ae932e-cd27-4c8e-8738-bc69b843697f','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1069309','needs_research',
   'HARRIS SUPERIOR COURT CAMPAIGN COMMITTEE, JUDGE JOHN D.',
   'surname-only auto-link: Cal-Access 1069309 "HARRIS SUPERIOR COURT CAMPAIGN COMMITTEE, JUDGE JOHN D." -- a campaign for a judgeship (John D. Harris), not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('e9a85379-307c-4949-995d-4007a379be50','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1228920','needs_research',
   'HARRIS, COMMITTEE TO ELECT',
   'surname-only auto-link: Cal-Access 1228920 "HARRIS, COMMITTEE TO ELECT" -- a San Diego committee (filer area code 619); nothing ties it to a Stacy Harris or to Los Nietos SD; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('0b782a4e-79a5-4133-861d-1fe258ac55e6','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1236934','needs_research',
   'HARRIS FOR COUNCIL',
   'surname-only auto-link: Cal-Access 1236934 "HARRIS FOR COUNCIL" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('e63a2068-ae42-4d98-8396-b44870fb6ef8','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1249372','needs_research',
   'HARRIS, SR., COMMITTEE TO ELECT MICHAEL D. (MIKE)',
   'surname-only auto-link: Cal-Access 1249372 "HARRIS, SR., COMMITTEE TO ELECT MICHAEL D. (MIKE)" -- names a different person (Michael D. "Mike" Harris Sr.; filer area code 760); this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('d547ef7f-e7f0-418e-8987-23d61726bcdf','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1373611','needs_research',
   'HARRIS 4 CITY COUNCIL 2015',
   'surname-only auto-link: Cal-Access 1373611 "HARRIS 4 CITY COUNCIL 2015" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('a5c7ecdb-d042-4358-bc59-bb72fd86f5c1','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1381233','needs_research',
   'HARRIS CITY COUNCIL 2017; CITIZENS FOR DON',
   'surname-only auto-link: Cal-Access 1381233 "HARRIS CITY COUNCIL 2017; CITIZENS FOR DON" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('b98fc43e-c84d-405a-82a4-027b5fa77ffd','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1384074','needs_research',
   'HARRIS FOR MAYOR 2016',
   'surname-only auto-link: Cal-Access 1384074 "HARRIS FOR MAYOR 2016" -- a campaign for mayor, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('e5d17a03-5574-4255-998e-0fa1db519b4b','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1388521','needs_research',
   'ALAMEDANS UNITED SUPPORTING VELLA AND ASHCRAFT FOR CITY COUNCIL, BRATZLER FOR TREASURER, MC MAHON FOR AUDITOR, HARRIS AND HETTICH FOR SCHOOL BOARD 2016 SPONSORED BY PUBLIC SAFETY & LABOR ORGANIZATIONS',
   'surname-only auto-link: Cal-Access 1388521 "ALAMEDANS UNITED SUPPORTING VELLA AND ASHCRAFT FOR CITY COUNCIL, BRATZLER FOR TREASURER, MC MAHON FOR AUDITOR, HARRIS AND HETTICH FOR SCHOOL BOARD 2016 SPONSORED BY PUBLIC SAFETY & LABOR ORGANIZATIONS" -- a slate committee (Alameda city and school-board candidates; filer area code 510), not a campaign for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('aed5c843-cf7d-4dea-8cab-fa39ed8f3d9e','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1394543','needs_research',
   'HARRIS FOR CITY COUNCIL 2017',
   'surname-only auto-link: Cal-Access 1394543 "HARRIS FOR CITY COUNCIL 2017" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('338db065-b86b-43cd-aa67-3dab114ecb71','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1407198','needs_research',
   'HARRIS FOR MAYOR 2018',
   'surname-only auto-link: Cal-Access 1407198 "HARRIS FOR MAYOR 2018" -- a campaign for mayor, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('97c260ed-1c2a-49c6-a381-8b47cef8d33b','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1424039','needs_research',
   'HARRIS CITY COUNCIL DISTRICT 8 2020; ELECT',
   'surname-only auto-link: Cal-Access 1424039 "HARRIS CITY COUNCIL DISTRICT 8 2020; ELECT" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('012c820d-f13f-4158-b278-4d465410fd4d','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1425061','needs_research',
   'HARRIS DEL NORTE COUNTY SUPERINTENDENT OF SCHOOLS; COMMITTEE SUPPORTING THE RECALL 2020 OF JEFF',
   'surname-only auto-link: Cal-Access 1425061 "HARRIS DEL NORTE COUNTY SUPERINTENDENT OF SCHOOLS; COMMITTEE SUPPORTING THE RECALL 2020 OF JEFF" -- a recall committee (supporting the recall of Jeff Harris, Del Norte County Superintendent of Schools), not a campaign for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('1ee36d42-cb6f-4de1-8e88-83a2a464a777','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1433384','needs_research',
   'HARRIS FOR TDPUD BOARD 2020',
   'surname-only auto-link: Cal-Access 1433384 "HARRIS FOR TDPUD BOARD 2020" -- a campaign for a public utility district board, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('3c748ebe-7af9-4c00-b28b-08c5616075fd','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1464035','needs_research',
   'HARRIS FOR SUPERVISOR 2024',
   'surname-only auto-link: Cal-Access 1464035 "HARRIS FOR SUPERVISOR 2024" -- a campaign for a county board of supervisors, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('c2d3bd72-8624-462b-b1b3-d196ff5f21a3','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1466190','needs_research',
   'HARRIS FOR SB COUNTY SUPERVISOR, DISTRICT 1, 2024',
   'surname-only auto-link: Cal-Access 1466190 "HARRIS FOR SB COUNTY SUPERVISOR, DISTRICT 1, 2024" -- a campaign for a county board of supervisors, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('43f6f0ad-5c50-4f1b-8127-b8aef2b57984','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1466758','needs_research',
   'HARRIS FOR CITY COUNCIL 2024; COMMITTEE TO ELECT',
   'surname-only auto-link: Cal-Access 1466758 "HARRIS FOR CITY COUNCIL 2024; COMMITTEE TO ELECT" -- a campaign for a city council, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('81272031-1f41-4bc4-91a9-85f8014a3b2f','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1472845','needs_research',
   'HARRIS FOR SCHOOL BOARD 2024',
   'surname-only auto-link: Cal-Access 1472845 "HARRIS FOR SCHOOL BOARD 2024" -- a Contra Costa-area committee (filer area code 925); the 2024 LA County candidates for Los Nietos SD were Edith Marcel and Emilio Sosa (RR/CC list); nothing ties it to a Stacy Harris; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('8c438446-892d-4404-99b2-83746c40f6f2','f6a42150-82ed-4416-a3c6-fd8331324889','cal_access','1475810','needs_research',
   'HARRIS FOR BOARD OF SUPERVISORS 2026',
   'surname-only auto-link: Cal-Access 1475810 "HARRIS FOR BOARD OF SUPERVISORS 2026" -- a campaign for a county board of supervisors, not for the Los Nietos SD board; this row is a CA_0159 no-evidence Los Nietos SD placeholder (deactivated)'),
  ('9f1934ab-4e07-455b-8538-fd8c8ad092ce','ddc4b4df-7744-4ce2-8620-db2faeea86f2','cal_access','1456766','needs_research',
   'PENA FOR EL CENTRO ELEMENTARY SCHOOL DISTRICT 2022; COMMITTEE TO ELECT',
   'surname-only auto-link: Cal-Access 1456766 "PENA FOR EL CENTRO ELEMENTARY SCHOOL DISTRICT 2022; COMMITTEE TO ELECT" -- a campaign for the board of a different school district, not for the Mountain View SD board; this row is a CA_0159 no-evidence Mountain View SD placeholder (deactivated)'),
  ('879372c4-e08f-4662-b54b-e05f59ec97fc','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1299300','needs_research',
   'HUBER FOR ASSEMBLY',
   'surname-only auto-link: Cal-Access 1299300 "HUBER FOR ASSEMBLY" -- a campaign for the State Assembly, not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('a303aa89-3927-4847-815b-b1d17a63d6f2','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1314155','needs_research',
   'HUBER FOR ASSEMBLY 2010',
   'surname-only auto-link: Cal-Access 1314155 "HUBER FOR ASSEMBLY 2010" -- a campaign for the State Assembly, not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('28e83c0d-261f-491e-8b0c-3b252a8688d3','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1319989','needs_research',
   'HUBER, TAXPAYERS AGAINST THE WASTEFUL RECALL OF ALYSON',
   'surname-only auto-link: Cal-Access 1319989 "HUBER, TAXPAYERS AGAINST THE WASTEFUL RECALL OF ALYSON" -- a recall committee (against the recall of Alyson Huber), not a campaign for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('f76a2830-09ac-4383-8242-3a449594d271','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1319991','needs_research',
   'HUBER, TAXPAYERS AGAINST THE RECALL OF ALYSON',
   'surname-only auto-link: Cal-Access 1319991 "HUBER, TAXPAYERS AGAINST THE RECALL OF ALYSON" -- a recall committee (against the recall of Alyson Huber), not a campaign for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('c766f322-6083-4ba9-84d7-9e0f892ab810','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1325587','needs_research',
   'HUBER MAYOR 2010, PEOPLE FOR BOB',
   'surname-only auto-link: Cal-Access 1325587 "HUBER - MAYOR 2018, PEOPLE FOR BOB" (stored as "HUBER MAYOR 2010, PEOPLE FOR BOB") -- a campaign for mayor (Bob Huber), not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('a15cc377-509b-4938-b5dd-8458a16131e3','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1334275','needs_research',
   'HUBER FOR ASSEMBLY 2012',
   'surname-only auto-link: Cal-Access 1334275 "HUBER FOR ASSEMBLY 2012" -- a campaign for the State Assembly, not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('ecac5109-0572-4070-8ee8-7186b26c3fa1','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1344757','needs_research',
   'HUBER ASSEMBLY 2010 OFFICEHOLDER ACCOUNT',
   'surname-only auto-link: Cal-Access 1344757 "HUBER ASSEMBLY 2010 OFFICEHOLDER ACCOUNT" -- a campaign for the State Assembly (an officeholder account), not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('4761f8b1-9787-489c-b0b4-79bb286c4819','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1371111','needs_research',
   'MAC DONALD FOR MAYOR AND HUBER FOR CITY COUNCIL 2014, SPONSORED BY FIREFIGHTERS AND POLICE OFFICER ORGANIZATIONS; COMMITTEE FOR A SAFE AND PROSPEROUS OXNARD SUPPORTING',
   'surname-only auto-link: Cal-Access 1371111 "MAC DONALD FOR MAYOR AND HUBER FOR CITY COUNCIL 2014, SPONSORED BY FIREFIGHTERS AND POLICE OFFICER ORGANIZATIONS; COMMITTEE FOR A SAFE AND PROSPEROUS OXNARD SUPPORTING" -- a campaign for a city council (Oxnard), not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('aa180676-6cf5-44f6-9949-025ece4e749c','40b39473-5ed1-41b6-85c6-6d1aff569464','cal_access','1400662','needs_research',
   'HUBER - VENTURA COUNTY SUPERVISOR 4TH DISTRICT 2022; PEOPLE FOR BOB',
   'surname-only auto-link: Cal-Access 1400662 "HUBER - VENTURA COUNTY SUPERVISOR 4TH DISTRICT 2022; PEOPLE FOR BOB" -- a campaign for a county board of supervisors (Bob Huber, Ventura County), not for the Wilsona SD board; this row is a CA_0159 no-evidence Wilsona SD placeholder (deactivated)'),
  ('1eeaa1b0-70e7-4bfa-b3b6-2e331d6de10e','5cbff79d-99e2-4054-be57-07049ca1e3cf','cal_access','1313902','needs_research',
   'LIM FOR CITY COUNCIL',
   'surname-only auto-link: Cal-Access 1313902 "LIM FOR CITY COUNCIL 2013" (stored as "LIM FOR CITY COUNCIL") -- a campaign for a city council, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('fe8867a0-391a-4309-a7a0-dc18ba1a2620','5cbff79d-99e2-4054-be57-07049ca1e3cf','cal_access','1380277','needs_research',
   'LIM HCSD TRUSTEE 2015; COMMITTEE FOR',
   'surname-only auto-link: Cal-Access 1380277 "LIM HCSD TRUSTEE 2015; COMMITTEE FOR" -- a campaign for the board of a different school district, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)'),
  ('f636f4df-11ec-4df1-ba96-6a46f9eb7217','5cbff79d-99e2-4054-be57-07049ca1e3cf','cal_access','1383035','needs_research',
   'LIM FOR ALAMEDA COUNTY SUPERIOR COURT JUDGE 2016',
   'surname-only auto-link: Cal-Access 1383035 "LIM FOR ALAMEDA COUNTY SUPERIOR COURT JUDGE 2016" -- a campaign for a judgeship, not for the Garvey SD board; this row is a CA_0159 no-evidence Garvey SD placeholder (deactivated)');

-- the displayed total, before anything moves
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.research_status = 'confirmed') AS confirmed_total;


-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _link;
  IF v_n <> 180 THEN RAISE EXCEPTION 'PRE: _link holds %, expected 180', v_n; END IF;

  -- the population: exactly the 135 CA_0159 no-evidence rows, all deactivated placeholders
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%')
     AND NOT p.is_active AND p.source = 'scraped' AND p.data_source LIKE 'https://empowered.vote/school-district/%';
  IF v_n <> 135 THEN RAISE EXCEPTION 'PRE: % CA_0159 no-evidence placeholder rows, expected 135', v_n; END IF;

  -- each link is the recorded (row, system, committee id, stored committee name), still at its reviewed status
  -- (or already disputed by an earlier run of this file), on one of those rows
  SELECT count(*) INTO v_n FROM _link l
    JOIN transparent_motivations.politician_sources ps ON ps.id = l.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.essentials_politician_id = l.politician_id
     AND ps.source_system = l.source_system AND ps.external_id = l.external_id
     AND COALESCE(split_part(ps.notes, ' | ', 1)::jsonb ->> 'committee_name',
                  split_part(ps.notes, ' | ', 1)::jsonb ->> 'cmt_nm') = l.committee
     AND (ps.research_status = l.prior_status
          OR (ps.research_status = 'disputed' AND strpos(ps.notes, 'CA_0177 (2026-09-23)') > 0))
     AND NOT p.is_active
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 180 THEN RAISE EXCEPTION 'PRE: % of 180 links match their reviewed record on a CA_0159 no-evidence row', v_n; END IF;

  -- the review was complete: the only confirmed/needs_research link on those rows outside _link is the kept PORTILLO
  -- link. A link added since the review fails here instead of being left unreviewed.
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.research_status IN ('confirmed', 'needs_research')
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%')
     AND NOT EXISTS (SELECT 1 FROM _link l WHERE l.id = ps.id)
     AND NOT (ps.source_system = 'cal_access' AND ps.external_id = '1222359' AND ps.research_status = 'needs_research');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % confirmed/needs_research link(s) on CA_0159 no-evidence rows were not reviewed', v_n; END IF;
END $$;

-- ─── 1. Dispute the 180 links ─────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = CASE WHEN ps.notes IS JSON OBJECT
                    THEN (ps.notes::jsonb || jsonb_build_object('disputed_by', 'CA_0177 (2026-09-23)', 'disputed_reason', l.reason))::text
                    ELSE ps.notes || ' | DISPUTED by CA_0177 (2026-09-23): ' || l.reason END,
       updated_at = now()
  FROM _link l
 WHERE ps.id = l.id AND ps.research_status = l.prior_status;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric; v_ids uuid[];
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id
   WHERE ps.research_status = 'disputed'
     AND ((ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0177 (2026-09-23)' AND ps.notes::jsonb ->> 'disputed_reason' = l.reason)
          OR right(ps.notes, length(' | DISPUTED by CA_0177 (2026-09-23): ' || l.reason)) = ' | DISPUTED by CA_0177 (2026-09-23): ' || l.reason);
  IF v_n <> 180 THEN RAISE EXCEPTION 'POST: % of 180 links disputed with their reason', v_n; END IF;

  -- no confirmed committee on any CA_0159 no-evidence row, and the one needs_research link left is PORTILLO
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.research_status = 'confirmed'
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % confirmed link(s) on CA_0159 no-evidence rows', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.research_status = 'needs_research'
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % needs_research link(s) on CA_0159 no-evidence rows, expected 1 (PORTILLO)', v_n; END IF;

  -- disputed = CA_0166's 4 + these 180; this file never touches not_applicable (555 measured 2026-09-23)
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.research_status = 'disputed'
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 184 THEN RAISE EXCEPTION 'POST: % disputed links on CA_0159 no-evidence rows, expected 184 (4 CA_0166 + 180)', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.research_status = 'not_applicable'
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 555 THEN RAISE EXCEPTION 'POST: % not_applicable links on CA_0159 no-evidence rows, expected 555 (untouched)', v_n; END IF;

  -- no money hangs off these links, and nothing was deleted
  -- ids through an array, not a temp-table subquery: contributions is large and the planner has no stats on _link
  SELECT array_agg(id) INTO v_ids FROM _link;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = ANY (v_ids);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % contributions on the 180 sources, expected 0', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contribution_summary_agg WHERE politician_source_id = ANY (v_ids);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % aggregate rows on the 180 sources, expected 0', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.ingestion_runs WHERE politician_source_id = ANY (v_ids);
  IF v_n <> 25 THEN RAISE EXCEPTION 'POST: % ingestion_runs on the 180 sources, expected 25 (untouched)', v_n; END IF;

  -- the confirmed total did not move
  SELECT b.confirmed_total - (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                               JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                              WHERE ps.research_status = 'confirmed')
    INTO v_amt FROM _before b;
  IF v_amt <> 0 THEN RAISE EXCEPTION 'POST: the confirmed total moved by %, expected 0', v_amt; END IF;

  RAISE NOTICE 'CA_0177 applied: 180 wrong committee links disputed on CA_0159 no-evidence rows; PORTILLO kept; no money moved';
END $$;

COMMIT;
