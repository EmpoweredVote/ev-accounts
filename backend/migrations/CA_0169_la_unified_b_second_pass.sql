-- CA_0169_la_unified_b_second_pass.sql
-- Second research pass on the 99 CA_0156 class-B ("NO EVIDENCE") rows whose roster was NOT complete for
-- their recorded term end (roster_complete <> true in
-- data/roster-audits/2026-09-22-la-unified-unsourced-holders-CA_0156.csv). CA_0156's shared web-search
-- quota ran out mid-audit, so most of these got one search plus a roster check. This pass re-ran them
-- with a fresh quota. Per-row table: data/roster-audits/2026-09-23-la-unified-b-second-pass-CA_0169.csv.
--
-- No migration runner exists; this file records SQL applied by hand over psql (DATABASE_URL).
-- Operator approval: Chris Andrews, 2026-09-23 ("I agree with your recommendations, go ahead").
--
-- ---------------------------------------------------------------------------------------------------
-- A. WHAT WAS DONE (2026-09-23)
-- ---------------------------------------------------------------------------------------------------
--   * Two or more targeted searches per name: one WebSearch ("Full Name" + district + board) and at least
--     one Bing query in a real browser ("Full Name" trustee + city). 113 WebSearches used in total
--     (105 per-name, 8 district-level). DuckDuckGo was dropped after it served a CAPTCHA.
--   * Roster sources ADDED to CA_0156's: the LA County Office of Education directory board lists for all
--     25 districts -- printed directories 2012-13 (Wayback 2012-10-04) and 2013 (Wayback 2013-01-16),
--     online directory 2016 (2019 for Rowland) via Wayback, and the live directory 2026-09-23.
--     0 of 99 surnames appear on their district's board in any of them.
--   * RR/CC results re-pulled from results.lavote.gov (GetElectionData, all 73 elections 2013-2026,
--     10,916 candidate entries, positive control Lucero @ Baldwin Park = 3 hits): no target is a
--     candidate for its own board. CA_0156's result holds.
--   * District-level searches for an official all-time trustee list (the CA_0156 C2 test): none of the
--     25 districts publishes one that could be found.
--
-- ---------------------------------------------------------------------------------------------------
-- B. RESULT: 0 REAL, 0 DISPROVED, 99 STILL NO EVIDENCE
-- ---------------------------------------------------------------------------------------------------
--   Nothing is reactivated and no term is archived or deleted. This file only appends one note per row
--   recording the second pass, so the next audit does not repeat it.
--
--   13 rows carry a NAME-ONLY match to another office. Under the rule for this pass they stay NO
--   EVIDENCE; each note records the lead. Three are local and documented with a fetched source:
--     * George Fuller (Torrance row)   -- West Covina USD trustee: "Serving as a member of the West Covina
--       Board of Education since 1997" (wcusd.org/board/members.html, Wayback 2012-04-25).
--     * Paula Lantz (ABC row)          -- Pomona City Council: "Pomona records show Paula Lantz H held job
--       of Councilmember from 2011 to 2014." (govsalaries.com).
--     * Vicky Martinez (Montebello row) -- El Monte City Council, won 2015-11-03 (RR/CC election 967).
--   OPERATOR RULING 2026-09-23: all three stay NO EVIDENCE. Documentation of another office explains where
--   a seeded name probably came from; it does not show that nobody of that name sat on THIS board -- only a
--   complete official roster does, and none of these districts publishes one. (CA_0156 classed Darcy
--   McNaboe, the same pattern as Paula Lantz, C1 DISPROVED; that row is left as it is -- reclassifying it
--   changes nothing any reader sees.)
--   The real exposure -- kept term_start-NULL placeholder terms answering history lookups -- is fixed
--   separately by CA_0171 (office_holders_as_of skips '| unverified' terms).
--
-- ---------------------------------------------------------------------------------------------------
-- C. ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   UPDATE essentials.politicians
--      SET notes = ARRAY(SELECT n FROM unnest(notes) n WHERE n NOT LIKE 'CA_0169%')
--    WHERE EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0169%');
--
-- IDEMPOTENT: the note is appended only where no 'CA_0169%' note exists; a re-run is a no-op and the
-- post-verify gate still passes.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _b (politician_id uuid PRIMARY KEY, full_name text, district text, lead text) ON COMMIT DROP;
INSERT INTO _b VALUES
  ('e1b7f87e-cde7-408b-860a-f2e034a5dfe0'::uuid, 'Arturo Montez', 'ABC Unified', 'OTHER BOARD, Orange County (name-only) -- https://ballotpedia.org/Art_Montez -- Art Montez, Centralia School District trustee (per CA_0156)'),
  ('401d37f3-24d8-4b95-8be5-46dab72bc477'::uuid, 'Mike Seck', 'ABC Unified', ''),
  ('d142c4c9-ad9c-4003-ac48-27e035ff8f62'::uuid, 'Olimpia Miranda', 'ABC Unified', ''),
  ('bdfbb3bc-d63c-4188-9ba2-528fa9bcf6ec'::uuid, 'Paula Lantz', 'ABC Unified', 'OTHER OFFICE (name-only) -- https://govsalaries.com/paula-h-lantz-67919498 -- Pomona records show Paula Lantz H held job of Councilmember from 2011 to 2014.'),
  ('c3b1093f-891b-4fd2-bc47-521af38f693d'::uuid, 'Ramona Anand', 'ABC Unified', ''),
  ('220bbe64-4cd0-4949-b7a4-7453e316b1f0'::uuid, 'Sommer Foster', 'ABC Unified', 'OTHER OFFICE, far away (name-only) -- Canton Township (Michigan) trustee per search results; not fetched'),
  ('29d411a9-c672-4549-8c2e-a9b276cf8537'::uuid, 'Ed Chung', 'Arcadia Unified', ''),
  ('be1c71f8-d5d9-416e-a713-35ccda7a5743'::uuid, 'Elizabeth Mensah', 'Arcadia Unified', ''),
  ('bf906462-f937-4d8c-b452-6555e95b4bac'::uuid, 'Tim Tran', 'Arcadia Unified', ''),
  ('9d2713c4-1d4f-4c40-ae35-b331e9771fa1'::uuid, 'Ariel Mestas', 'Baldwin Park Unified', ''),
  ('74bfd93c-d707-4432-8e99-ad62a20a1235'::uuid, 'Herman Dace', 'Baldwin Park Unified', ''),
  ('090f3cb2-20e9-42a9-872e-80081f3b5bfe'::uuid, 'Leticia Garcia', 'Baldwin Park Unified', 'OTHER BOARD (name-only) -- https://ballotpedia.org/Leticia_Garcia_(California_school_board_member) -- Leticia Garcia was a member of the Sacramento City Unified School District school board'),
  ('93989522-c68e-4187-bf11-99afb673473f'::uuid, 'Mario Ventura Rodriguez', 'Baldwin Park Unified', ''),
  ('6edc2e44-f7f7-4212-8746-03112a933be3'::uuid, 'Cindy Rosenberger', 'Bellflower Unified', ''),
  ('688fdc43-4d61-48c8-9216-c5cccf722a47'::uuid, 'Joseph Santoyo', 'Bellflower Unified', ''),
  ('b0f48347-625e-4b16-8ac1-e05363219688'::uuid, 'Patricia Avalos', 'Bellflower Unified', ''),
  ('fe5803dd-c13f-4a9a-9c9e-c433a1c390a9'::uuid, 'Rebecca Petz', 'Bellflower Unified', ''),
  ('2000e3c6-9634-4591-97ce-ad9d21274e5e'::uuid, 'Sheila Lichtblau', 'Bellflower Unified', 'OTHER OFFICE (name-only) -- Marin County Superior Court judge; ran for Marin County Board of Education TA1 (pastelections.marincounty.gov)'),
  ('9ddd1703-dbaa-4ec6-8a6b-0ec1ef4ae106'::uuid, 'Svetlana Shagalov', 'Beverly Hills Unified', ''),
  ('9cab21a6-f107-4789-bcd1-b5b1e6cd7a15'::uuid, 'Adam Schur', 'Burbank Unified', ''),
  ('352826a5-7a8a-4f18-980d-a3a655f17720'::uuid, 'Charlene Stiles', 'Burbank Unified', 'GARBLE of real trustee? -- search results return only Charlene Tabet (BUSD 2013-2025); no ''Charlene Stiles'' on any BUSD source'),
  ('2551c624-92bb-4510-8770-e7e10d29c143'::uuid, 'Anita Torres', 'Charter Oak Unified', ''),
  ('3406623a-e942-4677-b154-541c4c05fbc9'::uuid, 'Lisa Gonzalez', 'Charter Oak Unified', ''),
  ('0b2c8789-97c0-40e7-927a-c40f01309d3c'::uuid, 'Marcia Riddick', 'Charter Oak Unified', ''),
  ('29fe6345-0c50-478a-b674-c0868ec29def'::uuid, 'Tim Nader', 'Charter Oak Unified', ''),
  ('f0e9775a-f691-4fe8-84dc-d8f9c5e301c7'::uuid, 'Amy Rottschafer', 'Covina-Valley Unified', ''),
  ('06b5dac4-73b6-44a3-a279-77b1758a6163'::uuid, 'Cheryl Cox', 'Covina-Valley Unified', 'OTHER OFFICE, far away (name-only) -- Chula Vista mayor 2006-2014 (Wikipedia, per CA_0156); DB carries a confirmed Cal-Access link COX FOR MAYOR, CHERYL (1283795)'),
  ('5a521a16-f581-47a0-90eb-1a44434e705b'::uuid, 'John Garcia', 'Covina-Valley Unified', ''),
  ('22763240-b5c9-4ad9-912a-a94cb23db695'::uuid, 'Sam Payán', 'Covina-Valley Unified', ''),
  ('134cc13a-f45a-442c-9946-4cfe893c46b8'::uuid, 'Diego Cardenas', 'El Rancho Unified', ''),
  ('84869bde-6410-46f0-bbe2-1315cd5c017b'::uuid, 'Gloria Negrete-Mendoza', 'El Rancho Unified', ''),
  ('4956d410-f77a-43f8-92c8-e8827e50a17a'::uuid, 'Lesley Chavez Magan', 'El Rancho Unified', ''),
  ('ea4552a4-3112-4089-9902-1630715cba97'::uuid, 'Raquel Otiniano', 'El Rancho Unified', ''),
  ('cbe120bb-0a1a-43ff-ad68-87406b499964'::uuid, 'Tony Fuerte', 'El Rancho Unified', ''),
  ('81154d3e-fe2c-4864-a341-5c8c8538e4b6'::uuid, 'Al Winkler', 'El Segundo Unified', ''),
  ('1bef4877-5dec-4460-ad79-a7ecb186c1b8'::uuid, 'Amanda Grossman', 'El Segundo Unified', ''),
  ('c7a69d69-20b9-4d54-ab4a-33198c9f7c78'::uuid, 'Christian Thomas', 'El Segundo Unified', ''),
  ('d0f59905-f5e3-4e38-a3df-2dc6fb51a4a4'::uuid, 'Dave Horner', 'El Segundo Unified', ''),
  ('0136184a-71a4-48cf-b3f0-52beb7da6038'::uuid, 'Bob Gard', 'Glendora Unified', ''),
  ('215f92ac-46d3-4b48-9567-62ecbc9ed45c'::uuid, 'Dawn Sherrill', 'Glendora Unified', ''),
  ('12223b4f-15c1-4852-9e2a-d1d04ff7c165'::uuid, 'Randy Battenfield', 'Glendora Unified', ''),
  ('4e21995f-5d6b-44ca-aac6-bef3a65dcfc9'::uuid, 'Stephanie Harding', 'Glendora Unified', ''),
  ('c5942060-6b40-46f0-8518-9d6aa0e55307'::uuid, 'Dorothy Chi', 'Hacienda La Puente Unified', ''),
  ('b59c2b42-0cc7-4120-91bd-ea078bb4f248'::uuid, 'Eduardo Arreola', 'Hacienda La Puente Unified', ''),
  ('3497ebda-ffab-4987-bf69-d59bcbd3eb82'::uuid, 'Gloria Mercado-Vega', 'Hacienda La Puente Unified', ''),
  ('6acf611b-8790-4e1f-bb08-05164ae18981'::uuid, 'Jorge Blanco', 'Hacienda La Puente Unified', ''),
  ('4e7828d8-5046-483a-9d71-58cc2d5c0f4c'::uuid, 'Kathleen Reynen', 'Hacienda La Puente Unified', ''),
  ('97aabe4f-794c-4617-8518-cfefe2cd91b7'::uuid, 'Samuel Lee', 'Hacienda La Puente Unified', ''),
  ('002969f3-e8cf-4c1e-8ee9-bc855b0f39ac'::uuid, 'Damien Straughn', 'Inglewood Unified', ''),
  ('0e648516-55fc-4773-ba51-65da7d3c9fda'::uuid, 'Guillermo Vega Jr.', 'Inglewood Unified', 'OTHER ROLE (name-only, not fetched) -- https://transparentcalifornia.com/salaries/2024/school-districts/los-angeles/lynwood-unified/guillermo-vega-jr/ -- search-result title only: "Guillermo Vega Jr. | Transparent California" (Lynwood Unified 2024 salaries); page not fetched'),
  ('1d9d72c9-4a06-41eb-8196-a09f879dce80'::uuid, 'Maria Escobedo', 'Inglewood Unified', ''),
  ('7ea7b7b1-fa32-4652-82a4-4d6f67ad1127'::uuid, 'Yvonne Gallegos', 'Inglewood Unified', ''),
  ('9f240574-48a1-44f7-9728-712ade528e84'::uuid, 'Brian Riddick', 'La Cañada Unified', ''),
  ('0720ce76-332a-4817-b887-2e7599934f64'::uuid, 'Darleen Ramos', 'La Cañada Unified', ''),
  ('ea6acf1c-3ada-4062-b324-0278459c99be'::uuid, 'Diana Carey', 'La Cañada Unified', 'OTHER BOARD, Orange County (name-only) -- https://ocvote.gov/fileadmin/user_upload/elections/GEN2022/cs/3242-5.pdf -- search-result title: "DIANA LEE CAREY Governing Board Member, Huntington Beach Union High"'),
  ('5112b67b-566e-4099-9c8a-2f1fbc623055'::uuid, 'Jon Haraguchi', 'La Cañada Unified', ''),
  ('64f2bab6-2325-41da-8202-b8dd756aa9d3'::uuid, 'Kristin Shane', 'La Cañada Unified', ''),
  ('8f5fded3-98c2-4703-8c83-4ccbf8a6cc7d'::uuid, 'Barry Zorthian', 'Las Virgenes Unified', ''),
  ('62674342-08a9-48ba-bd31-6fb3fe3f8fde'::uuid, 'Christine Wood', 'Las Virgenes Unified', ''),
  ('49ff1385-476d-4bb3-9912-80202b106cbc'::uuid, 'Shira Katz', 'Las Virgenes Unified', ''),
  ('09772a05-d16b-45c4-98c6-8a340dc80734'::uuid, 'Lyn Behrens', 'Long Beach Unified', ''),
  ('67b3bb06-3c13-49dc-93d0-1aa7f5b04672'::uuid, 'Holly Bhagavan', 'Manhattan Beach Unified', ''),
  ('29558ef3-818a-4e33-968c-5abe35f93e1f'::uuid, 'Jason Turner', 'Manhattan Beach Unified', ''),
  ('102e826e-87df-4731-8ee7-ae7c7f0f07dd'::uuid, 'Joanna Robinson', 'Manhattan Beach Unified', ''),
  ('9e396ede-1420-4b3e-aab2-d1799e284e18'::uuid, 'Alex Lujan', 'Monrovia Unified', ''),
  ('2e1658de-04ce-4d50-bb86-6a74f62d2aa6'::uuid, 'Jessica Castro', 'Monrovia Unified', ''),
  ('341f687f-4a41-414c-8da8-7675922e9283'::uuid, 'Mary Ann Blount', 'Monrovia Unified', ''),
  ('f931ec44-44cb-443a-9995-f3e0867be886'::uuid, 'Stephanie Juarez', 'Monrovia Unified', ''),
  ('75c60e41-1ef0-426b-9899-67b8796ea4b8'::uuid, 'Anthony Medina', 'Montebello Unified', ''),
  ('f8dddc8f-f5aa-4e6e-be08-7f686436b3db'::uuid, 'Christina Lara', 'Montebello Unified', ''),
  ('051b8e30-2ddf-4e74-95ac-f02ca3abbeea'::uuid, 'Lorraine Abundis', 'Montebello Unified', ''),
  ('6ded6ac5-dcf5-4e96-aba6-8fc32c827a36'::uuid, 'Paul Shelton', 'Montebello Unified', ''),
  ('c5d72741-5ca0-4aad-ae06-486b1186d070'::uuid, 'Vanessa Ramirez', 'Montebello Unified', ''),
  ('60fb595d-32dd-46b2-a090-b8c5b48d208b'::uuid, 'Vicky Martinez', 'Montebello Unified', 'OTHER OFFICE (name-only) -- https://results.lavote.gov/ElectionResults/GetElectionData?electionID=967 -- EL MONTE CITY GENERAL MUNICIPAL ELECTION Member of the City Council: VICTORIA "VICKY" MARTINEZ (Winner: true), 2015-11-03'),
  ('d9e394d9-3e01-4643-ae70-90fbccc5aeb7'::uuid, 'Adriana Camorlinga', 'Pomona Unified', ''),
  ('a72b6e3b-1f34-4469-b9d1-622b64496927'::uuid, 'Ashley Johnson', 'Pomona Unified', ''),
  ('54dbc290-591b-4a01-95c4-6c2c80c68195'::uuid, 'Chuck Kauffman', 'Pomona Unified', ''),
  ('3f09884f-950d-462b-821f-6161c5d52784'::uuid, 'David Buerge', 'Pomona Unified', ''),
  ('ca63670f-2000-490e-9a99-0317684f1ad9'::uuid, 'Evelyne Aquilar', 'Pomona Unified', ''),
  ('4fe30078-fd83-4d42-aca0-83ea14062dd7'::uuid, 'Isabel Cruz', 'Pomona Unified', ''),
  ('04fcc309-611e-4678-808b-87ca80f95ac6'::uuid, 'Roberta Bacon', 'Pomona Unified', 'GARBLE of real trustee? -- search results return only Roberta A. Perlman (PUSD trustee since 2009)'),
  ('9b1ebb14-fc87-4705-8639-667d8f3b3101'::uuid, 'Cary Romo Nakayama', 'Rowland Unified', ''),
  ('7d4241b8-cc27-48a0-9b76-f205f2eeca84'::uuid, 'Jeff Mata', 'Rowland Unified', ''),
  ('015e3a37-ac58-49a1-8483-1343f33a9356'::uuid, 'Jeff Seawright', 'Rowland Unified', ''),
  ('296f315f-bb67-4816-9bcd-a59108ce972a'::uuid, 'Marilyn Solorzano', 'Rowland Unified', ''),
  ('9dc46319-a05f-4370-9ab6-8577bb61fb91'::uuid, 'Mike Bhatt', 'Rowland Unified', ''),
  ('d46f8101-1cc9-4f2f-8e6a-ceb58febba8b'::uuid, 'Estela Sanchez-Torres', 'San Gabriel Unified', ''),
  ('e526fc4e-536d-4878-b1f0-5d2b903a6ee0'::uuid, 'Megan Ngo', 'San Gabriel Unified', ''),
  ('8825a1a2-c225-47d3-8848-8fa687f0f7ba'::uuid, 'Nora Martinez', 'San Gabriel Unified', ''),
  ('a4ed6e28-252b-4bd5-a6f2-ddb96c37aa3f'::uuid, 'Yvette Vivanco', 'San Gabriel Unified', ''),
  ('3aeeb9e8-68e7-4bd3-a4ff-19958d46debd'::uuid, 'Yvonne Marquez', 'San Gabriel Unified', ''),
  ('636c3d78-e230-4c1f-b267-921c4775b2c4'::uuid, 'Alicia Brodkin', 'Santa Monica-Malibu Unified', ''),
  ('fdc4de72-cd43-4ff8-b13e-28e1c419fe83'::uuid, 'Roy Rifkin', 'Santa Monica-Malibu Unified', ''),
  ('544aa910-95a2-4443-99e5-6a3b350940ae'::uuid, 'George Fuller', 'Torrance Unified', 'OTHER BOARD (name-only) -- http://web.archive.org/web/20120425164857/http://www.wcusd.org/board/members.html -- Serving as a member of the West Covina Board of Education since 1997, Mr. Fuller also enjoys camping'),
  ('08f76054-5a5d-4543-88de-569ffb4d5b96'::uuid, 'Michael Rock', 'Torrance Unified', ''),
  ('a08c5e26-feee-4bbf-a60a-5de90eda74b5'::uuid, 'Ben Kay', 'West Covina Unified', ''),
  ('af08db12-bace-48ce-b9e5-eaa0e3e2ffd8'::uuid, 'Cynthia Moran', 'West Covina Unified', 'OTHER OFFICE (name-only) -- https://www.chinohills.org/174/Cynthia-Moran -- per CA_0156: first elected to the Chino Hills City Council in November 2012'),
  ('4d0397a4-6863-4e57-bfdf-510d3738630b'::uuid, 'Joe Panganiban', 'West Covina Unified', ''),
  ('8f362998-d0ae-490d-a3df-1d5a5de9243f'::uuid, 'Lorenzo Munoz', 'West Covina Unified', '');

CREATE TEMP TABLE _baseline ON COMMIT DROP AS
  SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
         (SELECT count(*) FROM essentials.office_terms ot JOIN _b ON _b.politician_id = ot.politician_id) AS b_terms,
         (SELECT count(*) FROM essentials.politicians p
           WHERE EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0169%')
             AND p.id NOT IN (SELECT politician_id FROM _b)) AS foreign_notes;

-- ─── PRE-VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  IF (SELECT count(*) FROM _b) <> 99 THEN RAISE EXCEPTION 'PRE: _b holds % rows, expected 99', (SELECT count(*) FROM _b); END IF;

  -- every row exists, is the same person CA_0156 audited, and is still deactivated
  SELECT count(*) INTO v_n FROM _b JOIN essentials.politicians p ON p.id = _b.politician_id
   WHERE p.full_name = _b.full_name AND NOT p.is_active AND NOT p.is_incumbent;
  IF v_n <> 99 THEN RAISE EXCEPTION 'PRE: % of 99 rows match by name and are inactive/non-incumbent', v_n; END IF;

  -- each carries exactly one CA_0156 note (its class-B verdict)
  SELECT count(*) INTO v_n FROM _b JOIN essentials.politicians p ON p.id = _b.politician_id
   WHERE (SELECT count(*) FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0156 (2026-09-22): NO EVIDENCE%') = 1;
  IF v_n <> 99 THEN RAISE EXCEPTION 'PRE: % of 99 rows carry exactly one CA_0156 NO EVIDENCE note', v_n; END IF;

  -- their terms are all closed and tagged unverified by CA_0156 (95 terms; 4 rows hold none)
  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _b ON _b.politician_id = ot.politician_id
   WHERE ot.term_end IS NOT NULL AND ot.source LIKE '%| unverified CA_0156%';
  IF v_n <> 95 OR (SELECT b_terms FROM _baseline) <> 95 THEN
    RAISE EXCEPTION 'PRE: % tagged closed terms of % total, expected 95/95', v_n, (SELECT b_terms FROM _baseline); END IF;

  -- no stance data and no ballot row hangs off any of them (nothing to orphan, nothing to show)
  SELECT (SELECT count(*) FROM inform.politician_answers x JOIN _b ON _b.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context x JOIN _b ON _b.politician_id = x.politician_id)
       + (SELECT count(*) FROM essentials.race_candidates x JOIN _b ON _b.politician_id = x.politician_id)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answer/context/race rows point at these politicians', v_n; END IF;

  -- nobody else carries a CA_0169 note
  IF (SELECT foreign_notes FROM _baseline) <> 0 THEN
    RAISE EXCEPTION 'PRE: % rows outside _b already carry a CA_0169 note', (SELECT foreign_notes FROM _baseline); END IF;
END $$;

-- ─── 1. One second-pass note per row ────────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET notes = COALESCE(p.notes, ARRAY[]::text[]) || ARRAY[
       'CA_0169 (2026-09-23): second pass, still NO EVIDENCE of service on the ' || _b.district || ' board. '
       || 'Two targeted searches (WebSearch + Bing), LACOE county directory board lists 2012/2013/2016/2026, '
       || 'RR/CC results 2013-2026 (73 elections) re-pulled: name absent. No official all-time trustee list '
       || 'found for this district. Stays deactivated; closed term kept.'
       || CASE WHEN _b.lead <> '' THEN ' Lead (name-only, not disproof): ' || _b.lead ELSE '' END]
  FROM _b
 WHERE _b.politician_id = p.id
   AND NOT EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0169%');

-- ─── POST-VERIFY ────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _b JOIN essentials.politicians p ON p.id = _b.politician_id
   WHERE (SELECT count(*) FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0169%') = 1;
  IF v_n <> 99 THEN RAISE EXCEPTION 'POST: % of 99 rows carry exactly one CA_0169 note', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0169%')
     AND p.id NOT IN (SELECT politician_id FROM _b);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows outside _b carry a CA_0169 note', v_n; END IF;

  SELECT count(*) INTO v_n FROM _b JOIN essentials.politicians p ON p.id = _b.politician_id
   WHERE p.is_active OR p.is_incumbent;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows became active or incumbent', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _b ON _b.politician_id = ot.politician_id;
  IF v_n <> (SELECT b_terms FROM _baseline) THEN RAISE EXCEPTION 'POST: term count moved to %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> (SELECT missing_terms FROM _baseline) THEN
    RAISE EXCEPTION 'POST: offices_missing_terms moved from % to %', (SELECT missing_terms FROM _baseline), v_n; END IF;
END $$;

COMMIT;
