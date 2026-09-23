-- CA_0159_la_elem_high_unsourced_holder_audit.sql
-- Audit and clean up the 143 politician rows that the unsourced "school-district" seeding pass put on 31
-- LA County ELEMENTARY and HIGH-SCHOOL district boards (data_source
-- 'https://empowered.vote/school-district/<name>', not '%unified'). CA_0158 closed their stale terms and
-- seated the verified boards; this file decides, row by row, what those people ARE. Same method, classes
-- and operator rulings as CA_0156 (the unified-board audit). REQUIRES CA_0158 to be applied first.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML; the archive table
-- essentials._fabricated_ca0156_removed already exists, so no DDL).
--
-- ---------------------------------------------------------------------------------------------------
-- A. PROVENANCE -- why these rows are suspect
-- ---------------------------------------------------------------------------------------------------
-- All 143 carry source 'scraped', external_id -201856..-202369 (the same pass as the 238 unified rows),
-- a placeholder data_source, party 'Nonpartisan', and a migration-1459 NULL/NULL term. Of the 143 names,
-- only 5 appear on any LA County RR/CC school candidate list 2017-2026, and only 4 ever served.
--
-- ---------------------------------------------------------------------------------------------------
-- B. EVIDENCE GATHERED 2026-09-22 (per-row table: data/roster-audits/2026-09-22-la-elem-high-unsourced-holders-CA_0159.csv)
-- ---------------------------------------------------------------------------------------------------
--   * LA County RR/CC candidate lists Nov 2017 - Nov 2026 (lavote.gov/Apps/CandidateList, 21 elections),
--     and the candidate names of EVERY contest in all 73 RR/CC elections 2013-2026
--     (results.lavote.gov /ElectionResults/GetElectionData, read in a browser), matched per name.
--   * Each district's own board page and its Wayback snapshots (most districts back to 2008-2012),
--     BoardDocs / Simbli minutes, Ballotpedia, AV Press, Santa Clarita Signal, Whittier Daily News.
--   * inform.politician_answers / politician_context / politician_context_evidence / evidence_items:
--     ZERO rows for all 143 -- deactivating anyone orphans no stance data (asserted below).
--   Limit: general web search was unavailable this session (Bing ignored quoted names; other engines
--   showed captchas), so the name checks rest on rosters, minutes, county lists and local-news site
--   search rather than one web search per name.
--
-- ---------------------------------------------------------------------------------------------------
-- C. CLASSES AND WHAT HAPPENS TO EACH (every class: party and party_short_name -> NULL; antipartisan)
-- ---------------------------------------------------------------------------------------------------
--   A1   3  REAL, CURRENT -- Hart TA2 Bob Jensen, TA3 Cherise Moore, TA5 Joe Messina: on the Hart board
--           page ("current term 2022 - 2026") and RR/CC winners 2018 and 2022. CA_0158 kept their open
--           terms. Party only.
--   A2   1  REAL, FORMER -- Jeff Baird, Whittier Union High, Dec 1997 - Dec 2022 (Whittier Daily News
--           2022-08-21; RR/CC 3752 elected incumbent, won Nov 2017). CA_0158 closed his term with
--           'term_expired'. Row stays active, is_incumbent false, evidence appended to the term source.
--   B  135  NO EVIDENCE -- deactivated (is_active false, is_incumbent false). Closed term KEPT (absence is
--           not disproof -- 1588/1590) but tagged '| unverified CA_0159' in its source. Includes name-only
--           matches that are NOT disproof: Jose Lara (an El Rancho USD trustee, 2018), Jose Rios (a
--           Norwalk-La Mirada USD candidate), Lance Christensen (a 2022 statewide candidate), Maria Mendez
--           (a losing Whittier Union candidate in 2017 and a losing 2022 write-in -- ran, never seated).
--   C    4  DISPROVED -- the person is documented in a DIFFERENT office (the CA_0156 C1 standard: Sho Tay,
--           Tim Goodrich, Darcy McNaboe, Carl Coles). Term row archived to essentials._fabricated_ca0156_removed
--           (reason 'CA_0159: ...') and DELETED; row deactivated and retained.
--           Arturo Flores (Centinela)  Huntington Park City Council member / Mayor 2025; the row's headshot
--                                      is his Huntington Park council portrait
--           Thomas Bakaly (Hermosa)    Hermosa Beach City Manager
--           Colleen Hawkins (Castaic)  Saugus Union SD superintendent
--           Margarita Rios (Little Lake) Mayor / City Council member of Norwalk (RR/CC 4085 ballot title
--                                      "Mayor/Police Sergeant"); the district serves part of Norwalk
--
-- ---------------------------------------------------------------------------------------------------
-- D. ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   * Deleted terms: INSERT INTO essentials.office_terms SELECT id, office_id, politician_id, term_start,
--     term_end, start_precision, how_started, how_ended, source, created_at
--     FROM essentials._fabricated_ca0156_removed WHERE reason LIKE 'CA_0159%';
--   * Tags: strip the ' | verified CA_0159 ...' / ' | unverified CA_0159 ...' suffix from source, and drop
--     the notes element starting 'CA_0159'.
--   * Flags: is_active back to true on the 139 B/C rows. Party was 'Nonpartisan' on all 143; restoring it
--     is not recommended. is_incumbent was already false after CA_0158 (except A1, still true).
--
-- NOT DONE HERE: the headshots on 9f43110f (Arturo Flores -- a real Huntington Park official's portrait)
-- and 74257677 (Antonio Castro -- a Moorpark candidate's photo) stay on the deactivated rows, which no
-- longer display; the wrong politician_sources links 'confirmed' on four B rows (Dolores Santiago ->
-- "MIGUEL SANTIAGO FOR CITY COUNCIL 2024", Gale Reyes -> "Eddie Reyes for City Council", Joe Renteria ->
-- "RENTERIA FOR LYNWOOD SCHOOL BOARD 2018", Lance Christensen -> "CHRISTENSEN FOR SCHOOL BOARD, LANCE")
-- are left for the campaign-finance owners.
--
-- IDEMPOTENT: every UPDATE is guarded on the value it changes; the archive insert and the delete are
-- keyed on the term id; a re-run is a no-op and the post-verify gate still passes.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _a (politician_id uuid PRIMARY KEY, full_name text, cls text, district text, evidence text) ON COMMIT DROP;
INSERT INTO _a VALUES
  ('d304c0d7-f0ad-49fd-8252-87e86ca93c53'::uuid, 'Bob Jensen', 'A1', 'William S. Hart Union High School District', ''),
  ('41076964-edd9-4e7b-866f-79680545bb2c'::uuid, 'Cherise Moore', 'A1', 'William S. Hart Union High School District', ''),
  ('4cee37b3-76a5-40f8-ad03-f30be18886aa'::uuid, 'Joe Messina', 'A1', 'William S. Hart Union High School District', ''),
  ('84c5018c-bd47-41df-8192-64d1ace15712'::uuid, 'Jeff Baird', 'A2', 'Whittier Union High School District', 'Whittier Daily News 2022-08-21: "in the November 1997 election, challengers Leighton Anderson, Jeff Baird and Alex Morales were elected ... Anderson and Baird have remained on the board" until they did not seek re-election in 2022; RR/CC 3752 (Nov 2017) JEFF BAIRD elected incumbent, won (3rd of 3 seats, 4,801 votes); service Dec 1997 - Dec 2022'),
  ('823e3a9a-f135-4014-91cf-2b947f03f256'::uuid, 'Colleen Hawkins', 'C', 'Castaic Union School District', 'documented as superintendent of the neighbouring Saugus Union SD, not a Castaic trustee: saugususd.org/our-administration (Wayback 2022) "Colleen Hawkins, Ed.D. Superintendent"; absent from every Castaic roster 2008-2026'),
  ('9f43110f-23e1-45ab-b264-9f079720892f'::uuid, 'Arturo Flores', 'C', 'Centinela Valley Union High School District', 'documented as a Huntington Park City Council member, not a Centinela Valley trustee: hpca.gov/directory.aspx?EID=177 "Council Member Arturo Flores joined the Huntington Park City Council in 2022 and was selected by his colleagues in March 2025 to serve as Mayor"; RR/CC 4316 (Mar 2024) lists ARTURO FLORES, Councilman, City of Huntington Park; this rows headshot is that council portrait; absent from every Centinela Valley roster 2009-2026'),
  ('9515abde-bac7-427b-88e9-9c866dc0a968'::uuid, 'Thomas Bakaly', 'C', 'Hermosa Beach City School District', 'documented as the Hermosa Beach City Manager, not a school trustee: hermosabch.org (Wayback 20150209174223) "City of Hermosa Beach City Manager: Tom Bakaly"; absent from every Hermosa Beach City SD roster seen and every RR/CC list 2017-2026'),
  ('c83403a8-2c30-4b6e-a97c-1faf8aebf43f'::uuid, 'Margarita Rios', 'C', 'Little Lake City School District', 'documented as Mayor / City Council member of Norwalk (Little Lake City SD serves part of Norwalk): RR/CC candidate list 4085 (Mar 2020) "MARGARITA L. RIOS Mayor/Police Sergeant ... NORWALK", Norwalk City Council; also filed Mar 2017 (special) and Nov 2024; absent from every Little Lake roster 2007-2026'),
  ('b4a1311d-edab-44c9-81fb-05923f998753'::uuid, 'Adyson Quashie', 'B', 'Antelope Valley Joint Union High School District', ''),
  ('8c145930-0af7-4cfc-b959-06a2a394e11e'::uuid, 'Dr. Kathleen Lang', 'B', 'Antelope Valley Joint Union High School District', ''),
  ('c965c628-5fa7-44d2-b299-59e49eff3ece'::uuid, 'Jim Gilbert', 'B', 'Antelope Valley Joint Union High School District', ''),
  ('a7e73528-e586-479b-99b5-d5eaa0fc6f42'::uuid, 'Lorene Reed', 'B', 'Antelope Valley Joint Union High School District', ''),
  ('af7efbff-3408-4579-a6ba-f9c76c0590e9'::uuid, 'Michael Layne', 'B', 'Antelope Valley Joint Union High School District', ''),
  ('2183063b-a86b-49da-bf0b-44799d0a15b1'::uuid, 'Kimberly Tresvant', 'B', 'Castaic Union School District', ''),
  ('bc17004c-5edb-429d-a585-182b4db29c26'::uuid, 'Lisa Zellhart', 'B', 'Castaic Union School District', ''),
  ('62eff385-96e5-4b35-8383-55bd7e2cbe28'::uuid, 'Mindi Lauro', 'B', 'Castaic Union School District', ''),
  ('f90049fb-23a9-41ad-b4da-49ef4ef518d4'::uuid, 'Randell Herr', 'B', 'Castaic Union School District', ''),
  ('4c76e59e-fd86-4534-ac05-9281ee4aa776'::uuid, 'Javier Gonzalez', 'B', 'Centinela Valley Union High School District', ''),
  ('27925c8c-5bfe-42c2-a46f-aa41352543dc'::uuid, 'Natasha Henderson', 'B', 'Centinela Valley Union High School District', ''),
  ('3eaa5036-ec52-48ff-8111-73347db2bb18'::uuid, 'Sonia Campos', 'B', 'Centinela Valley Union High School District', ''),
  ('d50ad38d-ed64-45ac-b3c3-cf4e0f6ac788'::uuid, 'Andy Torres', 'B', 'East Whittier City School District', ''),
  ('421390dd-e2cf-492b-bdd7-d5053a719592'::uuid, 'Kathleen Ruane', 'B', 'East Whittier City School District', ''),
  ('1480a0e8-082b-4157-8ebd-4876cf5644f7'::uuid, 'Patty Pacheco', 'B', 'East Whittier City School District', ''),
  ('c1f47e52-3f0f-4dcb-9421-a14b8daab0db'::uuid, 'Scott Hernandez', 'B', 'East Whittier City School District', ''),
  ('db1606e1-817f-4071-85d9-7d60ff31edd1'::uuid, 'Suzy Moore', 'B', 'East Whittier City School District', ''),
  ('cccd245f-2b48-4360-b0f7-e9e2affb8921'::uuid, 'Lupe Trujillo', 'B', 'Eastside Union School District', ''),
  ('235bc16f-a70d-4bbb-891c-562580540b16'::uuid, 'Michael Lara', 'B', 'Eastside Union School District', ''),
  ('2a3f478b-74fa-4077-b13a-794b947a5f21'::uuid, 'Monica Harmon', 'B', 'Eastside Union School District', ''),
  ('b8e52d93-7468-4fda-ab9e-a4b0e1477255'::uuid, 'Trina Stringer', 'B', 'Eastside Union School District', ''),
  ('3f06b286-4c26-4a01-a29c-88a0e1145bb1'::uuid, 'Alma Guerrero', 'B', 'El Monte City School District', ''),
  ('c043a9b5-ebc1-4a58-8c0d-0125744767c8'::uuid, 'Ana Ponce', 'B', 'El Monte City School District', ''),
  ('1b7900b6-50b5-4c43-ba3b-673fbf0fe02d'::uuid, 'Gloria Corrales', 'B', 'El Monte City School District', ''),
  ('40b52e27-5ad5-48af-93dd-5d8a625746f6'::uuid, 'Rosemarie Lopez', 'B', 'El Monte City School District', ''),
  ('b27b616c-88d6-4288-afd3-80d7e60ba46b'::uuid, 'Yvette Jimenez', 'B', 'El Monte City School District', ''),
  ('6fab21ef-c66e-4fff-afb6-93e1ec7c5c2f'::uuid, 'Emma Turner', 'B', 'El Monte Union High School District', ''),
  ('c97d6025-84bf-44be-aa50-90fbe1029b4c'::uuid, 'Ingrid González', 'B', 'El Monte Union High School District', ''),
  ('6485f5ef-6df0-48b7-8f66-8e7a53693435'::uuid, 'Jose Lara', 'B', 'El Monte Union High School District', ''),
  ('1eb2e102-323a-4852-8366-ba68681d361c'::uuid, 'Maria Elena Martinez', 'B', 'El Monte Union High School District', ''),
  ('9ce4fa5c-4884-45aa-bd8e-b0fd7257c6ee'::uuid, 'Xochitl Flores', 'B', 'El Monte Union High School District', ''),
  ('416b3a99-371f-4125-95d5-ee693877d76d'::uuid, 'Jonathan Contreras', 'B', 'Garvey School District', ''),
  ('5f6d627f-0916-4b20-9d70-58923c8e344e'::uuid, 'Kimberly Martinez', 'B', 'Garvey School District', ''),
  ('c4e6fe44-6eff-4674-b8b4-185de72a4d39'::uuid, 'Maggie Cheung-Lim', 'B', 'Garvey School District', ''),
  ('47e3c1cf-c57e-49b6-92e7-e98fd642623e'::uuid, 'Teresa Srisiri', 'B', 'Garvey School District', ''),
  ('5cbff79d-99e2-4054-be57-07049ca1e3cf'::uuid, 'Tina Lim', 'B', 'Garvey School District', ''),
  ('5562b788-c13f-4f4d-87c4-521e271059e9'::uuid, 'Anna Wren', 'B', 'Gorman Joint School District', ''),
  ('26ae5f79-9ec5-4b3f-8b9e-dc2caaa71101'::uuid, 'Crystal Sherrill', 'B', 'Gorman Joint School District', ''),
  ('03d9147a-4402-474a-ac7e-8e70022f58dd'::uuid, 'Sharon Caughey', 'B', 'Gorman Joint School District', ''),
  ('74257677-b02b-42db-835d-467b01112b3f'::uuid, 'Antonio Castro', 'B', 'Hawthorne School District', ''),
  ('ab063dea-0ed6-450e-9a19-eb3a6a6e5da9'::uuid, 'James Moore', 'B', 'Hawthorne School District', ''),
  ('201e0365-8301-40f7-83bb-2292445fcb78'::uuid, 'Lisa Williams', 'B', 'Hawthorne School District', ''),
  ('d3a9f508-ebc5-4a7b-ba1a-8dc71827d720'::uuid, 'Maria Felix', 'B', 'Hawthorne School District', ''),
  ('ec31be2a-2151-48d8-9d40-3cf767836874'::uuid, 'Sarah Garcia', 'B', 'Hawthorne School District', ''),
  ('c5a12549-9b81-4013-b747-bbc7a4fca3f3'::uuid, 'Jeffrey Reinhart', 'B', 'Hermosa Beach City School District', ''),
  ('6804f05a-f30b-425f-a4e8-5919f510b024'::uuid, 'Joanna Ruelas', 'B', 'Hermosa Beach City School District', ''),
  ('f712f1e9-2b98-44d8-b552-917b034241c6'::uuid, 'Kellie Kennedy', 'B', 'Hermosa Beach City School District', ''),
  ('3e2c9417-79c0-4666-bff1-85b9b8237631'::uuid, 'Lea Liwanag', 'B', 'Hermosa Beach City School District', ''),
  ('288499db-64df-4c1f-ada4-9b94af531a34'::uuid, 'Dawn Snyder', 'B', 'Hughes-Elizabeth Lakes Union School District', ''),
  ('d3eebfad-b395-4180-8562-941dbb8cecb0'::uuid, 'Jeremy Williams', 'B', 'Hughes-Elizabeth Lakes Union School District', ''),
  ('2a954d75-5a34-4753-b508-be66799bc760'::uuid, 'Dolores Santiago', 'B', 'Keppel Union School District', ''),
  ('4352b2da-86fd-4435-a0f0-247972d34f38'::uuid, 'Eloisa Lopez', 'B', 'Keppel Union School District', ''),
  ('87b39a44-75b3-4395-a4a3-974b288c6047'::uuid, 'Jose Garcia', 'B', 'Keppel Union School District', ''),
  ('8f32c725-c14c-493a-a1c8-1f03fbd7f5ad'::uuid, 'Mark Brown', 'B', 'Keppel Union School District', ''),
  ('7b02ad38-18b8-42c1-bc8a-cc94509a1252'::uuid, 'Sandy Santos', 'B', 'Keppel Union School District', ''),
  ('391778af-fd7e-4e77-9998-08af8c645a4c'::uuid, 'Guadalupe Romero', 'B', 'Lancaster School District', ''),
  ('aa1cf148-3ad0-4295-924c-11ac69157685'::uuid, 'Joe Renteria', 'B', 'Lancaster School District', ''),
  ('589045c8-eb1e-44bc-b4f5-d4169b6892c0'::uuid, 'Kelly Talbert', 'B', 'Lancaster School District', ''),
  ('1302f537-1f51-4252-8567-12098983781b'::uuid, 'Laquita Moore', 'B', 'Lancaster School District', ''),
  ('c3b5ba4c-92f1-4388-89d8-6d4ed9a1e944'::uuid, 'Renee Garrison', 'B', 'Lancaster School District', ''),
  ('76e70bf9-f53e-4fcc-95c5-e0e268b318c1'::uuid, 'Diana Hernandez', 'B', 'Lawndale Elementary School District', ''),
  ('f0fbf466-3a1e-4a8d-be0f-d22fffbce140'::uuid, 'Paula Maybury', 'B', 'Lawndale Elementary School District', ''),
  ('6be2af76-7c14-4a06-a207-736df411221d'::uuid, 'Randolph Love', 'B', 'Lawndale Elementary School District', ''),
  ('716a22b3-5726-4147-92f1-5e6c44c84d81'::uuid, 'Robert Pulley', 'B', 'Lawndale Elementary School District', ''),
  ('9d32e71f-4a9b-4adc-9b9f-15679e4841aa'::uuid, 'Robert Sherrill', 'B', 'Lawndale Elementary School District', ''),
  ('c123ba35-f671-4e76-82bd-f90ae5aabfa0'::uuid, 'Alberto Guerrero', 'B', 'Lennox School District', ''),
  ('5d970ad1-ab54-4927-843d-de7c92539b8e'::uuid, 'Ana Paula Cruz', 'B', 'Lennox School District', ''),
  ('7a441141-a7bc-430f-8a0a-a87773a49368'::uuid, 'Carlos Cuevas', 'B', 'Lennox School District', ''),
  ('be22dba0-3dcd-49ad-92e5-a0c4326f0f4a'::uuid, 'Guadalupe Guzmán-Guerrero', 'B', 'Lennox School District', ''),
  ('acef6548-15ea-42fd-b9a4-7fb772929634'::uuid, 'Yahaira Rodriguez', 'B', 'Lennox School District', ''),
  ('a1643116-8ce4-495a-bcf0-2a967e17230f'::uuid, 'Claudia Hernandez', 'B', 'Little Lake City School District', ''),
  ('65ad8e41-d69f-4c8d-a612-7083afe8cf5f'::uuid, 'Elias Gonzalez', 'B', 'Little Lake City School District', ''),
  ('3e899452-b609-4aee-97ca-e5544a76c708'::uuid, 'Joe Zertuche', 'B', 'Little Lake City School District', ''),
  ('836583ca-b6cd-4871-a341-cb8fa5ecf64b'::uuid, 'Tony Oseguera', 'B', 'Little Lake City School District', ''),
  ('d44a17ee-02e2-42e2-89ae-9da222037dd1'::uuid, 'Irma Herrera', 'B', 'Los Nietos School District', ''),
  ('3d8bb339-b2d0-471d-a169-62713d1eb8a6'::uuid, 'Maria Carmona', 'B', 'Los Nietos School District', ''),
  ('61082cd9-f3ad-4179-ab00-2535a6b5f64a'::uuid, 'Saul Zavala', 'B', 'Los Nietos School District', ''),
  ('f6a42150-82ed-4416-a3c6-fd8331324889'::uuid, 'Stacy Harris', 'B', 'Los Nietos School District', ''),
  ('0e7799b3-1ecd-4252-808a-10691f3cb5e3'::uuid, 'Tonia Moats-Mendez', 'B', 'Los Nietos School District', ''),
  ('91b3fdfd-9908-495e-86c6-e2d523982e15'::uuid, 'David Aguirre', 'B', 'Mountain View School District', ''),
  ('97ce03cc-d559-40b0-ad60-e088b6628411'::uuid, 'Karla Ruiz', 'B', 'Mountain View School District', ''),
  ('851b6001-b75d-4c50-82af-a7b9b816bb04'::uuid, 'Maria Beasley', 'B', 'Mountain View School District', ''),
  ('093326fa-cf2e-4c6c-9522-66f7381b9e49'::uuid, 'Rosario Guzman', 'B', 'Mountain View School District', ''),
  ('ddc4b4df-7744-4ce2-8620-db2faeea86f2'::uuid, 'Steve Pena', 'B', 'Mountain View School District', ''),
  ('4e1915ca-20d8-49e0-aa5d-af15a5e85f44'::uuid, 'Deb Hartwell', 'B', 'Newhall School District', ''),
  ('7cdc98c6-a511-487d-a641-1c2b1aeee8ba'::uuid, 'Janet Zappone', 'B', 'Newhall School District', ''),
  ('6c9abc89-f26c-4ead-a98c-abcc2abe5c50'::uuid, 'Jeff Hearn', 'B', 'Newhall School District', ''),
  ('59874680-6d08-41e5-a87f-9f946ec98b35'::uuid, 'Lindsey Cardenas', 'B', 'Newhall School District', ''),
  ('c909d75a-7da3-4679-b360-b68d3d2c38f9'::uuid, 'Ryan Sherring', 'B', 'Newhall School District', ''),
  ('2376dcb8-0374-49de-b041-88035ed3c9f4'::uuid, 'Angela Portillo', 'B', 'Palmdale School District', ''),
  ('8a0d4875-70b5-4678-badb-4e1b8caa432c'::uuid, 'Claudia Valenzuela', 'B', 'Palmdale School District', ''),
  ('ccf4cf8f-30b7-48ba-a610-07ccd10a6e78'::uuid, 'Maria Garcia', 'B', 'Palmdale School District', ''),
  ('6dab5ac4-59ef-47c3-8b38-9fa416831041'::uuid, 'Stephanie Davis', 'B', 'Palmdale School District', ''),
  ('a6c61934-8f51-44f2-946b-7df4d1ba31d2'::uuid, 'Yvonne Ghandchi', 'B', 'Palmdale School District', ''),
  ('3ed8f158-6f91-4e96-9181-09e4783c010c'::uuid, 'Jay Imperial', 'B', 'Rosemead School District', ''),
  ('e771a832-0b22-4788-8c40-d314898dfeeb'::uuid, 'Sandra Herrera', 'B', 'Rosemead School District', ''),
  ('3548fca1-d0d3-402c-a69b-4292382dc6cf'::uuid, 'Tara Ly', 'B', 'Rosemead School District', ''),
  ('ee672e7d-063a-4803-a7cc-96522e2529ab'::uuid, 'Teresa Pimentel', 'B', 'Rosemead School District', ''),
  ('d6e8aae4-9dca-4594-9caf-03c374092d47'::uuid, 'Doree Frome', 'B', 'Saugus Union School District', ''),
  ('c471d672-413b-42ef-862b-2acf76e8c000'::uuid, 'Gale Reyes', 'B', 'Saugus Union School District', ''),
  ('713aba1d-06cc-4631-97b5-de89302df717'::uuid, 'Lance Christensen', 'B', 'Saugus Union School District', ''),
  ('b12d15ac-a768-4aca-a4d2-4377eabbab1b'::uuid, 'Steve Summy', 'B', 'Saugus Union School District', ''),
  ('aa99212b-41fc-484a-a7cd-20b65c1ed751'::uuid, 'Gloria Ornelas', 'B', 'South Whittier School District', ''),
  ('0ae3edf9-e0ce-43b2-8950-3ec5de00e43e'::uuid, 'Monica Hernandez', 'B', 'South Whittier School District', ''),
  ('5622c1c2-3ba1-4695-a691-7c564af304d0'::uuid, 'Norma Lopez', 'B', 'South Whittier School District', ''),
  ('9c4191fc-8460-43ca-9a18-29c4251abba9'::uuid, 'Raymond Cazarez', 'B', 'South Whittier School District', ''),
  ('b7e2ec3f-d1e8-44c9-94d6-7d89c5daaf54'::uuid, 'Santos Garcia', 'B', 'South Whittier School District', ''),
  ('c5a9c6f7-c0f1-477f-b078-23bf17e54709'::uuid, 'Danielle Zefferino', 'B', 'Sulphur Springs Union School District', ''),
  ('265f1d35-3b92-48b3-b68d-fc34b0681f96'::uuid, 'Judy Fearing', 'B', 'Sulphur Springs Union School District', ''),
  ('d46e969c-5a86-4a9f-aa58-6bbc633a2d92'::uuid, 'Marty Steckel', 'B', 'Sulphur Springs Union School District', ''),
  ('1d5c3afc-9614-4090-b083-3458f334a9be'::uuid, 'Mary Chadwick', 'B', 'Sulphur Springs Union School District', ''),
  ('38066707-6a62-40b8-a749-a94823c58326'::uuid, 'Melissa Linton', 'B', 'Sulphur Springs Union School District', ''),
  ('6b5b7342-cb31-4e47-9367-97cc363acd1f'::uuid, 'Adela Martinez', 'B', 'Valle Lindo School District', ''),
  ('f1a78f8e-85b9-459c-91b1-0091dc6cfb27'::uuid, 'Guillermo Gutierrez', 'B', 'Valle Lindo School District', ''),
  ('b1078a3e-d578-49a4-a3b9-88e7fc97df2d'::uuid, 'Jose Rios', 'B', 'Valle Lindo School District', ''),
  ('0e216216-3902-4217-944e-01defde50d1b'::uuid, 'Margarita Lopez', 'B', 'Valle Lindo School District', ''),
  ('84bd92c2-dd7a-470a-a6d1-d4b6f4808842'::uuid, 'Monica Torres', 'B', 'Valle Lindo School District', ''),
  ('b615a7a7-443f-4490-84a5-040116bd1708'::uuid, 'Cassie Thomas', 'B', 'Westside Union School District', ''),
  ('a4af047c-985c-4deb-9718-d4bfce2871a0'::uuid, 'John Valles', 'B', 'Westside Union School District', ''),
  ('81f85c7b-7abf-4b9e-80f0-38daf0d48fba'::uuid, 'Joseph Crawford', 'B', 'Westside Union School District', ''),
  ('c3c75a0a-6555-4058-a75f-cd14132c8d7a'::uuid, 'Kelly Kizer', 'B', 'Westside Union School District', ''),
  ('12c889ee-fe4c-4f02-aba8-54f27476ce45'::uuid, 'Sandy Derrick', 'B', 'Westside Union School District', ''),
  ('c3dc758d-378f-4867-91c1-00422760ef54'::uuid, 'Danny Argueta', 'B', 'Whittier City School District', ''),
  ('fb8d85f1-105d-453b-beda-fed70bde0cac'::uuid, 'Felipe Moran', 'B', 'Whittier City School District', ''),
  ('247a40d7-e641-4e90-9110-67c311c6d3f4'::uuid, 'Joe Ramos', 'B', 'Whittier City School District', ''),
  ('7fda4a85-279d-4fa1-b941-dfa98097a3c5'::uuid, 'Mary Pinkney', 'B', 'Whittier City School District', ''),
  ('242c68a1-7d99-4a0f-83b3-878b145f2522'::uuid, 'Monica Ayala', 'B', 'Whittier City School District', ''),
  ('5db21599-5f8e-4f08-b2e9-edbeb012add7'::uuid, 'Carole Hussey', 'B', 'Whittier Union High School District', ''),
  ('1729fc7b-9a35-4dda-9276-12b6123bc1d8'::uuid, 'Joe Torres', 'B', 'Whittier Union High School District', ''),
  ('a2ea72fc-4c80-4e3f-b72b-e584e3c81a7d'::uuid, 'Maria Mendez', 'B', 'Whittier Union High School District', ''),
  ('228d3acd-75db-44cc-bef9-06f448f94a21'::uuid, 'Sergio Garcia', 'B', 'Whittier Union High School District', ''),
  ('f5638f34-de59-4b45-890b-b59414aaf4de'::uuid, 'Jim Lecithin', 'B', 'William S. Hart Union High School District', ''),
  ('fce14caa-e78a-4538-ae4f-8657f53430ed'::uuid, 'Linda Miller', 'B', 'Wilsona School District', ''),
  ('ceec8e87-b495-4430-ba59-dc202a982ffd'::uuid, 'Mike Diaz', 'B', 'Wilsona School District', ''),
  ('40b39473-5ed1-41b6-85c6-6d1aff569464'::uuid, 'Tina Huber', 'B', 'Wilsona School District', '');

CREATE TEMP TABLE _del (term_id uuid PRIMARY KEY, politician_id uuid, office_id uuid) ON COMMIT DROP;
INSERT INTO _del VALUES
  ('c70e8470-9970-4537-91ee-288df227431d', '823e3a9a-f135-4014-91cf-2b947f03f256', 'f5a4bfa6-184e-49e8-9618-6c339fa9c3f2'),
  ('ebc21855-dfbc-4751-92e1-b52a50be59db', '9f43110f-23e1-45ab-b264-9f079720892f', 'eac642a5-df3e-4e3b-b47f-e1ee738b0824'),
  ('3d6778c1-a90b-4304-9186-e521ea3307f4', '9515abde-bac7-427b-88e9-9c866dc0a968', '8e3cfee0-7bdc-47b4-b52c-6540cd779a2c'),
  ('852b8401-dff1-4d0e-95d8-715294d39250', 'c83403a8-2c30-4b6e-a97c-1faf8aebf43f', '5b68a7cc-24b3-4c50-a680-f84cc22bf8f7');

CREATE TEMP TABLE _baseline ON COMMIT DROP AS
  SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
         (SELECT count(*) FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
           WHERE _a.cls = 'A1' AND ot.term_end IS NULL) AS a1_open_terms;

-- ─── PRE-FLIGHT: derive-then-verify every identifier ───────────────────────────────────────────────
DO $$
DECLARE v_n int; v_m int;
BEGIN
  SELECT count(*) INTO v_n FROM _a;
  IF v_n <> 143 THEN RAISE EXCEPTION 'PRE: expected 143 audit rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM (SELECT cls, count(*) c FROM _a GROUP BY cls) x
   WHERE (cls, c) NOT IN (('A1',3),('A2',1),('B',135),('C',4));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: class counts differ from the approved plan'; END IF;

  -- every row is the politician we audited: same id, same name, same seeding pass
  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.full_name = _a.full_name AND p.source = 'scraped'
     AND p.data_source LIKE 'https://empowered.vote/school-district/%' AND p.data_source NOT LIKE '%unified';
  IF v_n <> 143 THEN RAISE EXCEPTION 'PRE: only % of 143 politicians match id+name+data_source', v_n; END IF;

  -- and the audit covers the WHOLE population (nobody seeded since, nobody missed)
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.data_source LIKE 'https://empowered.vote/school-district/%' AND p.data_source NOT LIKE '%unified'
     AND NOT EXISTS (SELECT 1 FROM _a WHERE _a.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % elementary/high placeholder rows exist that the audit did not classify', v_n; END IF;

  -- CA_0158 is applied: every non-A1 term is closed and carries its close note
  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls <> 'A1' AND (ot.term_end IS NULL OR ot.source NOT LIKE '%| closed CA_0158%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % non-A1 terms are open or lack the CA_0158 close note -- apply CA_0158 first', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE source LIKE 'CA_0158:%';
  IF v_n <> 150 THEN RAISE EXCEPTION 'PRE: % CA_0158 terms found, expected 150 -- apply CA_0158 first', v_n; END IF;

  -- deactivating orphans nothing: no stance data on ANY of the 143
  SELECT (SELECT count(*) FROM inform.politician_answers x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context_evidence x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.evidence_items x JOIN _a ON _a.politician_id = x.politician_id)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % stance/evidence rows exist for audited politicians -- decide them first', v_n; END IF;

  -- no one being deactivated is on a ballot
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN _a ON _a.politician_id = rc.politician_id
   WHERE _a.cls IN ('B','C');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race_candidates rows point at politicians about to be deactivated', v_n; END IF;

  -- every A1 still holds exactly one open term
  SELECT count(*) INTO v_n FROM _a
   WHERE cls = 'A1' AND (SELECT count(*) FROM essentials.office_terms ot
                          WHERE ot.politician_id = _a.politician_id AND ot.term_end IS NULL) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % A1 rows no longer hold exactly one open term', v_n; END IF;

  -- each term to delete is either still present exactly as audited, or already archived (re-run)
  SELECT count(*) INTO v_n FROM _del d JOIN essentials.office_terms ot
      ON ot.id = d.term_id AND ot.politician_id = d.politician_id AND ot.office_id = d.office_id
     AND ot.term_start IS NULL AND ot.term_end IS NOT NULL;
  SELECT count(*) INTO v_m FROM _del d JOIN essentials._fabricated_ca0156_removed r ON r.id = d.term_id AND r.reason LIKE 'CA_0159%';
  IF v_n + v_m <> 4 OR (SELECT count(*) FROM _del) <> 4 THEN
    RAISE EXCEPTION 'PRE: terms to delete: % present + % archived, expected 4', v_n, v_m; END IF;

  -- deleting them never empties a seat: each office also holds the successor's term
  SELECT count(*) INTO v_n FROM _del d JOIN essentials.office_terms ot ON ot.id = d.term_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms s
                      WHERE s.office_id = d.office_id AND s.id <> d.term_id AND s.term_start > ot.term_end);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % deletable terms have no successor on their seat', v_n; END IF;

  -- the C terms belong to C politicians and to nobody else
  SELECT count(*) INTO v_n FROM _del d LEFT JOIN _a ON _a.politician_id = d.politician_id
   WHERE _a.cls IS DISTINCT FROM 'C';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % deletable terms are not held by class-C politicians', v_n; END IF;
END $$;

-- ─── 1. C: archive, then delete, the disproved terms ────────────────────────────────────────────────
INSERT INTO essentials._fabricated_ca0156_removed
SELECT ot.*,
       'CA_0159: recorded ' || _a.district || ' board seat disproved -- ' || _a.evidence,
       now()
  FROM essentials.office_terms ot
  JOIN _del d ON d.term_id = ot.id AND d.politician_id = ot.politician_id
  JOIN _a ON _a.politician_id = d.politician_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed r WHERE r.id = ot.id);

DELETE FROM essentials.office_terms ot
 USING _del d
 WHERE ot.id = d.term_id AND ot.politician_id = d.politician_id
   AND EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed r WHERE r.id = ot.id AND r.reason LIKE 'CA_0159%');

-- ─── 2. Tag the closed terms that stay ──────────────────────────────────────────────────────────────
UPDATE essentials.office_terms ot
   SET source = ot.source || ' | verified CA_0159 (2026-09-22): real former board member -- ' || _a.evidence
  FROM _a
 WHERE _a.politician_id = ot.politician_id AND _a.cls = 'A2'
   AND ot.term_end IS NOT NULL AND ot.source NOT LIKE '%CA_0159%';

UPDATE essentials.office_terms ot
   SET source = ot.source || ' | unverified CA_0159 (2026-09-22): no evidence this person ever served on '
                || 'this board (RR/CC lists 2017-2026, RR/CC contests 2013-2026, district rosters incl. Wayback, minutes, news); '
                || 'seeded by the unsourced school-district pass; politician deactivated, term kept (not disproved)'
  FROM _a
 WHERE _a.politician_id = ot.politician_id AND _a.cls = 'B'
   AND ot.term_end IS NOT NULL AND ot.source NOT LIKE '%CA_0159%';

-- ─── 3. Party: never stored (antipartisan) ──────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET party = NULL, party_short_name = NULL
  FROM _a
 WHERE _a.politician_id = p.id AND (p.party IS NOT NULL OR p.party_short_name IS NOT NULL);

-- ─── 4. Flags ───────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls <> 'A1' AND p.is_incumbent;

UPDATE essentials.politicians p
   SET is_active = false
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls IN ('B','C') AND p.is_active;

-- ─── 5. One audit note per non-A1 row ───────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET notes = COALESCE(p.notes, ARRAY[]::text[]) || ARRAY[
       CASE _a.cls
         WHEN 'A2' THEN 'CA_0159 (2026-09-22): verified former ' || _a.district || ' board member -- ' || _a.evidence
         WHEN 'B'  THEN 'CA_0159 (2026-09-22): NO EVIDENCE of service on the ' || _a.district || ' board. Seeded by '
                        || 'the unsourced school-district pass (placeholder data_source). Searched LA RR/CC candidate '
                        || 'lists 2017-2026 and contests 2013-2026, district rosters incl. Wayback, minutes, local news. '
                        || 'Deactivated; closed term kept and tagged unverified (absence is not disproof).'
         WHEN 'C'  THEN 'CA_0159 (2026-09-22): recorded ' || _a.district || ' board seat DISPROVED -- ' || _a.evidence
                        || '. Term archived to essentials._fabricated_ca0156_removed and deleted; row deactivated '
                        || 'and retained for audit.'
       END]
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls <> 'A1'
   AND NOT EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159%');

-- ─── POST-VERIFY ────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.party IS NOT NULL OR p.party_short_name IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % audited rows still carry a party', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.is_active <> (_a.cls IN ('A1','A2'));
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows have the wrong is_active', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.is_incumbent <> (_a.cls = 'A1');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows have the wrong is_incumbent', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls = 'C';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % terms remain for class-C politicians', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials._fabricated_ca0156_removed r JOIN _del d ON d.term_id = r.id
   WHERE r.reason LIKE 'CA_0159%';
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: archive holds % of the 4 deleted terms', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls IN ('A2','B') AND ot.source NOT LIKE '%CA_0159%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % A2/B terms are untagged', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls IN ('A2','B');
  IF v_n <> 136 THEN RAISE EXCEPTION 'POST: % A2/B terms kept, expected 136', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls = 'A1' AND ot.term_end IS NULL;
  IF v_n <> (SELECT a1_open_terms FROM _baseline) OR v_n <> 3 THEN
    RAISE EXCEPTION 'POST: A1 open terms = %, expected 3 and unchanged', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE _a.cls <> 'A1'
     AND (SELECT count(*) FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159%') <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % non-A1 rows lack exactly one CA_0159 note', v_n; END IF;

  -- no seat lost its occupancy record, and every CA_0158 seat still resolves to its member
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> (SELECT missing_terms FROM _baseline) THEN
    RAISE EXCEPTION 'POST: offices_missing_terms moved from % to %', (SELECT missing_terms FROM _baseline), v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.office_current_holder och ON och.office_id = t.office_id AND och.politician_id = t.politician_id
   WHERE t.source LIKE 'CA_0158:%';
  IF v_n <> 148 THEN RAISE EXCEPTION 'POST: % of 148 CA_0158 members still resolve as current', v_n; END IF;

  -- still no stance data touched
  SELECT (SELECT count(*) FROM inform.politician_answers x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context x JOIN _a ON _a.politician_id = x.politician_id)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: stance rows appeared (%)', v_n; END IF;

  RAISE NOTICE 'CA_0159 applied: 143 audited -- A1 3 (party only), A2 1 (kept, tagged verified), B 135 (deactivated, term tagged unverified), C 4 (term archived + deleted, deactivated)';
END $$;

COMMIT;
