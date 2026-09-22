-- CA_0145_la_unified_board_rosters_batch2.sql
-- Replace the STALE sitting members of six more LA-County AT-LARGE unified school boards with the
-- verified current boards, in essentials.office_terms (the only occupancy source; ADR 0002).
-- Batch 2 of the roster refresh begun in CA_0143; same method, same operator decision.
--
--   Baldwin Park Unified 0603690   Bassett Unified 0604110       Beverly Hills Unified 0604830
--   La Cañada Unified    0620130   Manhattan Beach Unified 0600025   San Marino Unified 0634860
--
-- No migration runner exists; this file records SQL applied by hand via
--   npx tsx scripts/_apply-file.ts <abs path>/backend/migrations/CA_0145_la_unified_board_rosters_batch2.sql
-- (pure DML -> DATABASE_URL is fine).
--
-- ---------------------------------------------------------------------------------------------------
-- A. THE DEFECT -- as CA_0143 §A
-- ---------------------------------------------------------------------------------------------------
-- Each district holds 5 generic 'Board Member' offices on ONE whole-district SCHOOL/G5420 row, each
-- seated by a migration-1459 backfill term (term_start NULL, term_end NULL, 'unknown'), holders with
-- data_source 'https://empowered.vote/school-district/<name>'. Of these 30 holders, 28 are NOT on the
-- current board. TWO ARE, and are KEPT unchanged (§C).
--
-- ---------------------------------------------------------------------------------------------------
-- B. HOW THE STALE TERMS ARE ENDED -- operator decision (Chris Andrews, 2026-09-22), as CA_0143 §B
-- ---------------------------------------------------------------------------------------------------
--   term_end = the day before the successor on the same generic seat took office (a modelling
--   consequence, not a researched last day); how_ended = 'unknown'; politicians.is_incumbent = false;
--   is_active left alone.
--   ONE EXCEPTION, where the record supports more: Noah Margo (Beverly Hills). RR/CC lists NOAH MARGO
--   as a Nov 2020 BHUSD winner (5,913 votes) and he is absent from the Nov 2024 BHUSD list (id 4324),
--   so his term expired in December 2024. He is paired with a 2024 successor, so his term_end
--   (2024-11-30) is month-accurate, and how_ended = 'term_expired'.
--   Also paired with a 2024 successor for the same reason, but how_ended stays 'unknown': the stale
--   'Cristina Lucero' (Baldwin Park) is very probably CHRISTINA M. LUCERO, the appointed incumbent
--   who lost the Nov 2024 full-term race (4th of 3 seats) -- but the spelling differs, so the
--   identity is not asserted.
--
-- ---------------------------------------------------------------------------------------------------
-- C. TWO STALE HOLDERS ARE REAL AND STILL SEATED -- kept, terms untouched
-- ---------------------------------------------------------------------------------------------------
--   Rachelle Marcus (Beverly Hills, a1e9b61d)  bhusd.org lists her as Board Member; RR/CC Nov 2022
--                                             lists RACHELLE MARCUS (E), winner with 5,300 votes.
--   Jen Fenton (Manhattan Beach, 4ef6ef6a)     mbusd.org lists her as Board Member; RR/CC Nov 2022
--                                             lists JENNIFER "JEN" FENTON (E), winner with 9,130.
-- Both were incumbents re-elected in Nov 2022, so their open, undated 1459 row is TRUE (they hold the
-- seat) and is left as it is -- the 1546 precedent for re-elected members: splitting the row would need
-- verified prior-term dates, and it changes no display. Only their stored party is cleared.
--
-- ---------------------------------------------------------------------------------------------------
-- D. THE CURRENT BOARDS -- each district's own board page, fetched and read 2026-09-22
-- ---------------------------------------------------------------------------------------------------
--   Baldwin Park    bpusd.net/apps/pages/index.jsp?uREC_ID=822588&type=d&pREC_ID=1205100
--                   Olmos "Term of Office: December 2024 - December 2026"; Mata, Juarez, Vazques
--                   "December 2024 - December 2028"; de Leon "December 2022 - December 2026".
--                   Olmos won the Nov 2024 ONE-seat contest (RR/CC 4324: 8,332 v Apolinario 6,479) --
--                   an unexpired term ending 2026, which is why she is an RR/CC "E" on the 2026 list.
--   Bassett         bassettusd.org/apps/pages/index.jsp?uREC_ID=1184491&type=d&pREC_ID=1429114
--                   Simental, Stanzione, Rivera "2022-2026"; Gonzalez, Florez "2024-2028".
--   Beverly Hills   bhusd.org/school-district-beverly-hills-unified-/board-of-education/board-of-education-overview
--                   Manouchehri, Sabag, Stern, Stuart, Marcus (read in a browser).
--   La Cañada       lcusd.net/apps/pages/index.jsp?uREC_ID=346325&type=d&pREC_ID=staff
--                   Anderson, Epstein, Thuss, Jeffries, Radabaugh.
--   Manhattan Beach mbusd.org/page/members (read in a browser)
--                   Shivpuri, Dohner, Graves, Fenton, Weinstein.
--   San Marino      smusd.us/apps/pages/index.jsp?uREC_ID=242685&type=d&pREC_ID=570576
--                   Gill, Ryan, Lam, Chang, Sung.
-- Each member's CURRENT term is the cycle they last won per the RR/CC candidate lists (Nov 2022 = 4300,
-- Nov 2024 = 4324). Nov 2024 was UNCONTESTED (candidates = seats) in Manhattan Beach (Dohner, Graves)
-- and San Marino (Gill, Sung): appointed in lieu of election, which Elections Code §10515 treats as
-- elected. TERM START = December of the election year, start_precision 'month' (CA_0143 §D).
--
-- ---------------------------------------------------------------------------------------------------
-- E. PEOPLE -- 24 new politician rows, 4 reused, 2 kept
-- ---------------------------------------------------------------------------------------------------
-- Reused, not duplicated -- confirmed LA County NetFile committees (transparent_motivations.
-- politician_sources, research_status 'confirmed'), and each is the ONLY person of that name on the
-- Nov 2024 RR/CC list:
--   f9e80b26 Amanda Stern      "Re-Elect Amanda Stern for School Board 2024"   (AMANDA E. STERN (E), BHUSD)
--   61f7b168 Russell Stuart    "RUSSELL STUART FOR SCHOOL BOARD 2024"          (RUSSELL STUART, BHUSD)
--   b6213010 Caroline Anderson "Caroline Anderson for LCUSD School Board 2024" (CAROLINE QUE ANDERSON (E))
--   6aee7b39 'Epstein'         "Epstein for LCUSD Governing Board 2024"       (JOSH EPSTEIN (E))
--                              -> name completed to Josh Epstein (only while unedited)
-- New rows: party NULL, is_active/is_incumbent true, data_source = the board page, ballot variants in
-- alternate_names. Seated reused and kept rows get party NULL and is_incumbent true.
--
-- ---------------------------------------------------------------------------------------------------
-- F. 2026 CANDIDATES -- the 13 RR/CC incumbents on the six CA_0142 races are linked to the seated rows.
-- ---------------------------------------------------------------------------------------------------
--
-- NOT DONE HERE: the stale holders keep party 'Nonpartisan' and is_active true (flagged, not touched);
-- the Baldwin Park 2026 candidate 'Christina Lucero' (not an incumbent) is left unlinked; titles stay
-- the generic 'Board Member'.
--
-- ROLLBACK: DELETE the 28 office_terms rows whose source starts 'CA_0145:'; for the 28 closed stale
-- rows (source contains '| closed CA_0145') SET term_end = NULL, how_ended = NULL and strip the note;
-- set is_incumbent = true on the 28 stale politicians; set race_candidates.politician_id = NULL on the
-- 13 rows linked here; DELETE the 24 new politicians (ids in _ca0145_newpol). The four reused NetFile
-- rows had is_incumbent false, party NULL, data_source NULL, alternate_names '{}'; 6aee7b39 had
-- full_name 'Epstein', first_name NULL. Marcus and Fenton had party 'Nonpartisan'.
--
-- IDEMPOTENT: stale closes guarded on term_end IS NULL; new terms on (office, politician, term_start);
-- politicians on id; links on politician_id IS NULL.

BEGIN;

-- ─── Seat map: one row per seat. action 'replace' = stale out / member in; 'keep' = verified holder ─
CREATE TEMP TABLE _ca0145_seat (
  geo_id text, office_id uuid, stale_term_id uuid, stale_pol_id uuid, stale_name text,
  new_pol_id uuid, new_name text, elected_year int, action text, how_ended text
) ON COMMIT DROP;
INSERT INTO _ca0145_seat VALUES
  -- Baldwin Park Unified
  ('0603690','0c40cf49-6d98-4255-9af7-132491047e9f','30db2931-c5c2-4ee4-9867-e9381ec2e414','09cd1f70-2a45-4393-ac52-33f55091ffd4','Cristina Lucero',       '2b298d7b-51e0-4825-a6a4-dba66f69d184','Norma Olmos',                2024,'replace','unknown'),
  ('0603690','6b7cb763-e449-4d4c-84b6-1ebc24e0d402','697ab319-999d-44a0-8e6a-2f04a7fa6a32','9d2713c4-1d4f-4c40-ae35-b331e9771fa1','Ariel Mestas',          '3f02aa66-cbd1-4c67-a8a4-be3f7bc8c516','John B. de Leon',            2022,'replace','unknown'),
  ('0603690','c0073f71-0d2c-4a16-a9db-1427978c5bae','0e512e7c-a631-4d1e-a1d9-3e0c6a3c7bce','090f3cb2-20e9-42a9-872e-80081f3b5bfe','Leticia Garcia',        '58907071-7604-4934-99c1-ef862865edd4','Jose M. Mata',               2024,'replace','unknown'),
  ('0603690','e7967d94-ecfa-4636-94bd-c1138d7d7da5','a73aa8f7-e6b9-41d0-845f-cb2f5ffac334','93989522-c68e-4187-bf11-99afb673473f','Mario Ventura Rodriguez','823e3738-4ec6-4ab2-aac8-e55dd737a93d','Yvonne S. Juarez',          2024,'replace','unknown'),
  ('0603690','f88ccc90-ae75-4193-8eb3-5ca0310ddfb0','03331a23-199b-4d0c-a6e9-0f4ec805914e','74bfd93c-d707-4432-8e99-ad62a20a1235','Herman Dace',           '35b2357f-3d89-4bea-b53b-43d5e51a47be','Ricardo Vazques',            2024,'replace','unknown'),
  -- Bassett Unified
  ('0604110','1c6b7e1c-1aef-46ac-b158-4fa9293e8251','804075f2-ab8a-4676-8e0b-0c1ca5619acf','9fc809a1-6e91-46ea-9850-b815df5cfbb9','Rafael Limon',          '35216523-9507-404e-a967-b6643a423917','Dolores Rivera',             2022,'replace','unknown'),
  ('0604110','53fb87f3-fca5-47c6-8a5c-1f6bead353f0','65be9ffa-741e-4920-92a4-efc75a15416e','1c0c6ccc-cbe7-43da-b760-7c812943292f','Roy Munoz',             '3a2d72cd-8ad7-4080-96ea-e5b2296e3f12','Aaron Simental',             2022,'replace','unknown'),
  ('0604110','5d779697-2865-4047-a919-acee7f27c180','132b5255-025a-43ee-81f6-9579157cdaa5','3dc1d627-754d-4053-a11c-c30b6088073a','John Piazza',           '16a82de0-755d-4e2e-87fa-1d1f86cdfdb2','Patrice Stanzione',          2022,'replace','unknown'),
  ('0604110','a1ea0687-c03d-4131-9754-4692794b92c1','a2067a42-bc79-4eef-9f98-f0d661193680','ee87befc-d2e3-4a24-acb8-76f95c3ab2ee','Maria Huerta',          '1873a41a-e325-4835-a9f5-0ad34ec6a73e','Dena Florez',                2024,'replace','unknown'),
  ('0604110','aa734660-db3c-46a7-9916-2bb50ef0724d','5c8378ce-640c-42a6-92bf-dd9cdfddd31e','4fe290b2-aa2f-4ba1-b172-c0e75e8994ee','Diana Corona',          'c071301b-a1bb-42de-a846-518c6c2b466d','Norma Gonzalez',             2024,'replace','unknown'),
  -- Beverly Hills Unified
  ('0604830','51265d6b-e523-417f-9ec7-965b5effcb8c','78eeeb0c-964a-4c29-b633-31f3241c80e0','8bc76d78-5793-4ab8-ba47-ddeefeb33413','Noah Margo',            'f9e80b26-9155-45cb-a1bc-83b35d0c70ec','Amanda Stern',               2024,'replace','term_expired'),
  ('0604830','527e2f3c-2e4c-452e-a925-ab05c624ba18','a310c80a-0f3e-43d9-a7e6-7cafcb1fdb62','84a73092-e2e4-4030-8b05-2113ec404df1','Alissa Roston',         '73881ac1-ff3a-4dbc-a489-723b790601d0','Judith Manouchehri',         2022,'replace','unknown'),
  ('0604830','5c8b8683-8614-4484-9bfe-7d0b39ea6fd2','a35fa7d7-bb9a-44eb-ba1a-9df2d2901b9a','35d08038-550b-4f13-b564-dcfe48b3dfa6','Brian Goldberg',        '98fa010e-f2e6-45a5-ada4-185acbb77caa','Sigalie Sabag',              2024,'replace','unknown'),
  ('0604830','65b806b7-2f52-4ef5-8f77-bc29aad76133','973ae030-3ff9-4456-b1a8-a0a4f21d4ca9','9ddd1703-dbaa-4ec6-8a6b-0ec1ef4ae106','Svetlana Shagalov',     '61f7b168-9adf-4f95-828d-f84e23b5a5b2','Russell Stuart',             2024,'replace','unknown'),
  ('0604830','7406e574-089c-4af3-aa03-b2a65b9c77d3','73196fc6-110c-4768-a717-3828a80b1c71','a1e9b61d-96e0-47be-ae4f-dab05158e56b','Rachelle Marcus',       'a1e9b61d-96e0-47be-ae4f-dab05158e56b','Rachelle Marcus',            2022,'keep',   NULL),
  -- La Cañada Unified
  ('0620130','06396e01-acee-4074-99c9-ff684e4d8f54','5e2afbcf-5a64-4066-9f69-34a36fadb9ce','ea6acf1c-3ada-4062-b324-0278459c99be','Diana Carey',           '9c2984dd-aed7-4447-ac6e-91d3341a2835','Dan Jeffries',               2022,'replace','unknown'),
  ('0620130','49d8f36e-efa1-402f-be5d-229d5d9d72e3','da6333a2-8d2f-412f-8154-895d1191fb8f','0720ce76-332a-4817-b887-2e7599934f64','Darleen Ramos',         '42a6fdbb-efdd-4980-92f7-d878dd5d5cbf','Joe Radabaugh',              2022,'replace','unknown'),
  ('0620130','4b494c87-ee4c-4dde-923c-304142c46bf6','3bdcbdfb-db33-4d60-9177-4c1d8ed58adc','64f2bab6-2325-41da-8202-b8dd756aa9d3','Kristin Shane',         '2603c095-a19c-43d4-9be6-9925db6055cb','Octavia Thuss',              2022,'replace','unknown'),
  ('0620130','8100c81e-d4c3-425d-9b7e-0aea417f7f32','7ed05720-3897-4d46-9a6c-76a1409c2924','5112b67b-566e-4099-9c8a-2f1fbc623055','Jon Haraguchi',         'b6213010-3dbd-4b3e-8aa7-0ac125b70f5e','Caroline Anderson',          2024,'replace','unknown'),
  ('0620130','9852f4a3-238c-4743-9aa6-f92add97da48','d2be810e-f158-47d6-bcb8-7421cfcb2087','9f240574-48a1-44f7-9728-712ade528e84','Brian Riddick',         '6aee7b39-93c7-48bc-8ad6-be6fa52a3707','Josh Epstein',               2024,'replace','unknown'),
  -- Manhattan Beach Unified
  ('0600025','4211a543-61b1-4b6d-b768-9f6d8a9000f5','9a1d9a2d-6b3f-460a-821f-db85f3d277e9','4ef6ef6a-7a0c-4f66-bc9e-3e923ce4965d','Jen Fenton',            '4ef6ef6a-7a0c-4f66-bc9e-3e923ce4965d','Jen Fenton',                 2022,'keep',   NULL),
  ('0600025','4b772339-d7a8-4752-afdd-d8cdc4b7d0df','7d0e22c6-6800-4b2b-9625-2f293347347e','67b3bb06-3c13-49dc-93d0-1aa7f5b04672','Holly Bhagavan',        '874b92dc-f728-4bd3-9312-58b5a40c0f79','Christina "Tina" Shivpuri',  2022,'replace','unknown'),
  ('0600025','5dd8c56d-f760-4802-ab72-8b9fa009c823','a0bc4ed6-88f6-4ae7-b158-43372aa16df8','102e826e-87df-4731-8ee7-ae7c7f0f07dd','Joanna Robinson',       'a8d41e8a-0f6a-40b5-87bd-30677f7162fe','Kristen "Wysh" Weinstein',   2022,'replace','unknown'),
  ('0600025','92cc301c-bfe8-4d73-b33b-3de39b04d2d1','1883500e-4652-43db-88d2-1d4fb0a3cc97','29558ef3-818a-4e33-968c-5abe35f93e1f','Jason Turner',          'f4ba1fb9-7759-4956-aa0a-f98e6f1f63dc','Jen Dohner',                 2024,'replace','unknown'),
  ('0600025','f541b163-0fc3-466e-8ac5-6b605b4ece51','2bc3e34f-0aec-485b-992f-efd46a92b35a','df7e4a1a-14d1-4044-9f81-2936486b3d4a','Jennifer Cochran',      '21837220-a246-4076-b9d0-fe2847b577bf','Cathey Graves',              2024,'replace','unknown'),
  -- San Marino Unified
  ('0634860','4b1895c4-923d-449c-b12e-c0c6e890671f','dfa1e31c-b0c7-4bd1-b4d0-f8145c936919','59d50869-a5c4-4e95-9276-a129e984fb8d','Marcella Hovey',        '2bba1c13-f1e5-4ae9-9633-71229f75b452','C. Joseph Chang',            2022,'replace','unknown'),
  ('0634860','8d5f8036-a69b-469e-92cb-8b50995f0874','ad298894-1152-4712-b24e-bb8023177080','1a7a4b31-f17f-4e95-954b-0cd7f78b5e85','Ann Huang',             '866ef252-d4ac-402c-a818-de5ae146fabe','Joanna Lam',                 2022,'replace','unknown'),
  ('0634860','9e40b010-5d00-4d3e-a553-92d4e5752c9b','405d5abc-563d-4af6-83bb-a8cd2dd63d9e','7b2e6829-ce2b-41c7-9258-4f65bb72c258','Linh Nguyen',           'fc5385d9-5b63-4dfa-9568-d91f4577c5cd','Shelley Ryan',               2022,'replace','unknown'),
  ('0634860','c2997ce8-9e67-45d6-9e97-8f7d6f32b2f4','977e80aa-4a55-4b72-a8ae-1c45f591078a','d0b60b59-207f-4687-86c9-15c7810d4117','Tom Regan',             '5124888c-a95c-4027-a1ee-2a495b009447','Francesca Gill',             2024,'replace','unknown'),
  ('0634860','eea97073-5386-4baa-8c3c-b50b18c0883f','e2aa1efd-361e-4abc-83b7-e63ecbc2ddd9','910b1c9b-1af6-48a1-ac98-1d93605a915f','Jason Paguio',          'caaea56b-5a0e-4c68-b83a-76e65cd2e226','Joshua Sung',                2024,'replace','unknown');

CREATE TEMP TABLE _ca0145_district (geo_id text PRIMARY KEY, name text, board_url text, uncontested_2024 boolean) ON COMMIT DROP;
INSERT INTO _ca0145_district VALUES
  ('0603690','Baldwin Park Unified',   'https://www.bpusd.net/apps/pages/index.jsp?uREC_ID=822588&type=d&pREC_ID=1205100',   false),
  ('0604110','Bassett Unified',        'https://www.bassettusd.org/apps/pages/index.jsp?uREC_ID=1184491&type=d&pREC_ID=1429114', false),
  ('0604830','Beverly Hills Unified',  'https://www.bhusd.org/school-district-beverly-hills-unified-/board-of-education/board-of-education-overview', false),
  ('0620130','La Cañada Unified',      'https://www.lcusd.net/apps/pages/index.jsp?uREC_ID=346325&type=d&pREC_ID=staff',      false),
  ('0600025','Manhattan Beach Unified','https://www.mbusd.org/page/members',                                                true),
  ('0634860','San Marino Unified',     'https://www.smusd.us/apps/pages/index.jsp?uREC_ID=242685&type=d&pREC_ID=570576',     true);

CREATE TEMP TABLE _ca0145_reused (id uuid PRIMARY KEY, full_name text, committee_like text, add_alternate text[]) ON COMMIT DROP;
INSERT INTO _ca0145_reused VALUES
  ('f9e80b26-9155-45cb-a1bc-83b35d0c70ec','Amanda Stern',      '%Re-Elect Amanda Stern for School Board 2024%',   '{"Amanda E. Stern"}'),
  ('61f7b168-9adf-4f95-828d-f84e23b5a5b2','Russell Stuart',    '%RUSSELL STUART FOR SCHOOL BOARD 2024%',          '{}'),
  ('b6213010-3dbd-4b3e-8aa7-0ac125b70f5e','Caroline Anderson', '%Caroline Anderson for LCUSD School Board 2024%', '{"Caroline Que Anderson"}'),
  ('6aee7b39-93c7-48bc-8ad6-be6fa52a3707','Epstein',           '%Epstein for LCUSD Governing Board 2024%',        '{}');

-- New people (24).
CREATE TEMP TABLE _ca0145_newpol (
  id uuid PRIMARY KEY, geo_id text, full_name text, first_name text, last_name text,
  preferred_name text, alternate_names text[]
) ON COMMIT DROP;
INSERT INTO _ca0145_newpol VALUES
  ('3f02aa66-cbd1-4c67-a8a4-be3f7bc8c516','0603690','John B. de Leon',          'John',     'de Leon',   NULL,    '{"John B. De Leon","John Bernard de Leon"}'),
  ('2b298d7b-51e0-4825-a6a4-dba66f69d184','0603690','Norma Olmos',              'Norma',    'Olmos',     NULL,    '{}'),
  ('58907071-7604-4934-99c1-ef862865edd4','0603690','Jose M. Mata',             'Jose',     'Mata',      'Joey',  '{"Jose Mari Mata"}'),
  ('823e3738-4ec6-4ab2-aac8-e55dd737a93d','0603690','Yvonne S. Juarez',         'Yvonne',   'Juarez',    NULL,    '{}'),
  ('35b2357f-3d89-4bea-b53b-43d5e51a47be','0603690','Ricardo Vazques',          'Ricardo',  'Vazques',   NULL,    '{}'),
  ('35216523-9507-404e-a967-b6643a423917','0604110','Dolores Rivera',           'Dolores',  'Rivera',    NULL,    '{"Dolores C. Rivera","Dolores Castro Rivera"}'),
  ('3a2d72cd-8ad7-4080-96ea-e5b2296e3f12','0604110','Aaron Simental',           'Aaron',    'Simental',  NULL,    '{}'),
  ('16a82de0-755d-4e2e-87fa-1d1f86cdfdb2','0604110','Patrice Stanzione',        'Patrice',  'Stanzione', NULL,    '{}'),
  ('1873a41a-e325-4835-a9f5-0ad34ec6a73e','0604110','Dena Florez',              'Dena',     'Florez',    NULL,    '{}'),
  ('c071301b-a1bb-42de-a846-518c6c2b466d','0604110','Norma Gonzalez',           'Norma',    'Gonzalez',  NULL,    '{}'),
  ('73881ac1-ff3a-4dbc-a489-723b790601d0','0604830','Judith Manouchehri',       'Judith',   'Manouchehri',NULL,   '{}'),
  ('98fa010e-f2e6-45a5-ada4-185acbb77caa','0604830','Sigalie Sabag',            'Sigalie',  'Sabag',     NULL,    '{}'),
  ('9c2984dd-aed7-4447-ac6e-91d3341a2835','0620130','Dan Jeffries',             'Dan',      'Jeffries',  NULL,    '{}'),
  ('42a6fdbb-efdd-4980-92f7-d878dd5d5cbf','0620130','Joe Radabaugh',            'Joe',      'Radabaugh', NULL,    '{}'),
  ('2603c095-a19c-43d4-9be6-9925db6055cb','0620130','Octavia Thuss',            'Octavia',  'Thuss',     NULL,    '{}'),
  ('874b92dc-f728-4bd3-9312-58b5a40c0f79','0600025','Christina "Tina" Shivpuri','Christina','Shivpuri',  'Tina',  '{"Tina Shivpuri"}'),
  ('a8d41e8a-0f6a-40b5-87bd-30677f7162fe','0600025','Kristen "Wysh" Weinstein', 'Kristen',  'Weinstein', 'Wysh',  '{"Wysh Weinstein"}'),
  ('f4ba1fb9-7759-4956-aa0a-f98e6f1f63dc','0600025','Jen Dohner',               'Jen',      'Dohner',    NULL,    '{}'),
  ('21837220-a246-4076-b9d0-fe2847b577bf','0600025','Cathey Graves',            'Cathey',   'Graves',    NULL,    '{}'),
  ('2bba1c13-f1e5-4ae9-9633-71229f75b452','0634860','C. Joseph Chang',          'C. Joseph','Chang',     NULL,    '{}'),
  ('866ef252-d4ac-402c-a818-de5ae146fabe','0634860','Joanna Lam',               'Joanna',   'Lam',       NULL,    '{}'),
  ('fc5385d9-5b63-4dfa-9568-d91f4577c5cd','0634860','Shelley Ryan',             'Shelley',  'Ryan',      NULL,    '{"Shelley Carolyn Ryan"}'),
  ('5124888c-a95c-4027-a1ee-2a495b009447','0634860','Francesca Gill',           'Francesca','Gill',      NULL,    '{}'),
  ('caaea56b-5a0e-4c68-b83a-76e65cd2e226','0634860','Joshua Sung',              'Joshua',   'Sung',      NULL,    '{"Joshua H. Sung"}');

-- 2026 RR/CC incumbents on the six CA_0142 races.
CREATE TEMP TABLE _ca0145_link (race_id uuid, rc_full_name text, politician_id uuid) ON COMMIT DROP;
INSERT INTO _ca0145_link VALUES
  ('c2e79e70-8887-46e3-89c6-292a420bc620','John B. De Leon',            '3f02aa66-cbd1-4c67-a8a4-be3f7bc8c516'),
  ('c2e79e70-8887-46e3-89c6-292a420bc620','Norma Olmos',                '2b298d7b-51e0-4825-a6a4-dba66f69d184'),
  ('77a84354-ce41-4c51-aa27-5120b510b5bf','Dolores C. Rivera',          '35216523-9507-404e-a967-b6643a423917'),
  ('77a84354-ce41-4c51-aa27-5120b510b5bf','Aaron Simental',             '3a2d72cd-8ad7-4080-96ea-e5b2296e3f12'),
  ('77a84354-ce41-4c51-aa27-5120b510b5bf','Patrice Stanzione',          '16a82de0-755d-4e2e-87fa-1d1f86cdfdb2'),
  ('ccde4039-2f40-4ceb-bb67-2b78d65230a8','Judith Manouchehri',         '73881ac1-ff3a-4dbc-a489-723b790601d0'),
  ('d32bdf55-bb37-4597-8271-76641aa72ce6','Dan Jeffries',               '9c2984dd-aed7-4447-ac6e-91d3341a2835'),
  ('d32bdf55-bb37-4597-8271-76641aa72ce6','Joe Radabaugh',              '42a6fdbb-efdd-4980-92f7-d878dd5d5cbf'),
  ('d32bdf55-bb37-4597-8271-76641aa72ce6','Octavia Thuss',              '2603c095-a19c-43d4-9be6-9925db6055cb'),
  ('f84181ce-e2ed-4b90-8edf-3016fb912a9d','Christina "Tina" Shivpuri',  '874b92dc-f728-4bd3-9312-58b5a40c0f79'),
  ('f84181ce-e2ed-4b90-8edf-3016fb912a9d','Kristen "Wysh" Weinstein',   'a8d41e8a-0f6a-40b5-87bd-30677f7162fe'),
  ('6ac25b1c-a9fb-4a15-ac1c-2f779991f117','C. Joseph Chang',            '2bba1c13-f1e5-4ae9-9633-71229f75b452'),
  ('6ac25b1c-a9fb-4a15-ac1c-2f779991f117','Shelley Carolyn Ryan',       'fc5385d9-5b63-4dfa-9568-d91f4577c5cd');

-- ─── Pre-flight: derive-then-verify every identifier ─────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0145_seat s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = s.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND o.title = 'Board Member';
  IF v_n <> 30 THEN RAISE EXCEPTION 'PRE: % of 30 seat offices resolve to their SCHOOL/G5420 district', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0145_district);
  IF v_n <> 30 THEN RAISE EXCEPTION 'PRE: the 6 districts hold % offices, expected 30', v_n; END IF;

  -- each 1459 term is (id, office, politician, name) as recorded; open, or closed by THIS file
  SELECT count(*) INTO v_n FROM _ca0145_seat s
    JOIN essentials.office_terms t ON t.id = s.stale_term_id AND t.office_id = s.office_id AND t.politician_id = s.stale_pol_id
    JOIN essentials.politicians p ON p.id = s.stale_pol_id AND p.full_name = s.stale_name
   WHERE t.term_start IS NULL
     AND (t.term_end IS NULL
          OR (s.action = 'replace' AND t.term_end = make_date(s.elected_year, 12, 1) - 1 AND t.source LIKE '%| closed CA_0145%'));
  IF v_n <> 30 THEN RAISE EXCEPTION 'PRE: % of 30 existing terms match the recorded (id, office, politician, name)', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT stale_pol_id FROM _ca0145_seat WHERE action = 'replace');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % stance answers -- retire them first', v_n; END IF;

  -- no stale or kept holder sits on any other office
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT stale_pol_id FROM _ca0145_seat)
     AND t.id NOT IN (SELECT stale_term_id FROM _ca0145_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale/kept holders hold % other office_terms', v_n; END IF;

  -- reused rows are the people recorded, backed by the confirmed NetFile committee, and seat-free
  SELECT count(*) INTO v_n FROM _ca0145_reused r JOIN essentials.politicians p ON p.id = r.id
   WHERE p.full_name = r.full_name OR (r.id = '6aee7b39-93c7-48bc-8ad6-be6fa52a3707' AND p.full_name = 'Josh Epstein');
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 reused politician rows match', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0145_reused r
   WHERE EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                  WHERE ps.essentials_politician_id = r.id AND ps.source_system = 'la_county_netfile'
                    AND ps.research_status = 'confirmed' AND ps.notes ILIKE r.committee_like);
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 NetFile committees confirm the reused rows', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT id FROM _ca0145_reused) AND t.source NOT LIKE 'CA_0145:%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: reused rows hold % unexpected office_terms', v_n; END IF;

  -- every race to link is a CA_0142 race bound to one of these seats
  SELECT count(DISTINCT r.id) INTO v_n FROM essentials.races r
   WHERE r.id IN (SELECT race_id FROM _ca0145_link)
     AND r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND r.office_id IN (SELECT office_id FROM _ca0145_seat);
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 CA_0142 races resolve to these seats', v_n; END IF;
END $$;

-- ─── 1. New politician rows (24) ─────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, preferred_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.alternate_names,
       true, false, true, NULL, d.board_url, 'CA_0145_la_unified_board_rosters_batch2'
  FROM _ca0145_newpol n JOIN _ca0145_district d ON d.geo_id = n.geo_id
ON CONFLICT (id) DO NOTHING;

-- ─── 2. Reused and kept rows: seated -> incumbent, no stored party ───────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = true, party = NULL, data_source = COALESCE(p.data_source, d.board_url),
       alternate_names = ARRAY(SELECT DISTINCT unnest(p.alternate_names || r.add_alternate))
  FROM _ca0145_reused r, _ca0145_seat s JOIN _ca0145_district d ON d.geo_id = s.geo_id
 WHERE p.id = r.id AND s.new_pol_id = r.id
   AND (p.is_incumbent IS DISTINCT FROM true OR p.party IS NOT NULL OR p.data_source IS NULL
        OR NOT p.alternate_names @> r.add_alternate);

UPDATE essentials.politicians
   SET full_name = 'Josh Epstein', first_name = 'Josh'
 WHERE id = '6aee7b39-93c7-48bc-8ad6-be6fa52a3707' AND full_name = 'Epstein' AND NOT full_name_manual_override;

UPDATE essentials.politicians p
   SET party = NULL, is_incumbent = true
 WHERE p.id IN (SELECT new_pol_id FROM _ca0145_seat WHERE action = 'keep')
   AND (p.party IS NOT NULL OR NOT p.is_incumbent);

-- ─── 3. Close the 28 stale terms (operator decision §B) ──────────────────────────────────────────
UPDATE essentials.office_terms t
   SET term_end  = make_date(s.elected_year, 12, 1) - 1,
       how_ended = s.how_ended,
       source    = t.source || ' | closed CA_0145 (2026-09-22): holder is not on the verified current '
                   || d.name || ' board (' || d.board_url || '); '
                   || CASE WHEN s.how_ended = 'term_expired'
                           THEN 'won Nov 2020 per LA County RR/CC and absent from the Nov 2024 list, so the term expired in December 2024'
                           ELSE 'actual last day NOT researched -- term_end is the day before the successor on this generic seat took office' END
  FROM _ca0145_seat s JOIN _ca0145_district d ON d.geo_id = s.geo_id
 WHERE t.id = s.stale_term_id
   AND s.action = 'replace'
   AND t.term_end IS NULL;

-- ─── 4. Seat the 28 current members ──────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT s.office_id, s.new_pol_id, make_date(s.elected_year, 12, 1), 'month', 'elected',
       'CA_0145: ' || d.name || ' board roster, ' || d.board_url || ' (read 2026-09-22); current term won Nov '
       || s.elected_year || ' per LA County RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id='
       || CASE s.elected_year WHEN 2022 THEN '4300' ELSE '4324' END
       || CASE WHEN s.new_pol_id = '2b298d7b-51e0-4825-a6a4-dba66f69d184'
               THEN ' (one-seat contest for the unexpired term ending December 2026)' ELSE '' END
       || CASE WHEN s.elected_year = 2024 AND d.uncontested_2024
               THEN ' (uncontested; appointed in lieu of election, Elec. Code 10515)' ELSE '' END
       || '; term begins December ' || s.elected_year || ' (Ed. Code 5017), month precision'
  FROM _ca0145_seat s JOIN _ca0145_district d ON d.geo_id = s.geo_id
 WHERE s.action = 'replace'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = s.office_id AND t.politician_id = s.new_pol_id
                      AND t.term_start = make_date(s.elected_year, 12, 1));

-- ─── 5. Stale holders are no longer incumbents (only where they hold no current seat) ────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.id IN (SELECT stale_pol_id FROM _ca0145_seat WHERE action = 'replace')
   AND p.is_incumbent
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── 6. Link the 2026 incumbents ─────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET politician_id = l.politician_id
  FROM _ca0145_link l
 WHERE rc.race_id = l.race_id
   AND lower(rc.full_name) = lower(l.rc_full_name)
   AND rc.is_incumbent
   AND rc.politician_id IS NULL;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0145_seat s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id AND och.politician_id = s.new_pol_id;
  IF v_n <> 30 THEN RAISE EXCEPTION 'POST: % of 30 seats resolve to the intended current member', v_n; END IF;

  SELECT count(*) INTO v_bad FROM (
    SELECT d.geo_id
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
     WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0145_district)
     GROUP BY d.geo_id
    HAVING count(DISTINCT o.id) <> 5 OR count(DISTINCT p.id) <> 5 OR bool_or(o.is_vacant)) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) do not show 5 active incumbent holders', v_bad; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT new_pol_id FROM _ca0145_seat) AND p.party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) carry a stored party', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     WHERE och.politician_id IN (SELECT new_pol_id FROM _ca0145_seat)
     GROUP BY 1 HAVING count(*) <> 1) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) hold <> 1 current seat', v_bad; END IF;

  SELECT count(*) INTO v_n FROM _ca0145_seat s JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.politician_id = s.new_pol_id
   WHERE s.action = 'replace'
     AND t.term_start = make_date(s.elected_year, 12, 1) AND t.start_precision = 'month'
     AND t.how_started = 'elected' AND t.term_end IS NULL AND t.source LIKE 'CA_0145:%';
  IF v_n <> 28 THEN RAISE EXCEPTION 'POST: % of 28 new terms have the expected shape', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0145_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'replace' AND t.term_end = make_date(s.elected_year, 12, 1) - 1
     AND t.how_ended = s.how_ended AND t.source LIKE '%| closed CA_0145%';
  IF v_n <> 28 THEN RAISE EXCEPTION 'POST: % of 28 stale terms closed as intended', v_n; END IF;

  -- kept holders: their 1459 row is untouched and still current
  SELECT count(*) INTO v_n FROM _ca0145_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'keep' AND t.term_start IS NULL AND t.term_end IS NULL AND t.how_ended IS NULL;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 kept terms untouched', v_n; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT stale_pol_id FROM _ca0145_seat WHERE action = 'replace')
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % stale holder(s) still current or incumbent', v_bad; END IF;

  -- 2026 races: all 13 RR/CC incumbents linked to a current holder of the same district; none unlinked
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices ro ON ro.id = r.office_id
    JOIN essentials.office_current_holder och ON och.politician_id = rc.politician_id
    JOIN essentials.offices ho ON ho.id = och.office_id AND ho.district_id = ro.district_id
   WHERE r.id IN (SELECT race_id FROM _ca0145_link) AND rc.is_incumbent;
  IF v_n <> 13 THEN RAISE EXCEPTION 'POST: % of 13 incumbent candidates linked to a current holder of their district', v_n; END IF;
  SELECT count(*) INTO v_bad FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM _ca0145_link) AND rc.is_incumbent AND rc.politician_id IS NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % incumbent candidate(s) on these races still unlinked', v_bad; END IF;

  -- END TO END: an interior point of each district's polygon returns 5 active incumbent holders
  SELECT count(*) INTO v_bad FROM _ca0145_district x
   WHERE (SELECT count(DISTINCT p.id)
            FROM essentials.districts d0
            JOIN essentials.geofence_boundaries me ON me.geo_id = d0.geo_id AND me.mtfcc = d0.mtfcc
            JOIN essentials.geofence_boundaries gb ON public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry))
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc AND d.district_type = 'SCHOOL'
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id
            JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
           WHERE d0.geo_id = x.geo_id AND d0.district_type = 'SCHOOL' AND d0.mtfcc = 'G5420'
             AND d.geo_id = x.geo_id) <> 5;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) not reached from inside their own polygon', v_bad; END IF;

  RAISE NOTICE 'CA_0145 applied: 28 seats re-seated + 2 verified holders kept across 6 LA unified boards; 28 stale terms closed; 24 politicians created, 4 reused; 13 candidates linked';
END $$;

COMMIT;
