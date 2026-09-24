-- CA_0147_la_unified_board_rosters_batch3.sql
-- Replace the STALE sitting members of the last five LA-County AT-LARGE unified school boards with the
-- verified current boards, in essentials.office_terms (the only occupancy source; ADR 0002).
-- Batch 3 of the roster refresh (CA_0143, CA_0145); same method, same operator decisions.
--
--   Las Virgenes Unified 0621000   Lynwood Unified 0623160   Palos Verdes Peninsula Unified 0629700
--   San Gabriel Unified  0634425   Wiseburn Unified 0601428
--
-- No migration runner exists; this file records SQL applied by hand via
--   npx tsx scripts/_apply-file.ts <abs path>/backend/migrations/CA_0147_la_unified_board_rosters_batch3.sql
-- (pure DML -> DATABASE_URL is fine).
--
-- ---------------------------------------------------------------------------------------------------
-- A. THE DEFECT -- as CA_0143 §A. 24 generic 'Board Member' seats carry migration-1459 backfill terms
-- (NULL/NULL, 'unknown'); 23 holders are not on the current board, 1 is (§C). Lynwood has only FOUR
-- seats for a five-member board (§D).
--
-- ---------------------------------------------------------------------------------------------------
-- B. HOW THE STALE TERMS ARE ENDED -- operator decision (Chris Andrews, 2026-09-22), as CA_0143 §B:
-- term_end = day before the successor on the same generic seat took office (modelling consequence);
-- how_ended 'unknown'; is_incumbent = false; is_active left alone.
--   EXCEPTION, as CA_0145 §B: Kate Vadehra (Las Virgenes) won Nov 2020 (RR/CC 4193: 15,287 votes, 2nd
--   of 2 seats) and is absent from the Nov 2024 list (4324), so her term expired in December 2024. She is
--   paired with a 2024 successor (month-accurate term_end) and how_ended = 'term_expired'.
--   NOTE: the stale Lynwood holder 'Alma Carina Larrazolo' shares the given names of trustee Alma Carina
--   Castro, but no source links the two surnames, so she is closed as a stale row and Castro is a new
--   row. If they are one person, the two politician rows should be merged later.
--
-- ---------------------------------------------------------------------------------------------------
-- C. ONE STALE HOLDER IS REAL AND STILL SEATED -- kept, term untouched (CA_0145 §C / 1546 precedent)
--   Linda Menges (Las Virgenes, dafc1db2)  lvusd.org lists her as Board Member; RR/CC lists LINDA
--   MENGES (E) as a winner in Nov 2020 and Nov 2024; her NetFile committee "Linda Menges for Las
--   Virgenes School Board 2024" is already confirmed on this row. Only her stored party is cleared.
--
-- ---------------------------------------------------------------------------------------------------
-- D. LYNWOOD GETS ITS FIFTH SEAT -- operator decision (2026-09-22): add missing seats to match
-- ---------------------------------------------------------------------------------------------------
-- mylusd.org lists five members; the DB has four 'Board Member' offices. One office is added
-- (260a6892), a copy of Lynwood's existing seat 39373ded (same chamber, district, title and flags), and
-- Gary Hardie Jr. is seated on it. It has no predecessor, so it needs no close.
--
-- ---------------------------------------------------------------------------------------------------
-- E. THE CURRENT BOARDS -- each district's own board page, fetched and read 2026-09-22
-- ---------------------------------------------------------------------------------------------------
--   Las Virgenes  lvusd.org/board-of-education/about-the-board (read in a browser)
--                 Stein, Cutbill, Lazar, Lawrence, Menges.
--   Lynwood       mylusd.org/governance/board-of-education (read in a browser)
--                 Morales, Lopez, Castro, Del Real-Calleros, Hardie.
--   Palos Verdes  pvpusd.net/apps/pages/index.jsp?uREC_ID=361970&type=d&pREC_ID=791785
--                 Deen, Kurt "Term Expires: 2026"; Alegria, Gandhi "2028"; Linda Reid "Provisional
--                 Member, Term Expires: 2026". Reid fills the seat of Julie Hamill (a 2022 winner), who
--                 resigned effective 2025-08-22; the board voted her provisional appointment on
--                 2025-09-25 (PVPUSD regular meeting, as summarised by citizenportal.ai). Reid's term
--                 starts on that appointment-vote date, precision 'day', how_started 'appointed'.
--   San Gabriel   sgusd.k12.ca.us/apps/pages/index.jsp?uREC_ID=414118&type=d&pREC_ID=903765
--                 Chi, Scott, Haas "Current Term: 2022-2026"; Shellhart, Mercado "2024-2028".
--   Wiseburn      wiseburn.org/school-board/school-board-members
--                 Bañuelos, Goldman, Hamburg-Cappy, Legaspi, Martinez.
-- Each elected member's CURRENT term is the cycle they last won per the RR/CC candidate lists (Nov 2022
-- = 4300, Nov 2024 = 4324). UNCONTESTED (candidates = seats, no result line) and so appointed in lieu of
-- election (Elections Code §10515, treated as elected): Lynwood 2022, San Gabriel 2022 and 2024,
-- Wiseburn 2022. TERM START = December of the election year, precision 'month' (CA_0143 §D).
--
-- ---------------------------------------------------------------------------------------------------
-- F. PEOPLE -- 21 new politician rows, 3 reused, 1 kept
-- ---------------------------------------------------------------------------------------------------
-- Reused confirmed LA County NetFile committee rows (transparent_motivations.politician_sources):
--   32fe047c Alan Lazar      "Alan Lazar for LVUSD Board of Education 2024"
--   6c43482f Alfonso Morales "ALFONSO MORALES FOR LYNWOOD SCHOOL BOARD 2022"
--   b5eb36c0 'Hardie'        "Hardie for Lynwood Schools 2024" -> name completed to Gary Hardie Jr.
-- NOT reused: 9f4f1f7f 'Gary Hardie' (scraped), a stale holder on Covina-Valley -- another session's
-- slice, which closed it in CA_0144. It may be the same misassigned person; that is flagged to them.
-- New rows: party NULL, is_active/is_incumbent true, data_source = the board page.
--
-- G. 2026 CANDIDATES -- the 10 RR/CC incumbents on the Las Virgenes, Lynwood, San Gabriel and Wiseburn
-- CA_0142 races are linked. Palos Verdes has no incumbent on its 2026 ballot.
--
-- NOT DONE HERE: stale holders keep party 'Nonpartisan' and is_active true; titles stay 'Board Member'.
--
-- ROLLBACK: DELETE the 24 office_terms rows whose source starts 'CA_0147:'; DELETE office 260a6892;
-- for the 23 closed stale rows (source contains '| closed CA_0147') SET term_end = NULL, how_ended =
-- NULL and strip the note; set is_incumbent = true on the 23 stale politicians; set
-- race_candidates.politician_id = NULL on the 10 rows linked here; DELETE the 21 new politicians. The
-- reused rows had is_incumbent false, party NULL, data_source NULL; b5eb36c0 had full_name 'Hardie'.
-- Menges had party 'Nonpartisan'.
--
-- IDEMPOTENT: office insert on id; stale closes on term_end IS NULL; new terms on (office, politician,
-- term_start); politicians on id; links on politician_id IS NULL.

BEGIN;

-- ─── Seat map ─────────────────────────────────────────────────────────────────────────────────────
-- action: 'replace' (stale out, member in) | 'keep' (verified holder) | 'add' (new seat, no predecessor)
CREATE TEMP TABLE _ca0147_seat (
  geo_id text, office_id uuid, stale_term_id uuid, stale_pol_id uuid, stale_name text,
  new_pol_id uuid, new_name text, term_start date, start_precision text, how_started text,
  in_lieu boolean, action text, how_ended text, evidence text
) ON COMMIT DROP;
INSERT INTO _ca0147_seat VALUES
  -- Las Virgenes Unified
  ('0621000','39028c31-c6fa-4734-a78a-d38c135f959d','5bdb4283-4a2f-4751-a965-db399eb2a4a7','8f5fded3-98c2-4703-8c83-4ccbf8a6cc7d','Barry Zorthian',        '60f3632e-892a-4c7a-bd10-92994858eaa1','Angela Cutbill',          '2022-12-01','month','elected',false,'replace','unknown',NULL),
  ('0621000','84953d82-f759-47ef-9c91-378654a533e0','12fb9568-e100-4505-ab7b-4ba5381497c0','dafc1db2-758f-498f-93f8-4f632b0adc7a','Linda Menges',          'dafc1db2-758f-498f-93f8-4f632b0adc7a','Linda Menges',            NULL,        NULL,   NULL,     NULL, 'keep',   NULL,     NULL),
  ('0621000','955d90c8-261a-4fa4-b28d-0d37f19d5c79','32c5d000-0008-4119-a3d6-e186076421be','62674342-08a9-48ba-bd31-6fb3fe3f8fde','Christine Wood',        '56baae7f-c67e-46bb-bd05-834bec68c7a8','Lesli Stein',             '2022-12-01','month','elected',false,'replace','unknown',NULL),
  ('0621000','bb531826-b719-4159-b5c8-42735da3c49b','d416fba7-a3b7-456b-abf1-fb8aecaa0063','49ff1385-476d-4bb3-9912-80202b106cbc','Shira Katz',            '8622fa01-401f-4638-9511-a502050eaa4f','Dallas Lawrence',         '2022-12-01','month','elected',false,'replace','unknown',NULL),
  ('0621000','f1cccaec-0c97-4717-8c9d-50fc4559df80','05610aec-fb48-4838-8dbb-b3e4f97b9300','695ab650-58df-43b8-b8c9-b075e1e519fd','Kate Vadehra',          '32fe047c-b34f-473c-9093-650a36619c7e','Alan Lazar',              '2024-12-01','month','elected',false,'replace','term_expired',
     'won Nov 2020 per LA County RR/CC (4193) and absent from the Nov 2024 list (4324), so the term expired in December 2024'),
  -- Lynwood Unified (4 existing seats + 1 added)
  ('0623160','39373ded-83ca-4b4b-be60-9142f0b91fe7','15772b69-5cfe-412f-9265-acc1e01c9873','8c0fdb31-0020-4d1f-a60b-230e1146eef5','Alma Carina Larrazolo', '6c43482f-7ede-443a-aa87-072d1c555eb6','Alfonso Morales',         '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0623160','447f4b0e-5ace-4d59-85c5-8c4740c207d7','9705a3d8-73d4-4feb-a2d1-86aac0395142','a4e55f6b-f062-4a7d-b86a-e5998d696a46','George Gamboa',         '7a78f35a-26ea-4d75-9192-d4299ee8efdf','Julian Del Real-Calleros','2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0623160','b0e2f393-870c-4615-8dde-3fef6f72f1ae','83734f8b-3e39-43eb-b68d-194cb8bf8c0d','d6b805e8-d1ac-4a22-9cdc-53d2779668ca','Jose Ro',               '88216292-7a3c-4e49-ac4a-722a1b3764e4','Maria G. Lopez',          '2024-12-01','month','elected',false,'replace','unknown',NULL),
  ('0623160','e336d32f-53a4-40bb-a393-17e6398c2ef1','7dc58a88-64ac-4cec-8a32-46dbb4391516','23b32605-c2be-473e-9dd6-4fc2974b80b6','Raul Saldana',          'f56f8ef5-102b-4706-b0b3-cc71ddb7c389','Alma Carina Castro',      '2024-12-01','month','elected',false,'replace','unknown',NULL),
  ('0623160','260a6892-1d5b-4eb1-85c1-50874d516dcf',NULL,NULL,NULL,                                                                                           'b5eb36c0-877f-4cf5-8f24-ed48b6fd8ced','Gary Hardie Jr.',         '2024-12-01','month','elected',false,'add',    NULL,     NULL),
  -- Palos Verdes Peninsula Unified
  ('0629700','34b5dfaf-1f7c-4300-9207-db8f59038292','642f92af-cf8a-431e-883b-a894bd6f19f1','9163f6fc-8e93-4065-a49b-a009ff443477','Stacy Hollingsworth',   '7369ca2d-8aa8-40af-ace0-99a039b6e940','Sara Deen',               '2022-12-01','month','elected',false,'replace','unknown',NULL),
  ('0629700','35a185bd-ef00-4618-96e2-773c8a852a62','f4b9f8ed-d9d1-4bd0-89d1-239aee6c9292','c95c888a-8857-421b-af4f-63ddcbace789','Sandra Dorit',          '36396884-07c8-46d0-a6dd-cb7336010591','Linda Kurt',              '2022-12-01','month','elected',false,'replace','unknown',NULL),
  ('0629700','7a6f043b-46b2-4a27-bca8-3954de3dcd23','7a84cad1-0103-4b38-8732-45a13010a6b8','649e6bdf-eaed-40aa-b383-3af5725209f3','David Maron',           '5f0a5523-6f18-49e0-93ff-6e27abe5024d','Linda Reid',              '2025-09-25','day',  'appointed',false,'replace','unknown',
     'provisionally appointed by board vote 2025-09-25 (PVPUSD regular meeting) to the seat Julie Hamill vacated effective 2025-08-22; term ends 2026 per pvpusd.net; term_start is the appointment-vote date'),
  ('0629700','c8815abe-726d-4ffe-adf0-a0c0e2c576e8','7e6da77e-e02d-4b53-b145-cc93df4e1c9f','96ee62ec-4a0d-4d02-8d2d-43b84f16a9de','Susan Craig',           '19970ef1-85b5-4556-a6f4-b229845a9427','Eric Alegria',            '2024-12-01','month','elected',false,'replace','unknown',NULL),
  ('0629700','d98af431-8750-4bae-8aa2-8958e6140f78','4a5fd7d8-7ee9-4dbc-a425-3a68d1cdd61e','7cbf6f43-43d0-4a61-84ed-277eb3a8cf05','Cindy Byelich',         'a737ac13-b26e-4f19-acf6-bac92694b30b','Ami Gandhi',              '2024-12-01','month','elected',false,'replace','unknown',NULL),
  -- San Gabriel Unified
  ('0634425','a8cc42d0-37b6-4737-98f7-e2861176c368','b88700e9-3219-42d5-8e81-515402e9d48d','3aeeb9e8-68e7-4bd3-a4ff-19958d46debd','Yvonne Marquez',        '15e67783-c78d-4269-b164-f7355f009d50','Gina Chi',                '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0634425','a9902dc7-8026-47d8-b297-f243431677e0','2b380ab1-9ceb-4ae6-8fa3-370b00f32648','d46f8101-1cc9-4f2f-8e6a-ceb58febba8b','Estela Sanchez-Torres', '803ee656-879e-438e-8ff6-072830ba2c86','Rochelle Kate Haas',      '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0634425','bef43616-51b2-4fe8-8dea-d713f5f2df68','3ee76bbf-c9cd-49fb-ac20-de45dcc3562e','e526fc4e-536d-4878-b1f0-5d2b903a6ee0','Megan Ngo',             '7b04dc2f-b4c0-420b-9146-e9d36acabc51','Gary Thomas Scott',       '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0634425','c199b76e-34bb-41c5-8d64-003ec3eaadc5','b48f4dc1-e80d-44e1-9e3a-128700d6dc6e','a4ed6e28-252b-4bd5-a6f2-ddb96c37aa3f','Yvette Vivanco',        '369e4734-8f60-4de6-a266-3429b17facdb','Robert Mercado',          '2024-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0634425','feec1c65-39be-4eab-b972-7b2e054eaea6','f0c50b8d-87b2-47d4-9be7-6801dbe9ed13','8825a1a2-c225-47d3-8848-8fa687f0f7ba','Nora Martinez',         '3d367052-95f5-47ed-bb65-f7f1f69fd9c8','Cheryl A. Shellhart',     '2024-12-01','month','elected',true, 'replace','unknown',NULL),
  -- Wiseburn Unified
  ('0601428','0ad519b3-d3cd-456a-91a9-72cf80aa70a0','e2db793a-2b55-4c26-8e93-ab761940a554','f12ba4c2-859f-4453-9b32-37624d0132a0','Anastasia Flores',      '222398b8-6bb0-489a-97c2-e39e6f01cc51','Roger Bañuelos',          '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0601428','3c013e26-641d-403c-bd24-2dc3b69ad020','e1468902-8253-4941-913c-b6c0337b31a1','9bd840d2-3877-42ab-ac68-961accbf9140','Michael Murphy',        'df12544d-85da-49e1-b780-491fa9a8d30e','Rebecca Hamburg-Cappy',   '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0601428','405e8520-7f2c-4a64-8ffe-10363d8ecef1','87b0504d-929d-48ea-bc72-02c7d66cb224','91687c59-c7b0-4b20-8bdd-8cd2ba3e07b5','Matt Addington',        'f0d1e10d-4b28-41b6-b511-a4df7091ada2','Nelson Martinez',         '2022-12-01','month','elected',true, 'replace','unknown',NULL),
  ('0601428','80257788-d2ef-42d4-bb92-e78b253d6d6b','bf60c027-ab24-43d5-86ee-60a7df7aa291','f930cd79-ce2f-4a9e-9e73-1d29a3abd4dc','Patricia Ollie',        '45f994cd-5c96-4f2a-9fb6-187d4f41dc00','Neil Goldman',            '2024-12-01','month','elected',false,'replace','unknown',NULL),
  ('0601428','ca07c80b-348c-4c88-81be-10ab5ccdc53b','e2c57e86-4485-4d8c-b5eb-8f34ff55f044','6fa8ba0f-8afc-4bfa-ba1a-970f2a50171f','Jody Dean',             '7c05cca9-0453-4414-bd38-d9afba3f830c','Michelle Legaspi',        '2024-12-01','month','elected',false,'replace','unknown',NULL);

CREATE TEMP TABLE _ca0147_district (geo_id text PRIMARY KEY, name text, board_url text) ON COMMIT DROP;
INSERT INTO _ca0147_district VALUES
  ('0621000','Las Virgenes Unified',           'https://www.lvusd.org/board-of-education/about-the-board'),
  ('0623160','Lynwood Unified',                'https://www.mylusd.org/governance/board-of-education'),
  ('0629700','Palos Verdes Peninsula Unified', 'https://www.pvpusd.net/apps/pages/index.jsp?uREC_ID=361970&type=d&pREC_ID=791785'),
  ('0634425','San Gabriel Unified',            'https://www.sgusd.k12.ca.us/apps/pages/index.jsp?uREC_ID=414118&type=d&pREC_ID=903765'),
  ('0601428','Wiseburn Unified',               'https://www.wiseburn.org/school-board/school-board-members');

CREATE TEMP TABLE _ca0147_reused (id uuid PRIMARY KEY, full_name text, committee_like text, add_alternate text[]) ON COMMIT DROP;
INSERT INTO _ca0147_reused VALUES
  ('32fe047c-b34f-473c-9093-650a36619c7e','Alan Lazar',      '%Alan Lazar for LVUSD Board of Education 2024%',   '{}'),
  ('6c43482f-7ede-443a-aa87-072d1c555eb6','Alfonso Morales', '%ALFONSO MORALES FOR LYNWOOD SCHOOL BOARD 2022%',  '{}'),
  ('b5eb36c0-877f-4cf5-8f24-ed48b6fd8ced','Hardie',          '%Hardie for Lynwood Schools 2024%',                '{"Gary Hardie, Jr.","Gary Hardie"}');

CREATE TEMP TABLE _ca0147_newpol (
  id uuid PRIMARY KEY, geo_id text, full_name text, first_name text, last_name text,
  preferred_name text, alternate_names text[]
) ON COMMIT DROP;
INSERT INTO _ca0147_newpol VALUES
  ('60f3632e-892a-4c7a-bd10-92994858eaa1','0621000','Angela Cutbill',          'Angela',  'Cutbill',         NULL,   '{}'),
  ('56baae7f-c67e-46bb-bd05-834bec68c7a8','0621000','Lesli Stein',             'Lesli',   'Stein',           NULL,   '{}'),
  ('8622fa01-401f-4638-9511-a502050eaa4f','0621000','Dallas Lawrence',         'Dallas',  'Lawrence',        NULL,   '{"Dallas B. Lawrence"}'),
  ('7a78f35a-26ea-4d75-9192-d4299ee8efdf','0623160','Julian Del Real-Calleros','Julian',  'Del Real-Calleros',NULL,  '{}'),
  ('88216292-7a3c-4e49-ac4a-722a1b3764e4','0623160','Maria G. Lopez',          'Maria',   'Lopez',           NULL,   '{"Maria G. López"}'),
  ('f56f8ef5-102b-4706-b0b3-cc71ddb7c389','0623160','Alma Carina Castro',      'Alma',    'Castro',          NULL,   '{}'),
  ('7369ca2d-8aa8-40af-ace0-99a039b6e940','0629700','Sara Deen',               'Sara',    'Deen',            NULL,   '{"Sara H. Deen"}'),
  ('36396884-07c8-46d0-a6dd-cb7336010591','0629700','Linda Kurt',              'Linda',   'Kurt',            NULL,   '{}'),
  ('5f0a5523-6f18-49e0-93ff-6e27abe5024d','0629700','Linda Reid',              'Linda',   'Reid',            NULL,   '{"Linda D. Reid"}'),
  ('19970ef1-85b5-4556-a6f4-b229845a9427','0629700','Eric Alegria',            'Eric',    'Alegria',         NULL,   '{}'),
  ('a737ac13-b26e-4f19-acf6-bac92694b30b','0629700','Ami Gandhi',              'Ami',     'Gandhi',          NULL,   '{}'),
  ('15e67783-c78d-4269-b164-f7355f009d50','0634425','Gina Chi',                'Gina',    'Chi',             NULL,   '{"Gina L. Chi"}'),
  ('803ee656-879e-438e-8ff6-072830ba2c86','0634425','Rochelle Kate Haas',      'Rochelle','Haas',            NULL,   '{"Rochelle Kate Ongsiako Haas"}'),
  ('7b04dc2f-b4c0-420b-9146-e9d36acabc51','0634425','Gary Thomas Scott',       'Gary',    'Scott',           NULL,   '{}'),
  ('369e4734-8f60-4de6-a266-3429b17facdb','0634425','Robert Mercado',          'Robert',  'Mercado',         NULL,   '{}'),
  ('3d367052-95f5-47ed-bb65-f7f1f69fd9c8','0634425','Cheryl A. Shellhart',     'Cheryl',  'Shellhart',       NULL,   '{}'),
  ('222398b8-6bb0-489a-97c2-e39e6f01cc51','0601428','Roger Bañuelos',          'Roger',   'Bañuelos',        NULL,   '{"Rogelio \"Roger\" Bañuelos","Rogelio Bañuelos","Roger Banuelos"}'),
  ('df12544d-85da-49e1-b780-491fa9a8d30e','0601428','Rebecca Hamburg-Cappy',   'Rebecca', 'Hamburg-Cappy',   NULL,   '{"Rebecca Hamburg Cappy"}'),
  ('f0d1e10d-4b28-41b6-b511-a4df7091ada2','0601428','Nelson Martinez',         'Nelson',  'Martinez',        NULL,   '{"Nelson E. Martinez"}'),
  ('45f994cd-5c96-4f2a-9fb6-187d4f41dc00','0601428','Neil Goldman',            'Neil',    'Goldman',         NULL,   '{}'),
  ('7c05cca9-0453-4414-bd38-d9afba3f830c','0601428','Michelle Legaspi',        'Michelle','Legaspi',         NULL,   '{"Michelle Bella Legaspi"}');

CREATE TEMP TABLE _ca0147_link (race_id uuid, rc_full_name text, politician_id uuid) ON COMMIT DROP;
INSERT INTO _ca0147_link VALUES
  ('5fd9a005-3769-406a-954f-d934c4ed3546','Angela Cutbill',              '60f3632e-892a-4c7a-bd10-92994858eaa1'),
  ('5fd9a005-3769-406a-954f-d934c4ed3546','Dallas Lawrence',             '8622fa01-401f-4638-9511-a502050eaa4f'),
  ('eb5a6b30-5d4d-48b6-a156-6622c8aa872e','Julian Del Real-Calleros',    '7a78f35a-26ea-4d75-9192-d4299ee8efdf'),
  ('eb5a6b30-5d4d-48b6-a156-6622c8aa872e','Alfonso Morales',             '6c43482f-7ede-443a-aa87-072d1c555eb6'),
  ('f5edf188-f4c9-4631-b029-72c627322586','Gina L. Chi',                 '15e67783-c78d-4269-b164-f7355f009d50'),
  ('f5edf188-f4c9-4631-b029-72c627322586','Rochelle Kate Ongsiako Haas', '803ee656-879e-438e-8ff6-072830ba2c86'),
  ('f5edf188-f4c9-4631-b029-72c627322586','Gary Thomas Scott',           '7b04dc2f-b4c0-420b-9146-e9d36acabc51'),
  ('e95c9e92-7a83-468c-bb5c-2375e74e214e','Rogelio "Roger" Bañuelos',    '222398b8-6bb0-489a-97c2-e39e6f01cc51'),
  ('e95c9e92-7a83-468c-bb5c-2375e74e214e','Rebecca Hamburg Cappy',       'df12544d-85da-49e1-b780-491fa9a8d30e'),
  ('e95c9e92-7a83-468c-bb5c-2375e74e214e','Nelson E. Martinez',          'f0d1e10d-4b28-41b6-b511-a4df7091ada2');

-- ─── Pre-flight: derive-then-verify every identifier ─────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the 24 existing seats (all but the added one) are 'Board Member' on their SCHOOL/G5420 district
  SELECT count(*) INTO v_n FROM _ca0147_seat s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.action <> 'add' AND d.geo_id = s.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
     AND o.title = 'Board Member';
  IF v_n <> 24 THEN RAISE EXCEPTION 'PRE: % of 24 existing seat offices resolve to their SCHOOL/G5420 district', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0147_district)
     AND o.id <> '260a6892-1d5b-4eb1-85c1-50874d516dcf';
  IF v_n <> 24 THEN RAISE EXCEPTION 'PRE: the 5 districts hold % pre-existing offices, expected 24', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0147_seat s
    JOIN essentials.office_terms t ON t.id = s.stale_term_id AND t.office_id = s.office_id AND t.politician_id = s.stale_pol_id
    JOIN essentials.politicians p ON p.id = s.stale_pol_id AND p.full_name = s.stale_name
   WHERE s.action <> 'add' AND t.term_start IS NULL
     AND (t.term_end IS NULL
          OR (s.action = 'replace' AND t.term_end = s.term_start - 1 AND t.source LIKE '%| closed CA_0147%'));
  IF v_n <> 24 THEN RAISE EXCEPTION 'PRE: % of 24 existing terms match the recorded (id, office, politician, name)', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT stale_pol_id FROM _ca0147_seat WHERE action = 'replace');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % stance answers -- retire them first', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT stale_pol_id FROM _ca0147_seat WHERE stale_pol_id IS NOT NULL)
     AND t.id NOT IN (SELECT stale_term_id FROM _ca0147_seat WHERE stale_term_id IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale/kept holders hold % other office_terms', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0147_reused r JOIN essentials.politicians p ON p.id = r.id
   WHERE p.full_name = r.full_name OR (r.id = 'b5eb36c0-877f-4cf5-8f24-ed48b6fd8ced' AND p.full_name = 'Gary Hardie Jr.');
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 reused politician rows match', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0147_reused r
   WHERE EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                  WHERE ps.essentials_politician_id = r.id AND ps.source_system = 'la_county_netfile'
                    AND ps.research_status = 'confirmed' AND ps.notes ILIKE r.committee_like);
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 NetFile committees confirm the reused rows', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT id FROM _ca0147_reused) AND t.source NOT LIKE 'CA_0147:%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: reused rows hold % unexpected office_terms', v_n; END IF;

  -- the Lynwood template seat is what the added seat is copied from
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id = '39373ded-83ca-4b4b-be60-9142f0b91fe7' AND d.geo_id = '0623160' AND o.title = 'Board Member';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Lynwood template seat 39373ded not found'; END IF;

  SELECT count(DISTINCT r.id) INTO v_n FROM essentials.races r
   WHERE r.id IN (SELECT race_id FROM _ca0147_link)
     AND r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND r.office_id IN (SELECT office_id FROM _ca0147_seat);
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 CA_0142 races resolve to these seats', v_n; END IF;
END $$;

-- ─── 1. Lynwood's fifth seat (a copy of seat 39373ded) ──────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
   faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT '260a6892-1d5b-4eb1-85c1-50874d516dcf', o.chamber_id, o.district_id, o.title, o.representing_state,
       o.representing_city, o.description, o.seats, o.normalized_position_name, o.partisan_type, o.salary,
       o.is_appointed_position, false, NULL, o.faces_retention_vote, o.role_canonical, o.voting_powers,
       o.representation_note
  FROM essentials.offices o
 WHERE o.id = '39373ded-83ca-4b4b-be60-9142f0b91fe7'
ON CONFLICT (id) DO NOTHING;

-- ─── 2. New politician rows (21) ─────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, preferred_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.alternate_names,
       true, false, true, NULL, d.board_url, 'CA_0147_la_unified_board_rosters_batch3'
  FROM _ca0147_newpol n JOIN _ca0147_district d ON d.geo_id = n.geo_id
ON CONFLICT (id) DO NOTHING;

-- ─── 3. Reused and kept rows: seated -> incumbent, no stored party ───────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = true, party = NULL, data_source = COALESCE(p.data_source, d.board_url),
       alternate_names = ARRAY(SELECT DISTINCT unnest(p.alternate_names || r.add_alternate))
  FROM _ca0147_reused r, _ca0147_seat s JOIN _ca0147_district d ON d.geo_id = s.geo_id
 WHERE p.id = r.id AND s.new_pol_id = r.id
   AND (p.is_incumbent IS DISTINCT FROM true OR p.party IS NOT NULL OR p.data_source IS NULL
        OR NOT p.alternate_names @> r.add_alternate);

UPDATE essentials.politicians
   SET full_name = 'Gary Hardie Jr.', first_name = 'Gary'
 WHERE id = 'b5eb36c0-877f-4cf5-8f24-ed48b6fd8ced' AND full_name = 'Hardie' AND NOT full_name_manual_override;

UPDATE essentials.politicians p
   SET party = NULL, is_incumbent = true
 WHERE p.id IN (SELECT new_pol_id FROM _ca0147_seat WHERE action = 'keep')
   AND (p.party IS NOT NULL OR NOT p.is_incumbent);

-- ─── 4. Close the 23 stale terms ─────────────────────────────────────────────────────────────────
UPDATE essentials.office_terms t
   SET term_end  = s.term_start - 1,
       how_ended = s.how_ended,
       source    = t.source || ' | closed CA_0147 (2026-09-22): holder is not on the verified current '
                   || d.name || ' board (' || d.board_url || '); '
                   || CASE WHEN s.how_ended = 'term_expired' THEN s.evidence
                           ELSE 'actual last day NOT researched -- term_end is the day before the successor on this generic seat took office' END
  FROM _ca0147_seat s JOIN _ca0147_district d ON d.geo_id = s.geo_id
 WHERE t.id = s.stale_term_id
   AND s.action = 'replace'
   AND t.term_end IS NULL;

-- ─── 5. Seat the 24 current members (23 replacements + the added Lynwood seat) ───────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT s.office_id, s.new_pol_id, s.term_start, s.start_precision, s.how_started,
       'CA_0147: ' || d.name || ' board roster, ' || d.board_url || ' (read 2026-09-22); '
       || CASE WHEN s.how_started = 'appointed' THEN s.evidence
               ELSE 'current term won Nov ' || extract(year FROM s.term_start)::int
                    || ' per LA County RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id='
                    || CASE extract(year FROM s.term_start)::int WHEN 2022 THEN '4300' ELSE '4324' END
                    || CASE WHEN s.in_lieu THEN ' (uncontested; appointed in lieu of election, Elec. Code 10515)' ELSE '' END
                    || '; term begins December ' || extract(year FROM s.term_start)::int || ' (Ed. Code 5017), month precision'
          END
       || CASE WHEN s.action = 'add' THEN '; seated on a seat added by CA_0147 (the DB had 4 seats for a 5-member board)' ELSE '' END
  FROM _ca0147_seat s JOIN _ca0147_district d ON d.geo_id = s.geo_id
 WHERE s.action IN ('replace','add')
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = s.office_id AND t.politician_id = s.new_pol_id
                      AND t.term_start = s.term_start);

-- ─── 6. Stale holders are no longer incumbents ───────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.id IN (SELECT stale_pol_id FROM _ca0147_seat WHERE action = 'replace')
   AND p.is_incumbent
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── 7. Link the 2026 incumbents ─────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET politician_id = l.politician_id
  FROM _ca0147_link l
 WHERE rc.race_id = l.race_id
   AND lower(rc.full_name) = lower(l.rc_full_name)
   AND rc.is_incumbent
   AND rc.politician_id IS NULL;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0147_seat s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id AND och.politician_id = s.new_pol_id;
  IF v_n <> 25 THEN RAISE EXCEPTION 'POST: % of 25 seats resolve to the intended current member', v_n; END IF;

  SELECT count(*) INTO v_bad FROM (
    SELECT d.geo_id
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
     WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0147_district)
     GROUP BY d.geo_id
    HAVING count(DISTINCT o.id) <> 5 OR count(DISTINCT p.id) <> 5 OR bool_or(o.is_vacant)) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) do not show 5 seats with 5 active incumbent holders', v_bad; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT new_pol_id FROM _ca0147_seat) AND p.party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) carry a stored party', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     WHERE och.politician_id IN (SELECT new_pol_id FROM _ca0147_seat)
     GROUP BY 1 HAVING count(*) <> 1) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) hold <> 1 current seat', v_bad; END IF;

  SELECT count(*) INTO v_n FROM _ca0147_seat s JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.politician_id = s.new_pol_id
   WHERE s.action IN ('replace','add')
     AND t.term_start = s.term_start AND t.start_precision = s.start_precision
     AND t.how_started = s.how_started AND t.term_end IS NULL AND t.source LIKE 'CA_0147:%';
  IF v_n <> 24 THEN RAISE EXCEPTION 'POST: % of 24 new terms have the expected shape', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0147_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'replace' AND t.term_end = s.term_start - 1
     AND t.how_ended = s.how_ended AND t.source LIKE '%| closed CA_0147%';
  IF v_n <> 23 THEN RAISE EXCEPTION 'POST: % of 23 stale terms closed as intended', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0147_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'keep' AND t.term_start IS NULL AND t.term_end IS NULL AND t.how_ended IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % of 1 kept term untouched', v_n; END IF;

  -- the added seat carries exactly one term (Hardie) and mirrors its template's chamber
  SELECT count(*) INTO v_n FROM essentials.offices a JOIN essentials.offices t0 ON t0.id = '39373ded-83ca-4b4b-be60-9142f0b91fe7'
   WHERE a.id = '260a6892-1d5b-4eb1-85c1-50874d516dcf' AND a.chamber_id = t0.chamber_id AND a.district_id = t0.district_id
     AND a.title = t0.title AND (SELECT count(*) FROM essentials.office_terms x WHERE x.office_id = a.id) = 1;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: added Lynwood seat is not as intended'; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT stale_pol_id FROM _ca0147_seat WHERE action = 'replace')
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % stale holder(s) still current or incumbent', v_bad; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices ro ON ro.id = r.office_id
    JOIN essentials.office_current_holder och ON och.politician_id = rc.politician_id
    JOIN essentials.offices ho ON ho.id = och.office_id AND ho.district_id = ro.district_id
   WHERE r.id IN (SELECT race_id FROM _ca0147_link) AND rc.is_incumbent;
  IF v_n <> 10 THEN RAISE EXCEPTION 'POST: % of 10 incumbent candidates linked to a current holder of their district', v_n; END IF;
  SELECT count(*) INTO v_bad FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM _ca0147_link) AND rc.is_incumbent AND rc.politician_id IS NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % incumbent candidate(s) on these races still unlinked', v_bad; END IF;
  -- Palos Verdes: its 2026 race has no incumbent, so none can be left unlinked
  SELECT count(*) INTO v_bad FROM essentials.race_candidates rc
   WHERE rc.race_id = '683ae5ab-f176-4e5b-9442-e63b0590dd49' AND rc.is_incumbent;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: PVPUSD 2026 race unexpectedly carries % incumbent(s)', v_bad; END IF;

  SELECT count(*) INTO v_bad FROM _ca0147_district x
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

  RAISE NOTICE 'CA_0147 applied: 23 seats re-seated + 1 kept + 1 Lynwood seat added across 5 LA unified boards; 23 stale terms closed; 21 politicians created, 3 reused; 10 candidates linked';
END $$;

COMMIT;
