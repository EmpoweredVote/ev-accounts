-- CA_0148_la_unified_board_rosters_batch4a.sql
-- Replace the STALE sitting members of three more LA-County AT-LARGE unified school boards with the
-- verified current boards, in essentials.office_terms (the only occupancy source; ADR 0002).
-- Batch 4a of the roster refresh (CA_0143, CA_0145, CA_0147); same method, same operator decisions.
--
--   Arcadia Unified 0602970    Redondo Beach Unified 0600032    Santa Monica-Malibu Unified 0635700
--
-- All three elect AT LARGE: the LA County RR/CC precinct layer (Political_Boundaries/MapServer/34)
-- carries only DIV_USD 0 for their USD codes (28, 43, 34), i.e. no trustee areas. So this is a roster
-- refresh on the existing whole-district seats, like batches 1-3. (The trustee-area districts of this
-- slice -- Compton, Glendale, Inglewood, Long Beach, Pasadena -- are batch 4b.)
--
-- No migration runner exists; this file records SQL applied by hand via
--   npx tsx scripts/_apply-file.ts <abs path>/backend/migrations/CA_0148_la_unified_board_rosters_batch4a.sql
-- (pure DML -> DATABASE_URL is fine).
--
-- ---------------------------------------------------------------------------------------------------
-- A. THE DEFECT -- as CA_0143 §A. 15 generic 'Board Member' seats carry migration-1459 backfill terms
-- (NULL/NULL, 'unknown'). 12 holders are not on the current board; 3 are (§C). Arcadia has 4 seats for a
-- 5-member board and Santa Monica-Malibu 6 for 7 (§D).
--
-- B. STALE TERMS -- operator decision (Chris Andrews, 2026-09-22), as CA_0143 §B: term_end = day before
-- the successor on the same generic seat took office (modelling consequence), how_ended 'unknown',
-- is_incumbent = false, is_active left alone.
--
-- C. THREE STALE HOLDERS ARE REAL AND STILL SEATED (Santa Monica-Malibu) -- kept, terms untouched
-- (CA_0145 §C / 1546 precedent); only their stored party is cleared:
--   Maria Leon-Vazquez (dc78ce32), Jon Kean (063fd6f1) -- smmusd.org "Term Expires 12/28"; RR/CC Nov 2024
--     results (4324) list both among the 3 winners (26,454 and 26,564 votes).
--   Laurie Lieberman (0952f897) -- smmusd.org "Terms Expires 12/26"; RR/CC Nov 2022 (4300) top of 4 winners.
--
-- D. MISSING SEATS -- operator decision (2026-09-22): add seats to match the board. One seat is added to
-- Arcadia (b4c96951, a copy of 4ae07329) and one to Santa Monica-Malibu (ebd23662, a copy of 00676630).
-- Neither has a predecessor. No race references any of these offices.
--
-- ---------------------------------------------------------------------------------------------------
-- E. THE CURRENT BOARDS -- each district's own board page, fetched and read 2026-09-22
-- ---------------------------------------------------------------------------------------------------
--   Arcadia       ausd.net/apps/pages/Board (read in a browser): "2026-27 ARCADIA UNIFIED BOARD OF
--                 EDUCATION" -- Shirley Yee, Jennifer Vargo, Raymond Cheung, Leigh Chavez, Uyen Wong.
--                 Arcadia votes with the statewide PRIMARY. RR/CC candidate lists: March 5 2024 (4316)
--                 = Cheung (E), Vargo, Yee (E) for 3 seats; June 2 2026 (4338) = Chavez (E), Wong for 2
--                 seats. Both uncontested (no result line), so appointed in lieu of election (Elec. Code
--                 §10515, treated as elected). The Arcadia Chamber of Commerce (2026-07-23) reports the
--                 district "welcomed Uyen Wong" and that Chavez "begins her third four-year term"; Fenton
--                 Eng (a June 2022 winner) was honoured at his final meeting in June 2026. No source
--                 gives the month a primary-cycle Arcadia term begins, so start_precision is 'year'.
--   Redondo Beach rbusd.org/apps/pages/index.jsp?uREC_ID=853112&type=d&pREC_ID=2162700
--                 Byung Cho "Elected to the Board March 2023 / Current Term Expires March 2027"; Raymur
--                 Flinn "March 2019, March 2023 / March 2027"; Hanh Archer "March 2025 / March 2029";
--                 Dan Elder and Rachel Silverman Nemeth "March 2021, March 2025 / March 2029". Redondo
--                 Beach runs its own (city) elections, so RR/CC has no record; the district page is the
--                 source. start = March of the election year, precision 'month'.
--   Santa Monica- smmusd.org/board-of-education/board-members (read in a browser)
--   Malibu        Kean, Leon-Vazquez, Smith "Term Expires 12/28"; Lieberman, Mignano, Rouse,
--                 Tahvildaran-Jesswein "12/26". RR/CC results: Nov 2022 (4300) 4 seats -- Lieberman,
--                 Tahvildaran-Jesswein, Rouse, Mignano; Nov 2024 (4324) 3 seats -- Smith, Kean,
--                 Leon-Vazquez. start = December of the election year, precision 'month' (CA_0143 §D).
--
-- F. PEOPLE -- 14 new politician rows (party NULL, is_active/is_incumbent true, data_source = the board
-- page); no reusable NetFile row exists for any of them; 3 kept.
--
-- 🔴 NOT DONE HERE, AND OWED: Santa Monica-Malibu has FOUR seats on the Nov 3 2026 ballot (the 12/26
-- terms) but no 2026 race exists for it -- SMMUSD candidates file with the City of Santa Monica, so they
-- are absent from the RR/CC candidate list CA_0142 was built from. Also: stale holders keep party
-- 'Nonpartisan' and is_active true; titles stay 'Board Member'.
--
-- ROLLBACK: DELETE the 14 office_terms rows whose source starts 'CA_0148:'; DELETE offices b4c96951 and
-- ebd23662; for the 12 closed stale rows (source contains '| closed CA_0148') SET term_end = NULL,
-- how_ended = NULL and strip the note; set is_incumbent = true on the 12 stale politicians; DELETE the 14
-- new politicians. The 3 kept rows had party 'Nonpartisan'.
--
-- IDEMPOTENT: office inserts on id; stale closes on term_end IS NULL; new terms on (office, politician,
-- term_start); politicians on id.

BEGIN;

-- action: 'replace' | 'keep' | 'add' (template_office = the seat an added seat copies)
CREATE TEMP TABLE _ca0148_seat (
  geo_id text, office_id uuid, stale_term_id uuid, stale_pol_id uuid, stale_name text,
  new_pol_id uuid, new_name text, term_start date, start_precision text, how_started text,
  action text, template_office uuid, evidence text
) ON COMMIT DROP;
INSERT INTO _ca0148_seat VALUES
  -- Arcadia Unified (4 existing seats + 1 added)
  ('0602970','4ae07329-dd5d-4002-ab7c-0ecd61219cd1','5d2d40af-76b9-4694-904e-aebb53c29016','29d411a9-c672-4549-8c2e-a9b276cf8537','Ed Chung',
   '59f32fc4-ee40-45eb-973b-584819aebef7','Raymond Cheung','2024-01-01','year','elected','replace',NULL,
   'current term from the March 5 2024 election: RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id=4316 has 3 candidates for 3 seats (uncontested; appointed in lieu of election, Elec. Code 10515); the month the term began is not sourced, so precision year'),
  ('0602970','53e6bd33-e92c-4d09-bb6b-6ffd28b65f6f','ea635ff3-ca08-4569-9344-09837bc5dd93','1a0a34d3-0203-4f5a-a4f0-2e4f27034b48','Sho Tay',
   'e941049b-f855-491e-aa7a-3d37bc781138','Jennifer Vargo','2024-01-01','year','elected','replace',NULL,
   'current term from the March 5 2024 election: RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id=4316 has 3 candidates for 3 seats (uncontested; appointed in lieu of election, Elec. Code 10515); the month the term began is not sourced, so precision year'),
  ('0602970','84ad8de7-8128-43f7-97fe-ce93175210db','71949f31-eba1-42ce-b10c-d21e82757050','bf906462-f937-4d8c-b452-6555e95b4bac','Tim Tran',
   '3a693b5e-46b9-4727-bab0-24e6ff4a96b3','Shirley Yee','2024-01-01','year','elected','replace',NULL,
   'current term from the March 5 2024 election: RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id=4316 has 3 candidates for 3 seats (uncontested; appointed in lieu of election, Elec. Code 10515); the month the term began is not sourced, so precision year'),
  ('0602970','a837645a-e737-4f4c-b7da-a7fe73525694','03aecac3-2727-4d91-80fc-be986f4f6304','be1c71f8-d5d9-416e-a713-35ccda7a5743','Elizabeth Mensah',
   'bd7b47db-2ea9-4005-a135-82e09eeb76db','Leigh Chavez','2026-01-01','year','elected','replace',NULL,
   'current term from the June 2 2026 election: RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id=4338 has 2 candidates for 2 seats (uncontested; appointed in lieu of election, Elec. Code 10515); Arcadia Chamber of Commerce 2026-07-23: she "begins her third four-year term"; the month the term began is not sourced, so precision year'),
  ('0602970','b4c96951-d68f-4970-a126-ded778437deb',NULL,NULL,NULL,
   'bdad532f-8f5a-41de-8b36-f4788aa451be','Uyen Wong','2026-01-01','year','elected','add','4ae07329-dd5d-4002-ab7c-0ecd61219cd1',
   'current term from the June 2 2026 election: RR/CC candidate list lavote.gov/Apps/CandidateList/Index?id=4338 has 2 candidates for 2 seats (uncontested; appointed in lieu of election, Elec. Code 10515); Arcadia Chamber of Commerce 2026-07-23: the district "welcomed Uyen Wong" (succeeding Fenton Eng, whose final meeting was June 2026); the month the term began is not sourced, so precision year'),
  -- Redondo Beach Unified
  ('0600032','11b0edae-1bb8-4675-bf57-7ff70f485921','2a6e4aa0-eb76-48e1-944d-24269d1a68f4','5977fd63-62f6-471d-b379-046423e7fc75','Mark Schilit',
   'f9fb5725-733a-4748-9945-72f6b3827e90','Byung Cho','2023-03-01','month','elected','replace',NULL,
   'district page: "Elected to the Board March 2023 / Current Term Expires March 2027" (Redondo Beach city election); month precision'),
  ('0600032','5dfb2199-213c-4bb4-9fa2-c7d416b7ec0a','ad180d4e-744e-4c3c-ae66-aa210fe945c3','00c36fe6-86e1-4bd8-bfd7-417739ce553e','Rosie Ferree',
   'b8805582-53b8-4143-88ee-620f00ca989f','Raymur Flinn','2023-03-01','month','elected','replace',NULL,
   'district page: "Elected to the Board March 2019 / Elected to the Board March 2023 / Current Term Expires March 2027" (Redondo Beach city election); current term from March 2023, month precision'),
  ('0600032','96b6639d-1b72-4f86-8447-8ab0c1a47e53','67bb8185-6c67-47a1-9b97-ec89f3ae9d80','bbff7247-f129-41ef-8d39-393b3c973163','Naomi Kim',
   '2041c517-87c7-49c1-9ba4-d4fa75621728','Hanh Archer','2025-03-01','month','elected','replace',NULL,
   'district page: "Elected to the Board March 2025 / Current Term Expires March 2029" (Redondo Beach city election); month precision'),
  ('0600032','9f284e0d-e86b-4aa0-bd7d-3c82bc09bbd7','6cf2e59e-4b19-4aa6-b007-e560e163bae0','f5925180-4bec-4ab9-9dae-068ad3c8b657','Maggie McLaughlin',
   '190879aa-e6ce-4fba-9e12-0ee61093132d','Dan Elder','2025-03-01','month','elected','replace',NULL,
   'district page: "Elected to the Board March 2021 / Elected to the Board March 2025 / Current Term Expires March 2029" (Redondo Beach city election); current term from March 2025, month precision'),
  ('0600032','e420988a-7b15-4a7f-bfbd-99135faad785','d4c12438-f5bf-409d-bc84-5d2fd9ae84e1','52e2ca7c-cf20-490e-97dd-57741a95fb52','Eric Sheridan',
   '27dd8106-00d6-412e-bab1-90547d03df09','Rachel Silverman Nemeth','2025-03-01','month','elected','replace',NULL,
   'district page: "Elected to the Board March 2021 / Elected to the Board March 2025 / Current Term Expires March 2029" (Redondo Beach city election); current term from March 2025, month precision'),
  -- Santa Monica-Malibu Unified (6 existing seats + 1 added)
  ('0635700','00676630-2e51-4cdb-bf70-9c6f3dcb7537','a13db953-0d19-42ca-a14a-cd036370a697','dc78ce32-d1d6-40f6-a200-dd8fb5a13f7d','Maria Leon-Vazquez',
   'dc78ce32-d1d6-40f6-a200-dd8fb5a13f7d','Maria Leon-Vazquez',NULL,NULL,NULL,'keep',NULL,NULL),
  ('0635700','58511f9f-965a-4052-b1d6-bd84c51e624d','761a8c65-2d3f-4224-a481-c3b1903cdea4','636c3d78-e230-4c1f-b267-921c4775b2c4','Alicia Brodkin',
   '665372e8-49fe-4c6e-9930-fca6ed3430f0','Alicia Mignano','2022-12-01','month','elected','replace',NULL,
   'current term won Nov 2022 per LA County RR/CC results (results.lavote.gov/text-results/4300, 4 seats); district page "Term Expires 12/26"; term begins December 2022 (Ed. Code 5017), month precision'),
  ('0635700','7319d4dd-9f45-488c-aa5b-a3ad3419a300','9ced8cb9-536f-42de-abb0-53818c38e498','063fd6f1-42f0-47dc-aa7d-7feac385c495','Jon Kean',
   '063fd6f1-42f0-47dc-aa7d-7feac385c495','Jon Kean',NULL,NULL,NULL,'keep',NULL,NULL),
  ('0635700','7464a40f-1d25-469e-b6e7-dc2ccf722f76','65057f69-58a3-4ec7-bb3b-3849d3025038','0952f897-7414-4ad3-af88-022de9e4971c','Laurie Lieberman',
   '0952f897-7414-4ad3-af88-022de9e4971c','Laurie Lieberman',NULL,NULL,NULL,'keep',NULL,NULL),
  ('0635700','9c961024-0c4b-4864-b4f8-f2a77258fe40','c7dca23e-2187-407c-8431-ac253b19f77f','592a2ac4-686f-47d5-8668-269e21ad1924','Craig Foster',
   '3cf22d9d-f6fd-404c-b6ba-a1e4b7fb830d','Stacy Rouse','2022-12-01','month','elected','replace',NULL,
   'current term won Nov 2022 per LA County RR/CC results (results.lavote.gov/text-results/4300, 4 seats); district page "Term Expires 12/26"; term begins December 2022 (Ed. Code 5017), month precision'),
  ('0635700','d1e51625-36c9-4f39-9df0-081774ee00ae','8215e3f1-25be-4bd2-9072-7c8ad6cc019f','fdc4de72-cd43-4ff8-b13e-28e1c419fe83','Roy Rifkin',
   '7b1d8eb0-a823-449c-908b-fa103960d902','Richard Tahvildaran-Jesswein','2022-12-01','month','elected','replace',NULL,
   'current term won Nov 2022 per LA County RR/CC results (results.lavote.gov/text-results/4300, 4 seats); district page "Term Expires 12/26"; term begins December 2022 (Ed. Code 5017), month precision'),
  ('0635700','ebd23662-e010-44d8-8c61-0d0c66349128',NULL,NULL,NULL,
   'f19575de-a7df-4ca5-9b7e-31c8b2522a97','Jennifer Smith','2024-12-01','month','elected','add','00676630-2e51-4cdb-bf70-9c6f3dcb7537',
   'current term won Nov 2024 per LA County RR/CC results (results.lavote.gov/text-results/4324, 3 seats); district page "Term Expires 12/28"; term begins December 2024 (Ed. Code 5017), month precision');

CREATE TEMP TABLE _ca0148_district (geo_id text PRIMARY KEY, name text, board_url text, seats int) ON COMMIT DROP;
INSERT INTO _ca0148_district VALUES
  ('0602970','Arcadia Unified',            'https://www.ausd.net/apps/pages/Board', 5),
  ('0600032','Redondo Beach Unified',      'https://www.rbusd.org/apps/pages/index.jsp?uREC_ID=853112&type=d&pREC_ID=2162700', 5),
  ('0635700','Santa Monica-Malibu Unified','https://www.smmusd.org/board-of-education/board-members', 7);

CREATE TEMP TABLE _ca0148_newpol (
  id uuid PRIMARY KEY, geo_id text, full_name text, first_name text, last_name text, alternate_names text[]
) ON COMMIT DROP;
INSERT INTO _ca0148_newpol VALUES
  ('59f32fc4-ee40-45eb-973b-584819aebef7','0602970','Raymond Cheung',              'Raymond','Cheung',              '{"Raymond K. Cheung"}'),
  ('e941049b-f855-491e-aa7a-3d37bc781138','0602970','Jennifer Vargo',              'Jennifer','Vargo',              '{}'),
  ('3a693b5e-46b9-4727-bab0-24e6ff4a96b3','0602970','Shirley Yee',                 'Shirley','Yee',                 '{}'),
  ('bd7b47db-2ea9-4005-a135-82e09eeb76db','0602970','Leigh Chavez',                'Leigh',  'Chavez',              '{}'),
  ('bdad532f-8f5a-41de-8b36-f4788aa451be','0602970','Uyen Wong',                   'Uyen',   'Wong',                '{"Uyen H. Wong"}'),
  ('f9fb5725-733a-4748-9945-72f6b3827e90','0600032','Byung Cho',                   'Byung',  'Cho',                 '{}'),
  ('b8805582-53b8-4143-88ee-620f00ca989f','0600032','Raymur Flinn',                'Raymur', 'Flinn',               '{}'),
  ('2041c517-87c7-49c1-9ba4-d4fa75621728','0600032','Hanh Archer',                 'Hanh',   'Archer',              '{}'),
  ('190879aa-e6ce-4fba-9e12-0ee61093132d','0600032','Dan Elder',                   'Dan',    'Elder',               '{}'),
  ('27dd8106-00d6-412e-bab1-90547d03df09','0600032','Rachel Silverman Nemeth',     'Rachel', 'Silverman Nemeth',    '{}'),
  ('665372e8-49fe-4c6e-9930-fca6ed3430f0','0635700','Alicia Mignano',              'Alicia', 'Mignano',             '{}'),
  ('3cf22d9d-f6fd-404c-b6ba-a1e4b7fb830d','0635700','Stacy Rouse',                 'Stacy',  'Rouse',               '{}'),
  ('7b1d8eb0-a823-449c-908b-fa103960d902','0635700','Richard Tahvildaran-Jesswein','Richard','Tahvildaran-Jesswein','{}'),
  ('f19575de-a7df-4ca5-9b7e-31c8b2522a97','0635700','Jennifer Smith',              'Jennifer','Smith',              '{}');

-- ─── Pre-flight: derive-then-verify every identifier ─────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0148_seat s
    JOIN essentials.offices o ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.action <> 'add' AND d.geo_id = s.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
     AND o.title = 'Board Member';
  IF v_n <> 15 THEN RAISE EXCEPTION 'PRE: % of 15 existing seat offices resolve to their SCHOOL/G5420 district', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND d.geo_id IN (SELECT geo_id FROM _ca0148_district)
     AND o.id NOT IN (SELECT office_id FROM _ca0148_seat WHERE action = 'add');
  IF v_n <> 15 THEN RAISE EXCEPTION 'PRE: the 3 districts hold % pre-existing offices, expected 15', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0148_seat s
    JOIN essentials.office_terms t ON t.id = s.stale_term_id AND t.office_id = s.office_id AND t.politician_id = s.stale_pol_id
    JOIN essentials.politicians p ON p.id = s.stale_pol_id AND p.full_name = s.stale_name
   WHERE s.action <> 'add' AND t.term_start IS NULL
     AND (t.term_end IS NULL
          OR (s.action = 'replace' AND t.term_end = s.term_start - 1 AND t.source LIKE '%| closed CA_0148%'));
  IF v_n <> 15 THEN RAISE EXCEPTION 'PRE: % of 15 existing terms match the recorded (id, office, politician, name)', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT stale_pol_id FROM _ca0148_seat WHERE action = 'replace');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale holders carry % stance answers -- retire them first', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.politician_id IN (SELECT stale_pol_id FROM _ca0148_seat WHERE stale_pol_id IS NOT NULL)
     AND t.id NOT IN (SELECT stale_term_id FROM _ca0148_seat WHERE stale_term_id IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: stale/kept holders hold % other office_terms', v_n; END IF;

  -- no race is bound to any seat touched here (so an added seat changes no race binding)
  SELECT count(*) INTO v_n FROM essentials.races r WHERE r.office_id IN (SELECT office_id FROM _ca0148_seat);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race(s) reference these seats -- review before re-seating', v_n; END IF;

  -- the two templates are seats of their districts
  SELECT count(*) INTO v_n FROM _ca0148_seat s JOIN essentials.offices o ON o.id = s.template_office
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.action = 'add' AND d.geo_id = s.geo_id AND o.title = 'Board Member';
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 template seats found', v_n; END IF;
END $$;

-- ─── 1. Added seats (copies of a sibling seat) ───────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
   faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT s.office_id, o.chamber_id, o.district_id, o.title, o.representing_state, o.representing_city,
       o.description, o.seats, o.normalized_position_name, o.partisan_type, o.salary,
       o.is_appointed_position, false, NULL, o.faces_retention_vote, o.role_canonical, o.voting_powers,
       o.representation_note
  FROM _ca0148_seat s JOIN essentials.offices o ON o.id = s.template_office
 WHERE s.action = 'add'
ON CONFLICT (id) DO NOTHING;

-- ─── 2. New politician rows (14) ─────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, alternate_names,
   is_active, is_vacant, is_incumbent, party, data_source, source)
SELECT n.id, n.full_name, n.first_name, n.last_name, n.alternate_names,
       true, false, true, NULL, d.board_url, 'CA_0148_la_unified_board_rosters_batch4a'
  FROM _ca0148_newpol n JOIN _ca0148_district d ON d.geo_id = n.geo_id
ON CONFLICT (id) DO NOTHING;

-- ─── 3. Kept rows: no stored party ───────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET party = NULL, is_incumbent = true
 WHERE p.id IN (SELECT new_pol_id FROM _ca0148_seat WHERE action = 'keep')
   AND (p.party IS NOT NULL OR NOT p.is_incumbent);

-- ─── 4. Close the 12 stale terms ─────────────────────────────────────────────────────────────────
UPDATE essentials.office_terms t
   SET term_end  = s.term_start - 1,
       how_ended = 'unknown',
       source    = t.source || ' | closed CA_0148 (2026-09-22): holder is not on the verified current '
                   || d.name || ' board (' || d.board_url || '); actual last day NOT researched -- '
                   || 'term_end is the day before the successor on this generic seat took office'
  FROM _ca0148_seat s JOIN _ca0148_district d ON d.geo_id = s.geo_id
 WHERE t.id = s.stale_term_id
   AND s.action = 'replace'
   AND t.term_end IS NULL;

-- ─── 5. Seat the 14 current members (12 replacements + 2 added seats) ────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT s.office_id, s.new_pol_id, s.term_start, s.start_precision, s.how_started,
       'CA_0148: ' || d.name || ' board roster, ' || d.board_url || ' (read 2026-09-22); ' || s.evidence
       || CASE WHEN s.action = 'add'
               THEN '; seated on a seat added by CA_0148 (the DB had one seat too few for this board)' ELSE '' END
  FROM _ca0148_seat s JOIN _ca0148_district d ON d.geo_id = s.geo_id
 WHERE s.action IN ('replace','add')
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = s.office_id AND t.politician_id = s.new_pol_id
                      AND t.term_start = s.term_start);

-- ─── 6. Stale holders are no longer incumbents ───────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.id IN (SELECT stale_pol_id FROM _ca0148_seat WHERE action = 'replace')
   AND p.is_incumbent
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0148_seat s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id AND och.politician_id = s.new_pol_id;
  IF v_n <> 17 THEN RAISE EXCEPTION 'POST: % of 17 seats resolve to the intended current member', v_n; END IF;

  -- per district: seat count = board size, one active incumbent per seat, nothing flagged vacant
  SELECT count(*) INTO v_bad FROM (
    SELECT d.geo_id, x.seats
      FROM essentials.districts d
      JOIN _ca0148_district x ON x.geo_id = d.geo_id
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
     WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
     GROUP BY d.geo_id, x.seats
    HAVING count(DISTINCT o.id) <> x.seats OR count(DISTINCT p.id) <> x.seats OR bool_or(o.is_vacant)) z;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) do not show one active incumbent per seat', v_bad; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT new_pol_id FROM _ca0148_seat) AND p.party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) carry a stored party', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     WHERE och.politician_id IN (SELECT new_pol_id FROM _ca0148_seat)
     GROUP BY 1 HAVING count(*) <> 1) z;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % seated member(s) hold <> 1 current seat', v_bad; END IF;

  SELECT count(*) INTO v_n FROM _ca0148_seat s JOIN essentials.office_terms t
      ON t.office_id = s.office_id AND t.politician_id = s.new_pol_id
   WHERE s.action IN ('replace','add')
     AND t.term_start = s.term_start AND t.start_precision = s.start_precision
     AND t.how_started = s.how_started AND t.term_end IS NULL AND t.source LIKE 'CA_0148:%';
  IF v_n <> 14 THEN RAISE EXCEPTION 'POST: % of 14 new terms have the expected shape', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0148_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'replace' AND t.term_end = s.term_start - 1
     AND t.how_ended = 'unknown' AND t.source LIKE '%| closed CA_0148%';
  IF v_n <> 12 THEN RAISE EXCEPTION 'POST: % of 12 stale terms closed as intended', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0148_seat s JOIN essentials.office_terms t ON t.id = s.stale_term_id
   WHERE s.action = 'keep' AND t.term_start IS NULL AND t.term_end IS NULL AND t.how_ended IS NULL;
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 kept terms untouched', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ca0148_seat s JOIN essentials.offices a ON a.id = s.office_id
    JOIN essentials.offices t0 ON t0.id = s.template_office
   WHERE s.action = 'add' AND a.chamber_id = t0.chamber_id AND a.district_id = t0.district_id AND a.title = t0.title
     AND (SELECT count(*) FROM essentials.office_terms x WHERE x.office_id = a.id) = 1;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 added seats are as intended', v_n; END IF;

  SELECT count(*) INTO v_bad FROM essentials.politicians p
   WHERE p.id IN (SELECT stale_pol_id FROM _ca0148_seat WHERE action = 'replace')
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % stale holder(s) still current or incumbent', v_bad; END IF;

  -- END TO END: an interior point of each district's polygon returns one active incumbent per seat
  SELECT count(*) INTO v_bad FROM _ca0148_district x
   WHERE (SELECT count(DISTINCT p.id)
            FROM essentials.districts d0
            JOIN essentials.geofence_boundaries me ON me.geo_id = d0.geo_id AND me.mtfcc = d0.mtfcc
            JOIN essentials.geofence_boundaries gb ON public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry))
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc AND d.district_type = 'SCHOOL'
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id
            JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active AND p.is_incumbent
           WHERE d0.geo_id = x.geo_id AND d0.district_type = 'SCHOOL' AND d0.mtfcc = 'G5420'
             AND d.geo_id = x.geo_id) <> x.seats;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % district(s) not reached from inside their own polygon', v_bad; END IF;

  RAISE NOTICE 'CA_0148 applied: 12 seats re-seated + 3 kept + 2 seats added across 3 LA unified boards; 12 stale terms closed; 14 politicians created';
END $$;

COMMIT;
