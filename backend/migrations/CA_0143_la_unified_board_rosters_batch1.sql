-- CA_0143_la_unified_board_rosters_batch1.sql
-- Replace the STALE sitting members of five LA-County AT-LARGE unified school boards with the
-- verified current boards, in essentials.office_terms (the only occupancy source; ADR 0002).
--
--   Culver City Unified   0610260      Walnut Valley Unified 0641280      El Segundo Unified 0612210
--   El Rancho Unified     0612180      West Covina Unified   0642000
--
-- Plus ONE row on Charter Oak Unified (0608190): the wrong-seat term of Larry Redinger (see §C).
-- The rest of Charter Oak belongs to the trustee-area slice another session is doing (agreed
-- 2026-09-22); this file does not touch its other four seats.
--
-- No migration runner exists; this file records SQL applied by hand via
--   npx tsx scripts/_apply-file.ts <abs path>/backend/migrations/CA_0143_la_unified_board_rosters_batch1.sql
-- (pure DML -> DATABASE_URL / ev_api is fine).
--
-- ---------------------------------------------------------------------------------------------------
-- A. THE DEFECT
-- ---------------------------------------------------------------------------------------------------
-- Each district holds 5 generic 'Board Member' offices on ONE whole-district SCHOOL row (TIGER
-- unified polygon, mtfcc G5420), each seated by an office_terms row that migration 1459 backfilled
-- from the old offices.politician_id pointer: term_start NULL, term_end NULL, start_precision
-- 'unknown', no source beyond the backfill. The politicians carry
-- data_source 'https://empowered.vote/school-district/<name>'. NONE of the 25 is on the current
-- board. Across all 47 LA-County unified districts, 239 such holders exist and only 18 appear on ANY
-- LA County Registrar-Recorder (RR/CC) candidate list or result for Nov 2020 / 2022 / 2024. Several
-- are real people from a much older board (Culver City's Scott Zeidman and Kathy Paspalis); many
-- have no trace at all (web search for Culver City's Dawn Espe, Sadie Farber and Jamila Thomas, and
-- for El Segundo's Al Winkler and Amanda Grossman, finds no board service); and at least
-- two are real trustees of a DIFFERENT district (Larry Redinger, Walnut Valley, seated on Charter
-- Oak; Vivian Malauulu, Long Beach, seated on ABC).
-- CORRECTION (2026-09-23, from the CA_0156 holder audit): an earlier version of this header also
-- listed El Segundo's Robin Funk as having no trace. That was wrong -- Robin Funk served on the El
-- Segundo board 2005-2013. This comment-only fix changes nothing that was applied.
--
-- ---------------------------------------------------------------------------------------------------
-- B. HOW THE STALE TERMS ARE ENDED -- operator decision (Chris Andrews, 2026-09-22)
-- ---------------------------------------------------------------------------------------------------
-- Offered: close all / delete unverified rows / research each person first. Chosen: CLOSE ALL.
--   * term_end  = the day before the successor on the same generic seat took office -- the only way
--                 this schema expresses consecutive occupancy (office_terms_no_overlap is inclusive
--                 on both ends; same reasoning as migration 1546). It is a MODELLING CONSEQUENCE, not
--                 a researched last day: the seats are generic, so which stale holder is paired with
--                 which successor is arbitrary. The source note on every closed row says so.
--   * how_ended = 'unknown'.
--   * politicians.is_incumbent = false (the flat-list gate reads it directly; see 1546).
--     is_active is LEFT ALONE, as in 1546 -- its blast radius was not measured here.
--   * Rows with POSITIVE proof of a wrong seat are DELETED instead (the 1588 / 1566 standard: the
--     person is documented on a different board). In this batch that is only §C.
--
-- ---------------------------------------------------------------------------------------------------
-- C. LARRY REDINGER -- deleted from Charter Oak, seated on Walnut Valley
-- ---------------------------------------------------------------------------------------------------
-- Politician fca9a696-f3c7-4673-a9ec-4eb05ba74aa1 ('Larry Redinger', data_source charter_oak_unified)
-- holds Charter Oak office dd55b530-73ea-4657-aa27-fa5d414d1fec via term 7e807116. He is a WALNUT
-- VALLEY trustee: wvusd.org lists "Larry L. Redinger, Member, Year Term Expires: 2028"; RR/CC lists
-- him on the WVUSD contest in Nov 2020 (won, 14,628 votes) and Nov 2024 (incumbent, E). Charter Oak's
-- own board page (cousd.net) lists five trustees and not him. So the Charter Oak term is deleted and
-- his row is reused on WVUSD. Charter Oak office dd55b530 is left with NO term row until the
-- trustee-area slice seats its member there; the district keeps 4 active holders, so this is not
-- DEAD_GEOGRAPHY (that check is per district), but offices_missing_terms rises by 1 until then.
--   Deleted row, verbatim, for rollback:
--     INSERT INTO essentials.office_terms (id, office_id, politician_id, term_start, term_end,
--       start_precision, how_started, how_ended, source, created_at)
--     VALUES ('7e807116-f881-4ee6-a600-aac3000b6c26', 'dd55b530-73ea-4657-aa27-fa5d414d1fec',
--       'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1', NULL, NULL, 'unknown', NULL, NULL,
--       'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)',
--       '2026-07-26 01:09:06.415146+00');
--
-- ---------------------------------------------------------------------------------------------------
-- D. THE CURRENT BOARDS -- each district's own board page, fetched and read 2026-09-22
-- ---------------------------------------------------------------------------------------------------
--   Culver City   ccusd.org/apps/pages/index.jsp?uREC_ID=42334&type=d&pREC_ID=51428
--                 Loredo, Guerrero, Ezidore "Term of Office: 12/1/22 - 11/30/26";
--                 Lachman, Carlson "12/1/24 - 11/30/28".
--   Walnut Valley wvusd.org/apps/pages/index.jsp?uREC_ID=54504&type=d&pREC_ID=2645128
--                 Torng, Ruiz, Hall "Year Term Expires: 2026"; Abou-Taleb, Redinger "2028".
--   El Segundo    elsegundousd.net/page/board-members (behind a JS challenge; read in a browser)
--                 Beachly, Glynn, Miller-Zarneke, Wheaton, Sutherland.
--   El Rancho     erusd.org/apps/pages/index.jsp?uREC_ID=4482985&type=d&pREC_ID=2748416
--                 LaFarga, Mejia, Contreras "Term Expires 2026"; Saavedra, Perez "2028".
--   West Covina   wcusd.org/board/members (read in a browser)
--                 Magallanes, Lopez, Flowers, Cruz, Miranda Jimenez.
-- Every name is cross-checked against the RR/CC candidate lists (lavote.gov/Apps/CandidateList/
-- Index?id=N; incumbent flag E/A): Nov 2022 = 4300, Nov 2024 = 4324, Nov 2026 = 4348. Each member's
-- CURRENT term is the cycle they last won: 2022 winners are the RR/CC "E" incumbents on the Nov 2026
-- list; 2024 winners are on the Nov 2024 list and on the board now. Nov 2024 was UNCONTESTED in
-- Walnut Valley, El Segundo and West Covina (candidates = seats, no result line), so those members
-- were appointed in lieu of election; under Elections Code §10515 such an appointee takes office and
-- serves as if elected, hence how_started 'elected'.
--
-- TERM START = December of the election year, start_precision 'month'. Ed. Code §5017 starts the term
-- on the second Friday in December (2022-12-09, 2024-12-13); Culver City's own page says 12/1. The
-- MONTH is what every source agrees on, so that is what is asserted.
--
-- ---------------------------------------------------------------------------------------------------
-- E. PEOPLE -- 20 new politician rows, 5 reused
-- ---------------------------------------------------------------------------------------------------
-- Reused, not duplicated (the name-duplicate guard would also refuse a copy):
--   38aa3e5d Triston Ezidore  netfile_laco_2024, committee "Triston Ezidore for Culver City Unified School Board 2022"
--   2648c09b Andrew Lachman   netfile_laco_2024, committee "Andrew Lachman for Culver City Unified Board of Education 2024"
--   a73ad2b6 'Loredo'         netfile_laco_2024, committee "LOREDO FOR CULVER CITY UNIFIED SCHOOL BOARD 2022"
--                             -> name completed to Stephanie Loredo (only if the name is still unedited)
--   b1c4c42c Arlene Perez     netfile_laco_2024, committee "Arlene Perez for El Rancho Unified School District School Board for 2024"
--   fca9a696 Larry Redinger   §C; data_source repointed from charter_oak_unified to the WVUSD page
-- (all four netfile committees are research_status 'confirmed' in transparent_motivations.politician_sources)
-- Reusing them joins their campaign-finance records to the seated member.
-- New rows: party NULL (party is never stored), is_active/is_incumbent true, data_source = the
-- district board page. Ballot-name variants go in alternate_names. Seated reused rows also get
-- party NULL and is_incumbent true.
--
-- ---------------------------------------------------------------------------------------------------
-- F. 2026 CANDIDATES -- link the incumbents CA_0142 left unlinked
-- ---------------------------------------------------------------------------------------------------
-- CA_0142 seeded these five boards' Nov 3 2026 races and linked only Ezidore. The 13 other RR/CC
-- incumbents on those races are linked here to the politician rows seated above, so a candidate card
-- and the member's profile are one person. The CA_0142 race office on each district (lowest office
-- id) is kept and receives a 2022-cohort member -- the cohort whose seats are on that ballot.
--
-- ---------------------------------------------------------------------------------------------------
-- G. NOT DONE HERE
-- ---------------------------------------------------------------------------------------------------
--   * The other 42 LA unified districts (later batches; the 23 trustee-area ones are another
--     session's slice). Malauulu's wrong ABC seat is fixed with the Long Beach batch.
--   * The stale holders keep party 'Nonpartisan' and is_active true -- not touched, flagged.
--   * Titles stay the generic 'Board Member'.
--
-- ROLLBACK: DELETE the 25 office_terms rows whose source starts 'CA_0143:'; for the 25 closed stale
--   rows (source contains '| closed CA_0143') SET term_end = NULL, how_ended = NULL and strip the
--   note; re-insert the §C row; set is_incumbent = true on the 25 stale politicians; set
--   race_candidates.politician_id = NULL on the 13 rows linked here; DELETE the 20 new politicians
--   (ids in §1). The four reused netfile rows had is_incumbent false, party NULL, data_source NULL;
--   a73ad2b6 had full_name 'Loredo', first_name NULL; fca9a696 had party 'Nonpartisan', data_source
--   'https://empowered.vote/school-district/charter_oak_unified', alternate_names '{}'.
--
-- IDEMPOTENT: stale closes are guarded on term_end IS NULL; new terms on (office, politician,
-- term_start); politicians on id; links on politician_id IS NULL; the §C delete on its exact id.

BEGIN;

-- ─── Seat map: one row per seat (office), stale holder out, current member in ────────────────────
CREATE TEMP TABLE _ca0143_seat (
  geo_id text, office_id uuid, stale_term_id uuid, stale_pol_id uuid, stale_name text,
  new_pol_id uuid, new_name text, elected_year int
) ON COMMIT DROP;
INSERT INTO _ca0143_seat VALUES
  -- Culver City Unified
  ('0610260','258245d9-03ee-49d7-9d52-4bbdadc60bd8','5d2404f2-8e43-4106-a163-67393141baf3','6fe04ab6-3df4-4472-ac27-4c35a9c2f72f','Jamila Thomas',       '38aa3e5d-2824-4810-af6d-ad4d8f2bd359','Triston Ezidore',          2022),
  ('0610260','50e25445-33ea-462d-a478-379d290d6738','aef88766-ab6c-48d5-8ddb-d250b3d94a39','628180d5-26f9-4213-b2c7-6c22ceb120ef','Dawn Espe',           '40df5b12-202f-4f06-917d-5b9883441046','Brian Guerrero',           2022),
  ('0610260','b8447084-3c83-40da-b8b6-4783ff524fe0','ef1f61c8-5381-4eee-968d-b4b6a9f42e37','c46ce1ed-be39-4986-a070-4d12f37ee979','Sadie Farber',        'a73ad2b6-dedd-4186-b451-cf8b7898c098','Stephanie Loredo',         2022),
  ('0610260','f53bee9a-70af-457c-b706-1b508abc022a','a4d082fc-fe22-46ce-8df4-b752c94ed18b','599376b6-bdfa-4b76-837f-dd2230a546ad','Scott Zeidman',       '86d016c2-eeca-4fab-bef6-d9a279e3e0fb','Lindsay Carlson',          2024),
  ('0610260','f7da018f-c43b-4a9d-8121-5be11673e73b','ce261c21-c16d-44b8-8e0d-f89e6887217c','5501c147-5dad-48d5-845c-b6b91e8860a9','Kathy Paspalis',      '2648c09b-747d-4a97-a949-26b9a99b6b3f','Andrew Lachman',           2024),
  -- Walnut Valley Unified
  ('0641280','27b9bef7-54d1-41a0-8b9d-2d282f17165b','909ceb3c-51da-4660-b127-e0a762feac1b','1d6cb616-1d88-4010-9d91-2f13f625c58f','Noy Palacios',        '442cb09c-c590-4eb8-9718-00967d719e52','Helen M. Hall',            2022),
  ('0641280','28a7545e-1972-49a5-8c48-176360e6e8ed','5e03768a-d55c-42f8-aba9-d6a2387688eb','23e22371-fd7f-470d-9d2e-4bb9151bceb1','Nathan Donato',       '31472d29-6c13-42fa-b6a9-1cf53b71e824','Cynthia M. Ruiz',          2022),
  ('0641280','75dfd15b-f566-425f-a8e2-7a70703773fc','d74a0db7-dd97-4873-b7ac-ef7a7621085c','4a11c484-260d-4f62-a7d3-2011cd163f70','Wenling Chin',        'be0686f9-51e1-45b4-a1dd-518e898492c5','Yi "Tony" Torng',          2022),
  ('0641280','a20419cc-cdea-4634-a822-7dcfebb832f1','8f465241-1a10-4eba-9911-10943bc4b18e','a077e0db-3534-46b9-aee9-40eafb0d019a','John Castellano',     'd40a1ff0-1354-4095-89da-2e29e2bab349','Layla Abou-Taleb',         2024),
  ('0641280','c7e429be-2ca9-49e2-a3c0-152de408053d','18461e7e-7205-491c-89a0-0b1d11cbae91','509fe7b3-e444-4b85-9ffe-850d2adf7809','Cindy Ruelas',        'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1','Larry Redinger',           2024),
  -- El Segundo Unified
  ('0612210','390f56be-9ba2-4246-956c-48a5e08d76a0','7499d29c-e884-4aae-9120-e7952ac8cd27','81154d3e-fe2c-4864-a341-5c8c8538e4b6','Al Winkler',          '4ecc7d76-22da-44a6-b2b9-bd029046368d','Meredith J. Beachly',      2022),
  ('0612210','48a5ac58-cb33-4a7b-9839-e3f86b6e583a','8d50a6da-2a88-449e-8f0f-7d868684c5e5','1bef4877-5dec-4460-ad79-a7ecb186c1b8','Amanda Grossman',     'ec2a615b-7f6e-4e14-9fc2-2dfa8f0501c5','Frank C. Glynn',           2022),
  ('0612210','98464401-cad8-452f-9203-8c295fd8663c','a92dc792-c45a-43e0-8326-64f0701fe53b','c7a69d69-20b9-4d54-ab4a-33198c9f7c78','Christian Thomas',    'b261afca-4cb9-4a59-9521-704307bf69d4','Tracey I. Miller-Zarneke', 2022),
  ('0612210','cb8276fc-8cfd-42d6-896c-98423ffd3ffa','8df2819c-e3ce-407e-8e92-72724789562e','4a484a17-5426-403c-8c51-0b7e387a07b1','Robin Funk',          '25ebeb0e-9985-45fc-a5b2-aa64993bbcf7','Heather E. Sutherland',    2024),
  ('0612210','d1b6166b-c7b5-440e-8251-9d41af22244b','c4fe848e-053b-46b5-9abf-edc3e7213279','d0f59905-f5e3-4e38-a3df-2dc6fb51a4a4','Dave Horner',         '053ba101-06bc-4d39-a998-95eff7c977a8','Dieema A. Wheaton',        2024),
  -- El Rancho Unified
  ('0612180','2dff60c3-71be-434a-93c0-b8b60b4dda42','0dacbe98-b1e1-47f9-bd2c-4141c245744a','4956d410-f77a-43f8-92c8-e8827e50a17a','Lesley Chavez Magan', 'a45c73fc-6bb1-4642-b5b4-56da17b21fc1','John Contreras',           2022),
  ('0612180','49cf4fcd-edd1-42d0-ba41-520f33b70189','3c2ae209-3875-478c-afaa-2fe80582946e','ea4552a4-3112-4089-9902-1630715cba97','Raquel Otiniano',     'b85eeb90-e183-4ad4-ab05-663f3de31ba0','Hector LaFarga Jr.',       2022),
  ('0612180','e008fc2c-e56f-4e88-b67d-1fc83317264e','0c508367-77f9-4f78-a711-2979a8976d8f','134cc13a-f45a-442c-9946-4cfe893c46b8','Diego Cardenas',      'ed4e27bb-b4c0-400b-9c99-c3c696c44d67','Esther Mejia',             2022),
  ('0612180','f44419bb-a327-4679-8ae2-e4e6d418bfb0','ae64d6d5-8f2d-446d-851d-85851b78d787','84869bde-6410-46f0-bbe2-1315cd5c017b','Gloria Negrete-Mendoza','b1c4c42c-3f83-4953-a979-00d440164573','Arlene Perez',           2024),
  ('0612180','fb0825b0-f60e-4d50-b4eb-a57f3e60a8a4','d77ad373-7547-4977-ac10-06a4ba7db1f3','cbe120bb-0a1a-43ff-ad68-87406b499964','Tony Fuerte',         '8a514446-228f-4fe3-89fb-1559d33e0de0','Christine Saavedra',       2024),
  -- West Covina Unified
  ('0642000','0b2ed3ff-b492-4063-829c-3f61c132197a','edc9c125-2aa2-4fef-98b2-a364025aa009','a08c5e26-feee-4bbf-a60a-5de90eda74b5','Ben Kay',             '6e76b0be-ac38-4ad7-8473-ed468196d1c6','Rose Lopez',               2022),
  ('0642000','10047a98-d090-4183-8bff-8a1bee926b0f','69e3a4b0-3414-4400-9e60-a8c0bfa0a94a','ced90e57-de77-4a49-a9d8-5fa4ec9599c7','Darcy McNaboe',       'b8aa42f2-6bce-4531-a7c2-1b2398cf6ed1','Eileen Miranda Jimenez',   2022),
  ('0642000','4528def6-508b-41e6-83c4-ec3bc8ea57b6','542ca7b9-7eff-4015-9986-d9b31a17037b','af08db12-bace-48ce-b9e5-eaa0e3e2ffd8','Cynthia Moran',       '3aca5f48-3e5b-414c-9221-b4f08c493d67','Juanita Cruz',             2024),
  ('0642000','7646091b-eed4-4cfd-8e58-5457dc88a2c6','0135508c-8a66-4705-a57f-de3d70fcadcc','4d0397a4-6863-4e57-bfdf-510d3738630b','Joe Panganiban',      'fc2a669c-6e7f-43b5-8ba4-3fe6ea0ea2b6','Michael Flowers',          2024),
  ('0642000','8c0ef3e2-34f3-4558-bb53-177578938ae9','36e3f3e0-f5ac-43da-916c-55ba9dbd1188','8f362998-d0ae-490d-a3df-1d5a5de9243f','Lorenzo Munoz',       '9ca8d70e-84a3-40d9-a16a-17d3eab16479','Joe Magallanes',           2024);

CREATE TEMP TABLE _ca0143_district (geo_id text PRIMARY KEY, name text, board_url text, uncontested_2024 boolean) ON COMMIT DROP;
INSERT INTO _ca0143_district VALUES
  ('0610260','Culver City Unified',  'https://www.ccusd.org/apps/pages/index.jsp?uREC_ID=42334&type=d&pREC_ID=51428',   false),
  ('0641280','Walnut Valley Unified','https://www.wvusd.org/apps/pages/index.jsp?uREC_ID=54504&type=d&pREC_ID=2645128', true),
  ('0612210','El Segundo Unified',   'https://www.elsegundousd.net/page/board-members',                               true),
  ('0612180','El Rancho Unified',    'https://www.erusd.org/apps/pages/index.jsp?uREC_ID=4482985&type=d&pREC_ID=2748416', false),
  ('0642000','West Covina Unified',  'https://www.wcusd.org/board/members',                                           true);

-- New people (20). Reused rows (Ezidore, Lachman, Loredo, Perez, Redinger) are NOT in this list.
CREATE TEMP TABLE _ca0143_newpol (
  id uuid PRIMARY KEY, geo_id text, full_name text, first_name text, last_name text,
  preferred_name text, alternate_names text[]
) ON COMMIT DROP;
INSERT INTO _ca0143_newpol VALUES
  ('40df5b12-202f-4f06-917d-5b9883441046','0610260','Brian Guerrero',          'Brian',   'Guerrero',        NULL,    '{}'),
  ('86d016c2-eeca-4fab-bef6-d9a279e3e0fb','0610260','Lindsay Carlson',         'Lindsay', 'Carlson',         NULL,    '{}'),
  ('442cb09c-c590-4eb8-9718-00967d719e52','0641280','Helen M. Hall',           'Helen',   'Hall',            NULL,    '{"Helen Hall"}'),
  ('31472d29-6c13-42fa-b6a9-1cf53b71e824','0641280','Cynthia M. Ruiz',         'Cynthia', 'Ruiz',            'Cindy', '{"Cindy M. Ruiz","Cindy Ruiz"}'),
  ('be0686f9-51e1-45b4-a1dd-518e898492c5','0641280','Yi "Tony" Torng',         'Yi',      'Torng',           'Tony',  '{"Yi Tony Torng","Tony Torng"}'),
  ('d40a1ff0-1354-4095-89da-2e29e2bab349','0641280','Layla Abou-Taleb',        'Layla',   'Abou-Taleb',      NULL,    '{}'),
  ('4ecc7d76-22da-44a6-b2b9-bd029046368d','0612210','Meredith J. Beachly',     'Meredith','Beachly',         NULL,    '{}'),
  ('ec2a615b-7f6e-4e14-9fc2-2dfa8f0501c5','0612210','Frank C. Glynn',          'Frank',   'Glynn',           NULL,    '{"Frank Christopher Glynn","Frank Glynn"}'),
  ('b261afca-4cb9-4a59-9521-704307bf69d4','0612210','Tracey I. Miller-Zarneke','Tracey',  'Miller-Zarneke',  NULL,    '{}'),
  ('25ebeb0e-9985-45fc-a5b2-aa64993bbcf7','0612210','Heather E. Sutherland',   'Heather', 'Sutherland',      NULL,    '{"Heather Escalante Sutherland"}'),
  ('053ba101-06bc-4d39-a998-95eff7c977a8','0612210','Dieema A. Wheaton',       'Dieema',  'Wheaton',         NULL,    '{}'),
  ('a45c73fc-6bb1-4642-b5b4-56da17b21fc1','0612180','John Contreras',          'John',    'Contreras',       NULL,    '{}'),
  ('b85eeb90-e183-4ad4-ab05-663f3de31ba0','0612180','Hector LaFarga Jr.',      'Hector',  'LaFarga',         NULL,    '{"Hector Lafarga Jr."}'),
  ('ed4e27bb-b4c0-400b-9c99-c3c696c44d67','0612180','Esther Mejia',            'Esther',  'Mejia',           NULL,    '{}'),
  ('8a514446-228f-4fe3-89fb-1559d33e0de0','0612180','Christine Saavedra',      'Christine','Saavedra',       NULL,    '{}'),
  ('6e76b0be-ac38-4ad7-8473-ed468196d1c6','0642000','Rose Lopez',              'Rose',    'Lopez',           NULL,    '{}'),
  ('b8aa42f2-6bce-4531-a7c2-1b2398cf6ed1','0642000','Eileen Miranda Jimenez',  'Eileen',  'Miranda Jimenez', NULL,    '{"Eileen Miranda-Jimenez"}'),
  ('3aca5f48-3e5b-414c-9221-b4f08c493d67','0642000','Juanita Cruz',            'Juanita', 'Cruz',            NULL,    '{}'),
  ('fc2a669c-6e7f-43b5-8ba4-3fe6ea0ea2b6','0642000','Michael Flowers',         'Michael', 'Flowers',         NULL,    '{"Michael T. Flowers"}'),
  ('9ca8d70e-84a3-40d9-a16a-17d3eab16479','0642000','Joe Magallanes',          'Joe',     'Magallanes',      NULL,    '{}');

-- 2026 incumbents on the CA_0142 races to link (Ezidore is already linked).
CREATE TEMP TABLE _ca0143_link (race_id uuid, rc_full_name text, politician_id uuid) ON COMMIT DROP;
INSERT INTO _ca0143_link VALUES
  ('66659918-b0a8-401c-aa5d-9e654d16f3ba','Brian Guerrero',          '40df5b12-202f-4f06-917d-5b9883441046'),
  ('66659918-b0a8-401c-aa5d-9e654d16f3ba','Stephanie Loredo',        'a73ad2b6-dedd-4186-b451-cf8b7898c098'),
  ('6fe4d0ea-4125-4941-837c-05caaf299d53','Helen M. Hall',           '442cb09c-c590-4eb8-9718-00967d719e52'),
  ('6fe4d0ea-4125-4941-837c-05caaf299d53','Cindy M. Ruiz',           '31472d29-6c13-42fa-b6a9-1cf53b71e824'),
  ('6fe4d0ea-4125-4941-837c-05caaf299d53','Yi Tony Torng',           'be0686f9-51e1-45b4-a1dd-518e898492c5'),
  ('2ee6404a-3dda-48be-af41-fab3de9def2f','Meredith J. Beachly',     '4ecc7d76-22da-44a6-b2b9-bd029046368d'),
  ('2ee6404a-3dda-48be-af41-fab3de9def2f','Frank Christopher Glynn', 'ec2a615b-7f6e-4e14-9fc2-2dfa8f0501c5'),
  ('2ee6404a-3dda-48be-af41-fab3de9def2f','Tracey I. Miller-Zarneke','b261afca-4cb9-4a59-9521-704307bf69d4'),
  ('f2b1ef44-c7f0-4248-afa5-1cb355477430','John Contreras',          'a45c73fc-6bb1-4642-b5b4-56da17b21fc1'),
  ('f2b1ef44-c7f0-4248-afa5-1cb355477430','Hector Lafarga Jr.',      'b85eeb90-e183-4ad4-ab05-663f3de31ba0'),
  ('f2b1ef44-c7f0-4248-afa5-1cb355477430','Esther Mejia',            'ed4e27bb-b4c0-400b-9c99-c3c696c44d67'),
  ('28c94845-9c71-449f-9423-cab41f552803','Rose Lopez',              '6e76b0be-ac38-4ad7-8473-ed468196d1c6'),
  ('28c94845-9c71-449f-9423-cab41f552803','Eileen Miranda Jimenez',  'b8aa42f2-6bce-4531-a7c2-1b2398cf6ed1');

-- ─── Pre-flight: derive-then-verify every identifier ─────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every office is a 'Board Member' seat on its district's whole-district SCHOOL/G5420 row
  SELECT count(*) INTO v_n FROM _ca0143_seat s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = s.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND o.title = 'Board Member';
  IF v_n <> 25 THEN RAISE EXCEPTION 'PRE: % of 25 seat offices resolve to their SCHOOL/G5420 district', v_n; END IF;

  -- each district has exactly these 5 offices, no more
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0143_district);
  IF v_n <> 25 THEN RAISE EXCEPTION 'PRE: the 5 districts hold % offices, expected 25', v_n; END IF;

  -- each stale term is (id, office, politician, name) as recorded, and is open or closed by THIS file
  SELECT count(*) INTO v_n FROM _ca0143_seat s
    JOIN essentials.office_terms t ON t.id = s.stale_term_id AND t.office_id = s.office_id AND t.politician_id = s.stale_pol_id
    JOIN essentials.politicians p ON p.id = s.stale_pol_id AND p.full_name = s.stale_name
   WHERE t.term_start IS NULL
     AND (t.term_end IS NULL OR (t.term_end = make_date(s.elected_year, 12, 1) - 1 AND t.source LIKE '%| closed CA_0143%'));
  IF v_n <> 25 THEN RAISE EXCEPTION 'PRE: % of 25 stale terms match the recorded (id, office, politician, name)', v_n; END IF;

  -- a closed stale row must hold no stance data (nothing to orphan)
  SELECT count(*) INTO v_n FROM inform.politician_answers a WHERE a.politician_id IN (SELECT stale_pol_id FROM _ca0143_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % stance answers -- retire them first', v_n; END IF;

  -- no stale holder sits on any other office (closing this term must not unseat something else)
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT stale_pol_id FROM _ca0143_seat)
     AND t.id NOT IN (SELECT stale_term_id FROM _ca0143_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders hold % other office_terms', v_n; END IF;

  -- reused rows are the people recorded (a73ad2b6 is 'Loredo' before, 'Stephanie Loredo' after)
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE (p.id = '38aa3e5d-2824-4810-af6d-ad4d8f2bd359' AND p.full_name = 'Triston Ezidore')
      OR (p.id = '2648c09b-747d-4a97-a949-26b9a99b6b3f' AND p.full_name = 'Andrew Lachman')
      OR (p.id = 'a73ad2b6-dedd-4186-b451-cf8b7898c098' AND p.full_name IN ('Loredo','Stephanie Loredo') AND p.last_name = 'Loredo')
      OR (p.id = 'b1c4c42c-3f83-4953-a979-00d440164573' AND p.full_name = 'Arlene Perez')
      OR (p.id = 'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1' AND p.full_name = 'Larry Redinger');
  IF v_n <> 5 THEN RAISE EXCEPTION 'PRE: % of 5 reused politician rows match', v_n; END IF;

  -- the netfile committees behind the four reused rows are the right boards
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system = 'la_county_netfile' AND ps.research_status = 'confirmed'
     AND ((ps.essentials_politician_id = '38aa3e5d-2824-4810-af6d-ad4d8f2bd359' AND ps.notes ILIKE '%Ezidore for Culver City Unified%')
       OR (ps.essentials_politician_id = '2648c09b-747d-4a97-a949-26b9a99b6b3f' AND ps.notes ILIKE '%Lachman for Culver City Unified%')
       OR (ps.essentials_politician_id = 'a73ad2b6-dedd-4186-b451-cf8b7898c098' AND ps.notes ILIKE '%LOREDO FOR CULVER CITY UNIFIED%')
       OR (ps.essentials_politician_id = 'b1c4c42c-3f83-4953-a979-00d440164573' AND ps.notes ILIKE '%Arlene Perez for El Rancho Unified%'));
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 netfile committees confirm the reused rows', v_n; END IF;

  -- the reused rows hold no other term (so seating them adds, never moves, an office) -- except
  -- Redinger's §C Charter Oak term, which this file deletes
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN ('38aa3e5d-2824-4810-af6d-ad4d8f2bd359','2648c09b-747d-4a97-a949-26b9a99b6b3f',
                             'a73ad2b6-dedd-4186-b451-cf8b7898c098','b1c4c42c-3f83-4953-a979-00d440164573',
                             'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1')
     AND t.id <> '7e807116-f881-4ee6-a600-aac3000b6c26'
     AND t.source NOT LIKE 'CA_0143:%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: reused rows hold % unexpected office_terms', v_n; END IF;

  -- §C: Redinger's Charter Oak term is exactly the recorded row, or already gone
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.id = '7e807116-f881-4ee6-a600-aac3000b6c26'
     AND NOT (t.office_id = 'dd55b530-73ea-4657-aa27-fa5d414d1fec' AND t.politician_id = 'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1'
              AND t.term_start IS NULL AND t.term_end IS NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: term 7e807116 is not the recorded Redinger/Charter Oak row'; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id = 'dd55b530-73ea-4657-aa27-fa5d414d1fec' AND d.geo_id = '0608190' AND d.district_type = 'SCHOOL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: office dd55b530 is not a Charter Oak Unified seat'; END IF;

  -- every race to link is the CA_0142 race of one of these districts, bound to one of these seats
  SELECT count(DISTINCT r.id) INTO v_n FROM essentials.races r
   WHERE r.id IN (SELECT race_id FROM _ca0143_link)
     AND r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND r.office_id IN (SELECT office_id FROM _ca0143_seat);
  IF v_n <> 5 THEN RAISE EXCEPTION 'PRE: % of 5 CA_0142 races resolve to these seats', v_n; END IF;
END $$;

-- ─── 1. New politician rows (20) ─────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, preferred_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.alternate_names,
       true, false, true, NULL, d.board_url, 'CA_0143_la_unified_board_rosters_batch1'
  FROM _ca0143_newpol n JOIN _ca0143_district d ON d.geo_id = n.geo_id
ON CONFLICT (id) DO NOTHING;

-- ─── 2. Reused rows: seated -> incumbent, no party, sourced to the board page ────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = true, party = NULL, data_source = COALESCE(p.data_source, d.board_url)
  FROM _ca0143_seat s JOIN _ca0143_district d ON d.geo_id = s.geo_id
 WHERE p.id = s.new_pol_id
   AND p.id IN ('38aa3e5d-2824-4810-af6d-ad4d8f2bd359','2648c09b-747d-4a97-a949-26b9a99b6b3f',
                'a73ad2b6-dedd-4186-b451-cf8b7898c098','b1c4c42c-3f83-4953-a979-00d440164573')
   AND (p.is_incumbent IS DISTINCT FROM true OR p.party IS NOT NULL OR p.data_source IS NULL);

-- 'Loredo' -> Stephanie Loredo (only while the name is still the unedited import)
UPDATE essentials.politicians
   SET full_name = 'Stephanie Loredo', first_name = 'Stephanie'
 WHERE id = 'a73ad2b6-dedd-4186-b451-cf8b7898c098' AND full_name = 'Loredo' AND NOT full_name_manual_override;

-- Redinger: repoint his source off Charter Oak, record ballot names, drop the stored party
UPDATE essentials.politicians
   SET data_source = 'https://www.wvusd.org/apps/pages/index.jsp?uREC_ID=54504&type=d&pREC_ID=2645128',
       party = NULL,
       alternate_names = ARRAY(SELECT DISTINCT unnest(alternate_names || '{"Larry L. Redinger","Larry Lee Redinger"}'::text[]))
 WHERE id = 'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1'
   AND (data_source = 'https://empowered.vote/school-district/charter_oak_unified' OR party IS NOT NULL
        OR NOT alternate_names @> '{"Larry L. Redinger","Larry Lee Redinger"}');

-- ─── 3. §C: delete Redinger's wrong-seat Charter Oak term ────────────────────────────────────────
DELETE FROM essentials.office_terms
 WHERE id = '7e807116-f881-4ee6-a600-aac3000b6c26'
   AND office_id = 'dd55b530-73ea-4657-aa27-fa5d414d1fec'
   AND politician_id = 'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1';

-- ─── 4. Close the 25 stale terms (operator decision §B) ──────────────────────────────────────────
UPDATE essentials.office_terms t
   SET term_end  = make_date(s.elected_year, 12, 1) - 1,
       how_ended = 'unknown',
       source    = t.source || ' | closed CA_0143 (2026-09-22): holder is not on the verified current '
                   || d.name || ' board (' || d.board_url || '); actual last day NOT researched -- '
                   || 'term_end is the day before the successor on this generic seat took office'
  FROM _ca0143_seat s JOIN _ca0143_district d ON d.geo_id = s.geo_id
 WHERE t.id = s.stale_term_id
   AND t.term_end IS NULL;

-- ─── 5. Seat the 25 current members ──────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT s.office_id, s.new_pol_id, make_date(s.elected_year, 12, 1), 'month', 'elected',
       'CA_0143: ' || d.name || ' board roster, ' || d.board_url || ' (read 2026-09-22); current term won Nov '
       || s.elected_year || ' per LA County RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id='
       || CASE s.elected_year WHEN 2022 THEN '4300' ELSE '4324' END
       || CASE WHEN s.elected_year = 2024 AND d.uncontested_2024
               THEN ' (uncontested; appointed in lieu of election, Elec. Code 10515)' ELSE '' END
       || '; term begins December ' || s.elected_year || ' (Ed. Code 5017), month precision'
  FROM _ca0143_seat s JOIN _ca0143_district d ON d.geo_id = s.geo_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = s.office_id AND t.politician_id = s.new_pol_id
                      AND t.term_start = make_date(s.elected_year, 12, 1));

-- ─── 6. Stale holders are no longer incumbents (only where they hold no current seat) ────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.id IN (SELECT stale_pol_id FROM _ca0143_seat)
   AND p.is_incumbent
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── 7. Link the 2026 incumbents CA_0142 left unlinked ───────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET politician_id = l.politician_id
  FROM _ca0143_link l
 WHERE rc.race_id = l.race_id
   AND lower(rc.full_name) = lower(l.rc_full_name)
   AND rc.is_incumbent
   AND rc.politician_id IS NULL;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_held int; v_bad int;
BEGIN
  -- every seat's current holder is exactly the intended member
  SELECT count(*) INTO v_n FROM _ca0143_seat s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id AND och.politician_id = s.new_pol_id;
  IF v_n <> 25 THEN RAISE EXCEPTION 'POST: % of 25 seats resolve to the intended current member', v_n; END IF;

  -- per district: 5 offices, 5 distinct active incumbent holders, nothing flagged vacant
  SELECT count(*) INTO v_bad FROM (
    SELECT d.geo_id
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
     WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0143_district)
     GROUP BY d.geo_id
    HAVING count(DISTINCT o.id) <> 5 OR count(DISTINCT p.id) <> 5 OR bool_or(o.is_vacant)) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) do not show 5 active incumbent holders', v_bad; END IF;

  -- seated people: no stored party; each holds exactly one current seat
  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT new_pol_id FROM _ca0143_seat) AND p.party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) carry a stored party', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     WHERE och.politician_id IN (SELECT new_pol_id FROM _ca0143_seat)
     GROUP BY 1 HAVING count(*) <> 1) x;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) hold <> 1 current seat', v_bad; END IF;

  -- new terms: month precision, December of the election year, elected, open-ended
  SELECT count(*) INTO v_n FROM _ca0143_seat s JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.politician_id = s.new_pol_id
   WHERE t.term_start = make_date(s.elected_year, 12, 1) AND t.start_precision = 'month'
     AND t.how_started = 'elected' AND t.term_end IS NULL AND t.source LIKE 'CA_0143:%';
  IF v_n <> 25 THEN RAISE EXCEPTION 'POST: % of 25 new terms have the expected shape', v_n; END IF;

  -- stale terms: closed the day before the successor, how_ended unknown, annotated
  SELECT count(*) INTO v_n FROM _ca0143_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE t.term_end = make_date(s.elected_year, 12, 1) - 1 AND t.how_ended = 'unknown'
     AND t.source LIKE '%| closed CA_0143%';
  IF v_n <> 25 THEN RAISE EXCEPTION 'POST: % of 25 stale terms closed as intended', v_n; END IF;

  -- stale people: not current anywhere, not incumbents
  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT stale_pol_id FROM _ca0143_seat)
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % stale holder(s) still current or incumbent', v_bad; END IF;

  -- §C: the Charter Oak row is gone; Charter Oak still has active holders (no DEAD_GEOGRAPHY)
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE id = '7e807116-f881-4ee6-a600-aac3000b6c26';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: Redinger Charter Oak term still present'; END IF;
  SELECT count(DISTINCT p.id) INTO v_held
    FROM essentials.districts d JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
   WHERE d.geo_id = '0608190' AND d.district_type = 'SCHOOL';
  IF v_held = 0 THEN RAISE EXCEPTION 'POST: Charter Oak Unified left with no active holder'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
   WHERE och.politician_id = 'fca9a696-f3c7-4673-a9ec-4eb05ba74aa1' AND och.office_id = 'c7e429be-2ca9-49e2-a3c0-152de408053d';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Redinger is not the current WVUSD holder'; END IF;

  -- 2026 races: all 14 RR/CC incumbents on the 5 races (13 linked here + Ezidore from CA_0142) are
  -- linked to a current holder of that same district, and none is left unlinked
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices ro ON ro.id = r.office_id
    JOIN essentials.office_current_holder och ON och.politician_id = rc.politician_id
    JOIN essentials.offices ho ON ho.id = och.office_id AND ho.district_id = ro.district_id
   WHERE r.id IN (SELECT race_id FROM _ca0143_link) AND rc.is_incumbent;
  IF v_n <> 14 THEN RAISE EXCEPTION 'POST: % of 14 incumbent candidates linked to a current holder of their district', v_n; END IF;
  SELECT count(*) INTO v_bad FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM _ca0143_link) AND rc.is_incumbent AND rc.politician_id IS NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % incumbent candidate(s) on these races still unlinked', v_bad; END IF;

  -- END TO END: an interior point of each district's polygon returns 5 active incumbent holders
  SELECT count(*) INTO v_bad FROM _ca0143_district x
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

  RAISE NOTICE 'CA_0143 applied: 25 seats re-seated across 5 LA unified boards; 25 stale terms closed + 1 wrong-seat term deleted; 20 politicians created, 5 reused; 13 candidates linked';
END $$;

COMMIT;
