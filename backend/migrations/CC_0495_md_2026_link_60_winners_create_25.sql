-- CC_0495 — Maryland: link 60 of the 2026 General Assembly winners to the person this database
-- already holds, and create 25 who are genuinely new.
--
-- Pairs with CC_0494 (the dates) and CC_0496 (the seating). This file writes NO term.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE LEDGER SAID "85 WINNERS HAVE NO `politicians` ROW". SIXTY OF THEM DO.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `DATES.md` § MD and the register both recorded Maryland as "85 winners with no person record —
-- the largest people file in the pass by a factor of four". That number is the count of `won`
-- rows in `race_candidates` whose `politician_id` is NULL, and it is correct about the RACE ROWS
-- and wrong about the PEOPLE. Swept against the whole table:
--
--   55  are the SITTING HOLDER of the very seat they just won — David Moon, Jared Solomon,
--       Kathy Szeliga, Dana Stein, Terri Hill, Marvin E. Holmes Jr. and 49 more. The AP import
--       never linked their winner row; every one of them is in `politicians` already.
--    5  are a SITTING DELEGATE who won a SENATE seat — Tiffany Alston (24), C. T. Wilson (28),
--       Nicholaus Kipke (31), Mark S. Chang (32), Malcolm P. Ruff (41).
--   25  are new to this database.
--
-- 🔴 **CREATING ALL 85 WOULD HAVE MADE A SECOND ROW FOR SIXTY SITTING MARYLAND LEGISLATORS**,
--   each one then seated into the seat their own existing row already holds. `CLAUDE.md`'s rule
--   is ONE ROW PER PERSON, and `winner_no_record` means "no record in THIS RACE", never "no
--   record anywhere" — Nevada paid 1 of 13 for this, Maine 18 of 77, and Maryland is 60 of 85.
--   ▶ **Sweep the whole table before creating anybody, and sweep it against the BODY'S OWN
--     ROSTER rather than by name.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- HOW EACH OF THE 60 LINKS IS EVIDENCED — BY SEAT FIRST, BY NAME SECOND
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The anchor is not the name. For each race, the eligible offices are the sibling Delegate (or
-- Senate) offices of that district, and `office_current_holder` names who sits in each one
-- TODAY. A winner is linked to an existing person only when that person is the current holder of
-- an office inside that same race's own district — so the match is scoped to at most three
-- candidates, not to 92,001 rows. P5 asserts exactly that for all 55 same-seat links.
--
-- 🟢 **AND EVERY ONE OF THOSE SITTING HOLDERS WAS CONFIRMED AGAINST THE MARYLAND STATE ARCHIVES'
--   OWN ROSTER** — …/msa/mdmanual/06hse/html/hsedist.html and …/05sen/html/sendist.html, read
--   2026-11-23, 141 Delegates and 47 Senators parsed, matching Art. III § 2 exactly. 177 of our
--   178 sitting holders appear in the Manual under the district we hold them in. The 178th is
--   Subdistrict 34A's "Steve Johnson", whom the Manual writes "Steven C. Johnson" — ⚠ and 34A is
--   the one district holding TWO Johnsons ("Andre V. Johnson, Jr." is the other), which is
--   exactly why the link is anchored on the OFFICE and not on the surname.
--
-- **Four links differ in the first name, and the Manual settles each:**
--
--   ballot (AP)              our row               Maryland Manual, that district
--   ──────────────────────   ───────────────────   ─────────────────────────────────
--   Ken Kerr                 Kenneth Kerr          District 3   — "Kenneth P. Kerr"
--   Jeff Ghrist              Jefferson L. Ghrist   District 36  — "Jefferson L. Ghrist"
--   Tom Hutchinson           Thomas S. Hutchinson  District 37B — "Thomas S. Hutchinson"
--   Robert Julian Ivey       Julian Ivey           District 47A — "R. Julian Ivey"
--
-- 🔴 **THE FIVE CHAMBER SWITCHERS ARE LINKED ON THE SEAT THEY HOLD, NOT ON THE SEAT THEY WON.**
--   Each already sits for the Delegate district of the same number, which the Manual confirms,
--   and each wins the Senate seat currently held by somebody else (Benson 24, Ellis 28,
--   Simonaire 31, Beidle 32, Attar 41). P6 asserts the shape.
--
-- ⚠ **FOUR OF THE FIVE VACATE A DELEGATE SEAT THIS WAVE FILLS. KIPKE DOES NOT.** District 31 is
--   one of the four contests we hold no recorded result for (see CC_0494), so nobody is seated
--   there and his Delegate term is closed by nothing. **From 2027-01-13 our data shows Nicholaus
--   Kipke holding Senate District 31 AND Delegate District 31, and that is the correct output of
--   a missing result, not a defect to tidy.** Closing his House term here would mean inventing a
--   successor. The Maryland Manual's roster for District 31 names Chisholm, Kipke and Nkongolo;
--   the State Board's count gives the 2026 seats to Chisholm, Mike Jacobs and LaToya Marie
--   Caldwell-Nkongolo. **The fix is the result.** (Utah's Doug Fiefia, CC_0490, is the same
--   shape.) P6 names him as the one exception so that a sixth switcher cannot slip in silently.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE NAME IS DELIBERATELY *NOT* LINKED, AND THE DUPLICATE IS WRITTEN DOWN
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The Senate District 42 winner is **Kevin Ford**. This table already holds exactly one
-- "Kevin Ford" — and he is a sitting member of the **Mississippi** House of Representatives,
-- District 54, with an open term. He cannot also have won a Maryland Senate seat, and he is not
-- in the Maryland Manual's roster of either chamber.
--
-- ▶ **So a new row is created and the collision is recorded in that row's own `source`.** This
--   is the `CC_0482` shape (Will Mbah / Wilfred N. Mbah) and the two errors are not symmetric:
--   a duplicate full name is a visible, reversible condition that
--   `reference_person_merge_policy` exists to resolve, while a wrong link publishes a false
--   claim about two named real people at once. 🔴 This repository has already shipped Mark
--   Harris as NC-8 on a name match; Maine holds two active "Chad Perkins", one in Missouri and
--   one in Maine.
--   **P3 lets exactly this one name through and refuses any other collision; P7 asserts the
--   Mississippi row is untouched; assertion 6 refuses unless the new row's source says so.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHERE THE 178 WINNER NAMES COME FROM, AND THE INDEPENDENT READ THAT CONFIRMED THEM
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The result and the ballot spelling are AP's per-state results feed, read 2026-11-13. All 178
-- were then confirmed **candidate by candidate** against the Maryland State Board of Elections'
-- own "Unofficial 2026 Gubernatorial General Election Results" (gen_results_2026_5.html for the
-- Senate, gen_results_2026_6.html for the House, last refreshed 2026-11-20 06:47:33 PM, read
-- 2026-11-23): **47 Senate contests and 71 Delegate contests parsed, 47 + 141 seats, 178 of 178
-- of our winners present in the state's own table, 0 disagreements**, with one name deliberately
-- corrupted first and the comparison watched going red (177 agree, 1 disagree).
--
-- ⚠ Two spellings differ and neither is a disagreement about a person: the State Board writes
--   `S. I. "Sandy" Rosenberg` where AP writes `S. I. Rosenberg`, and `Mark N. Fisher` where AP
--   writes `Mark Fisher`. Both are already-linked incumbents and this file touches neither.
--
-- 🔴 **TWO ARTEFACTS OF OUR OWN PIPELINE LOOKED EXACTLY LIKE FINDINGS AND WERE NOT.** Reading
--   the State Board's UTF-8 pages as latin-1 turned `Peña-Melnyk` into `PeÃ±a-Melnyk` and
--   reported a mismatch on a real person; and Districts 36 and 37B append the county to each
--   candidate's name, because Maryland law caps those contests at one Delegate per county
--   ("Vote for up to 3 - No more than 1 per county"), which made five more. ▶ Before reporting
--   a mismatch between two readings, ask what your own pipeline does to the field.
--
-- `party` is deliberately NULL on all 25 new rows. Ruling, 2026-11-23: *"Parties are not
-- something we celebrate anywhere on our platform."* A NULL party is finished work.

BEGIN;

-- seat  = the district label the race belongs to
-- office_id = the RACE-CARRYING office, which is how the race is found. Under Ruling A this is
--             NOT necessarily the office the winner will be seated in; CC_0496 decides that.
CREATE TEMP TABLE cc0495_people (
  seat       text,
  office_id  uuid,
  person_id  uuid,
  full_name  text,
  first_name text,
  last_name  text,
  create_row boolean
) ON COMMIT DROP;

INSERT INTO cc0495_people VALUES
  ('State Legislative District 10',           'a7f0b89f-ba30-4e14-954e-cf402194303d', 'd80816fc-da1d-48f4-95c9-467f8831933c', 'Jennifer White Holland',          'Jennifer',      'Holland',           false),
  ('State Legislative District 10',           'a7f0b89f-ba30-4e14-954e-cf402194303d', '04eb4549-ad64-4ddc-ad53-8f90217f905f', 'N. Scott Phillips',               'N.',            'Phillips',          false),
  ('State Legislative District 10',           'a7f0b89f-ba30-4e14-954e-cf402194303d', 'd90d6bf0-7a23-4e4b-8961-6efa171963be', 'Robin Harvey',                    'Robin',         'Harvey',            true ),
  ('State Legislative District 13',           '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'b0cc209a-6164-4756-9327-ad65172f2037', 'Amy Brooks',                      'Amy',           'Brooks',            true ),
  ('State Legislative District 13',           '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec', 'Gabriel Maximilian Moreno',       'Gabriel',       'Moreno',            false),
  ('State Legislative District 14',           '1ee9cdb3-7faf-4a70-8356-0c932c9c8f34', '8abee534-5db0-4950-a2b9-d0d1e8088cc7', 'Bernice Mireku-North',            'Bernice',       'Mireku-North',      false),
  ('State Legislative District 14',           '1ee9cdb3-7faf-4a70-8356-0c932c9c8f34', 'aa6f9287-98eb-458f-a5af-05b5110009f8', 'Matt Post',                       'Matt',          'Post',              true ),
  ('State Legislative District 15',           '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'ab8aa19a-42c3-445e-9632-a5c7f05458ee', 'David V. Fraser-Hidalgo',         'David',         'Fraser-Hidalgo',    false),
  ('State Legislative District 15',           '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'e00e72f9-6b53-46a7-a1e4-74ab7b91d68d', 'Lily Qi',                         'Lily',          'Qi',                false),
  ('State Legislative District 16',           'ca7b3ffe-3345-4b52-8a79-0e1b703be635', '4db476f3-bc84-484c-9440-666028942469', 'Sarah Wolek',                     'Sarah',         'Wolek',             false),
  ('State Legislative District 16',           'ca7b3ffe-3345-4b52-8a79-0e1b703be635', '36171e41-704b-4bf9-b300-755afe4ee06f', 'Teresa Saavedra Woorman',         'Teresa',        'Woorman',           false),
  ('State Legislative District 17',           '40a3e126-e06d-4e63-acc8-924512a7e643', '458a60ba-a235-4b36-80bb-8b537375a4ff', 'Joe Vogel',                       'Joe',           'Vogel',             false),
  ('State Legislative District 17',           '40a3e126-e06d-4e63-acc8-924512a7e643', '203a0228-7a63-4a6a-b26d-fa45ba139472', 'Ryan Spiegel',                    'Ryan',          'Spiegel',           false),
  ('State Legislative District 18',           '4984e70f-5313-4313-a658-65e38cc228ec', 'd1a30768-52e8-4a0d-badc-3e5f2f5792c7', 'Emily Shetty',                    'Emily',         'Shetty',            false),
  ('State Legislative District 18',           '4984e70f-5313-4313-a658-65e38cc228ec', 'c0bf0c64-6254-40a7-b810-8717977759dd', 'Jared Solomon',                   'Jared',         'Solomon',           false),
  ('State Legislative District 19',           'f1e0b780-b752-4cbd-85ed-065fccd39a78', '1775b753-692c-443f-837f-9ba5e3a3305f', 'Christa Tichy',                   'Christa',       'Tichy',             true ),
  ('State Legislative District 19',           'f1e0b780-b752-4cbd-85ed-065fccd39a78', 'ac558ee8-ecae-47b6-a25e-46307521b4af', 'Vaughn Stewart',                  'Vaughn',        'Stewart',           false),
  ('State Legislative District 20',           'ce7eef8b-bd6e-41e0-816c-fbff5d310699', '96876928-53f8-4ed5-b2de-deab3a456d83', 'David Moon',                      'David',         'Moon',              false),
  ('State Legislative District 20',           'ce7eef8b-bd6e-41e0-816c-fbff5d310699', 'cf68a5cd-f375-4296-8a87-1828d903baea', 'Jheanelle K. Wilkins',            'Jheanelle',     'Wilkins',           false),
  ('State Legislative District 21',           '4de4d6bc-c24c-44dc-ae7d-f39d1732bd8d', '00cd05cc-75de-4d9a-ab23-9f53441bc186', 'Joseline A. Peña-Melnyk',         'Joseline',      'Peña-Melnyk',       false),
  ('State Legislative District 21',           '4de4d6bc-c24c-44dc-ae7d-f39d1732bd8d', '251a2047-372b-480e-aa09-231f9a5edeca', 'Mary A. Lehman',                  'Mary',          'Lehman',            false),
  ('State Legislative District 22',           'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'd8eee978-cec3-492d-9867-9d40b2a50a9d', 'Ashanti Martinez',                'Ashanti',       'Martinez',          false),
  ('State Legislative District 22',           'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'f85832cc-b4b2-4731-8759-81a600fa2329', 'Molly McKee-Seabrook',            'Molly',         'McKee-Seabrook',    true ),
  ('State Legislative District 22',           'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'ee4f4c8b-c3b9-48cb-876e-85dd1f3709f2', 'Tracy Gant',                      'Tracy',         'Gant',              true ),
  ('State Legislative District 23',           'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'd8133eef-6a49-4d32-82b7-e0e49bda4e31', 'Keenon James',                    'Keenon',        'James',             true ),
  ('State Legislative District 23',           'f959c581-ce74-491e-9cb5-e27fc81cbd01', '9273ed81-2052-428a-b39d-849abeef270b', 'Kym Taylor',                      'Kym',           'Taylor',            false),
  ('State Legislative District 23',           'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'b8e331fa-d58e-479f-b076-8fda0b0604c5', 'Marvin E. Holmes Jr.',            'Marvin',        'Holmes',            false),
  ('State Legislative District 24',           'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', 'd61a670a-7626-4464-93dc-c1e21d7b26da', 'Andrea Fletcher Harrison',        'Andrea',        'Harrison',          false),
  ('State Legislative District 24',           'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', '8fab5ff7-603d-4ab0-a05c-a7070d187a48', 'Derrick L. Coley',                'Derrick',       'Coley',             false),
  ('State Legislative District 24',           'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', '1380caf8-83a8-4916-84ba-9dfbd3c0e160', 'LaTasha R. Ward',                 'LaTasha',       'Ward',              true ),
  ('State Legislative District 25',           '70130202-21d0-4ff3-927d-976492f1fd74', 'd5999df9-83b8-4870-a170-4d13f40473e2', 'Denise Roberts',                  'Denise',        'Roberts',           false),
  ('State Legislative District 25',           '70130202-21d0-4ff3-927d-976492f1fd74', 'cd422f8c-913b-4280-987b-9383ead34e85', 'Karen Toles',                     'Karen',         'Toles',             false),
  ('State Legislative District 26',           'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', '916afe40-4061-476f-9a54-b271b32778d2', 'Jamila J. Woods',                 'Jamila',        'Woods',             false),
  ('State Legislative District 26',           'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', '768ac1cf-a599-4ddb-943c-c985fafb2607', 'Kriselda Valderrama',             'Kriselda',      'Valderrama',        false),
  ('State Legislative District 28',           'a645a828-f92a-4950-8d79-3b21b2731961', '32667326-7a42-4354-ac58-fdfdeb01e12f', 'Abena Affum-McAllister',          'Abena',         'Affum-McAllister',  true ),
  ('State Legislative District 28',           'a645a828-f92a-4950-8d79-3b21b2731961', 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266', 'Edith J. Patterson',              'Edith',         'Patterson',         false),
  ('State Legislative District 3',            '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', '5946ad0c-ddf5-4674-840e-6968105042cd', 'Karen Simpson',                   'Karen',         'Simpson',           false),
  ('State Legislative District 3',            '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255', 'Ken Kerr',                        'Ken',           'Kerr',              false),
  ('State Legislative District 32',           'f1009191-dcef-4657-a2eb-40a20289a054', '24980735-6a39-4e48-94b0-7318cac8dfde', 'Mike Rogers',                     'Mike',          'Rogers',            false),
  ('State Legislative District 32',           'f1009191-dcef-4657-a2eb-40a20289a054', 'a99b2c52-7454-41c2-a48d-021f3a963730', 'Spencer F. Dixon',                'Spencer',       'Dixon',             true ),
  ('State Legislative District 36',           'c07711d6-eee8-4343-8ab7-62479fe4ffac', '8b43dd9c-26c3-48bb-ac60-d95f8a39349a', 'Jay A. Jacobs',                   'Jay',           'Jacobs',            false),
  ('State Legislative District 36',           'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'eca530ff-628d-417d-a3dc-b858dc7c2376', 'Jeff Ghrist',                     'Jeff',          'Ghrist',            false),
  ('State Legislative District 39',           '0cb0a265-5710-4456-8f78-7a4fab3c8f86', 'b7e2aa8f-a301-4004-81e9-d1f857c81075', 'Greg Wims',                       'Greg',          'Wims',              false),
  ('State Legislative District 39',           '0cb0a265-5710-4456-8f78-7a4fab3c8f86', '2fa68ca4-00b5-4518-a692-d12447d7fec3', 'Lesley J. Lopez',                 'Lesley',        'Lopez',             false),
  ('State Legislative District 40',           'd5ec3f19-e9e2-4f4a-8cda-9a2ded496e60', '7217c1b4-6fae-447d-9566-f2513319fa94', 'Melissa Wells',                   'Melissa',       'Wells',             false),
  ('State Legislative District 40',           'd5ec3f19-e9e2-4f4a-8cda-9a2ded496e60', 'a6d37a0f-36ba-4ec8-95ea-bc1048b33d3a', 'Tiffany Welch',                   'Tiffany',       'Welch',             true ),
  ('State Legislative District 41',           'd22d3bdb-71c0-41af-b84d-a8ceb4e17b97', '719dcdfc-c910-480b-af56-4dba20caa1d8', 'Ryan Turner',                     'Ryan',          'Turner',            true ),
  ('State Legislative District 41',           'd22d3bdb-71c0-41af-b84d-a8ceb4e17b97', '012af8f7-693a-4ddc-b0bc-953dae8d2bc2', 'Sean A. Stinnett',                'Sean',          'Stinnett',          false),
  ('State Legislative District 45',           '2f135b6a-4dd6-458a-988a-95d72b291956', '92075c9b-6c7e-4763-981f-5a42a8afddf5', 'Caylin Young',                    'Caylin',        'Young',             false),
  ('State Legislative District 45',           '2f135b6a-4dd6-458a-988a-95d72b291956', 'be9232e4-a021-42f5-bf6a-582226698db8', 'Chanel A. Branch',                'Chanel',        'Branch',            true ),
  ('State Legislative District 46',           '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', 'bec4b395-bb4b-4740-ac1c-8e89f12608a2', 'Mark Edelson',                    'Mark',          'Edelson',           false),
  ('State Legislative District 46',           '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', '9285f590-79b5-48de-a1c0-a022629e6ebb', 'Robbyn Lewis',                    'Robbyn',        'Lewis',             false),
  ('State Legislative District 5',            '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', '5967c703-2583-466f-a438-c3ac182111d5', 'April R. Rose',                   'April',         'Rose',              false),
  ('State Legislative District 5',            '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904', 'Chris Tomlinson',                 'Chris',         'Tomlinson',         false),
  ('State Legislative District 5',            '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', '41d718b2-c9b4-4d62-b0fe-61ca88332d2f', 'Steve Whisler',                   'Steve',         'Whisler',           true ),
  ('State Legislative District 8',            '346c6035-4668-427f-96ad-afd832484ad3', '6d95657c-6c46-4aab-886f-f9688adc7b33', 'Harry Bhandari',                  'Harry',         'Bhandari',          false),
  ('State Legislative District 8',            '346c6035-4668-427f-96ad-afd832484ad3', '5d17e3ea-9d63-4a96-8848-9e293ac05fdb', 'Kim L. Ross',                     'Kim',           'Ross',              false),
  ('State Legislative Subdistrict 11B',       'a88be23e-bbd9-4703-bf76-7877f179e131', 'e94337e1-4776-4058-87b4-32dfeb7732a0', 'Dana Stein',                      'Dana',          'Stein',             false),
  ('State Legislative Subdistrict 12A',       '117ea3a2-17e5-4ce3-bb84-b42d54b6a628', 'f6a237a0-34ff-4a93-b05a-335ec38b6da3', 'Terri Hill',                      'Terri',         'Hill',              false),
  ('State Legislative Subdistrict 1A',        'be0d2bcf-bc8f-4cd3-bcd3-e09e255dd5f8', '8534a618-9cbf-4890-aa24-931fcebd047f', 'Dan Duggan',                      'Dan',           'Duggan',            true ),
  ('State Legislative Subdistrict 29B',       'cbf4386d-2f9a-4b0a-b3e7-993ce8339c3b', '928fcf91-bd31-42d9-a34a-f0bf70c10201', 'Adrianne M. Mathis',              'Adrianne',      'Mathis',            true ),
  ('State Legislative Subdistrict 2A',        'ecd872d1-6f97-4a99-afd1-b80fc76d7ced', 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7', 'William J. Wivell',               'William',       'Wivell',            false),
  ('State Legislative Subdistrict 30A',       '04771969-dba3-4a5b-96a3-0903e9d24910', 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf', 'Dana Jones',                      'Dana',          'Jones',             false),
  ('State Legislative Subdistrict 33B',       '84a3c1ef-f6ea-4e8b-b6d9-26f7cda0ee2e', 'bed1d56a-f6fc-462a-a305-19d02d11e783', 'Chuck Cook',                      'Chuck',         'Cook',              true ),
  ('State Legislative Subdistrict 34A',       '9269138d-b572-4609-bb86-bdffa3ec8bf7', 'dbb1c600-c87b-449c-bd3b-1c236287c00f', 'Steve Johnson',                   'Steve',         'Johnson',           false),
  ('State Legislative Subdistrict 35A',       '1220b835-9c8d-4b71-8e24-cc803c688015', '547841f2-3476-4e83-9344-0cac984d44e8', 'Teresa Reilly',                   'Teresa',        'Reilly',            false),
  ('State Legislative Subdistrict 35B',       'aefe1a1a-4df7-4803-ac6f-754c963ac2a7', 'ee129e40-3ec3-4425-8600-6a8e3dd6cf05', 'Derek J. Howell',                 'Derek',         'Howell',            true ),
  ('State Legislative Subdistrict 37B',       'bd0973d8-505f-4477-bfee-9d1b67f4125b', 'fb1fe811-b340-42d3-88ee-97b5364117cd', 'Tom Hutchinson',                  'Tom',           'Hutchinson',        false),
  ('State Legislative Subdistrict 38A',       'd7ba04fc-d342-44f2-8df7-76a33241f352', 'a07ea819-9bfd-4209-a2a8-a8cb0da4ad49', 'C.L. Marshall III',               'C.L.',          'Marshall',          true ),
  ('State Legislative Subdistrict 38B',       'af0c4413-22d1-4219-8972-c81da7d5970c', 'd9542d05-217f-4e1c-a560-ba28dc94b222', 'Josh Hastings',                   'Josh',          'Hastings',          true ),
  ('State Legislative Subdistrict 42A',       '7f8936f1-734a-4f4e-9d48-d73399dba7f1', '47827d99-df62-4e0a-a5f4-ec935df65393', 'Charles Edward Murphy III',       'Charles',       'Murphy',            true ),
  ('State Legislative Subdistrict 42C',       'bb979c67-1e70-4002-beaa-d4c7a7fe92cc', 'cf840d6a-6b39-430e-81a8-a7064f05c596', 'Steve Patten',                    'Steve',         'Patten',            true ),
  ('State Legislative Subdistrict 43A',       '90259d95-991d-4535-8d06-db1abca0c6f9', '03a161cf-1da8-4c34-9c08-d91bbf958987', 'Elizabeth Embry',                 'Elizabeth',     'Embry',             false),
  ('State Legislative Subdistrict 44B',       'f5446de1-714e-44fe-bd32-d3740fe078ad', 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e', 'Sheila Ruth',                     'Sheila',        'Ruth',              false),
  ('State Legislative Subdistrict 47A',       '63a04f44-51eb-4999-afe0-0f8ef4d5ddbf', '69bf6043-4546-4804-ae04-311cff54a986', 'Robert Julian Ivey',              'Robert',        'Ivey',              false),
  ('State Legislative Subdistrict 7A',        'dcdd107f-c96f-4087-887f-6071434f0ae3', '0945acd2-cb51-49ad-a22f-6043d2e61520', 'Kathy Szeliga',                   'Kathy',         'Szeliga',           false),
  ('State Legislative Subdistrict 9A',        'd3550c38-2ebe-41d2-b06a-59fad7901015', '38b5030a-aa8b-4363-8b62-3ec384d22088', 'Natalie Ziegler',                 'Natalie',       'Ziegler',           false),
  ('State Senate District 24',                'ff52f036-ad8b-46b4-815f-e51216f7ea8d', '2e809682-2d95-480c-885e-d2174b811cfe', 'Tiffany Alston',                  'Tiffany',       'Alston',            false),
  ('State Senate District 28',                '4281af61-6cf0-48b0-8390-1b8981502683', '69870c10-cea2-43c2-8cf9-bfcaf0b82265', 'C. T. Wilson',                    'C.',            'Wilson',            false),
  ('State Senate District 31',                'a6102124-3983-4855-a1de-eaac07932591', '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08', 'Nicholaus Kipke',                 'Nicholaus',     'Kipke',             false),
  ('State Senate District 32',                '9869176e-f7e6-4478-bdb2-87c9bf0ded9e', '4a409af4-8568-42c3-bb72-7bb7500c96ce', 'Mark S. Chang',                   'Mark',          'Chang',             false),
  ('State Senate District 39',                'f4b68d2b-ea9a-4259-acd2-3948066a86bb', 'b8b90558-313a-4c97-a991-a34cf98d12bb', 'Amar Mukunda',                    'Amar',          'Mukunda',           true ),
  ('State Senate District 4',                 'd383a280-2a6b-4b1a-99e7-0f28ce9b4673', '05a9de08-6aaf-45ec-81f0-7c88226fa7b8', 'Lara Westdorp',                   'Lara',          'Westdorp',          true ),
  ('State Senate District 41',                'bce321bb-f23c-493a-b24c-9a9a25795bfd', '7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4', 'Malcolm P. Ruff',                 'Malcolm',       'Ruff',              false),
  ('State Senate District 42',                '6c2421ee-9193-4da2-a95a-447732e29cac', '938d4f3b-c204-4059-84d1-6f4999548e69', 'Kevin Ford',                      'Kevin',         'Ford',              true );

-- The winner rows this file will link, matched by (race, ballot name) — NOT by office alone,
-- because a Maryland Delegate race carries up to three winners on one office row.
CREATE TEMP TABLE cc0495_rc ON COMMIT DROP AS
SELECT rc.id AS race_candidate_id, pp.seat, pp.person_id, pp.create_row, pp.full_name,
       rc.full_name AS ballot_name, rc.politician_id AS politician_id_before
  FROM cc0495_people pp
  JOIN essentials.races r            ON r.office_id = pp.office_id
  JOIN essentials.elections e        ON e.id = r.election_id
                                    AND e.election_date = DATE '2026-11-03'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won'
                                    AND rc.full_name = pp.full_name;

CREATE TEMP TABLE cc0495_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians)     AS politicians,
       (SELECT count(*) FROM essentials.office_terms)    AS terms,
       (SELECT count(*) FROM essentials.race_candidates) AS race_candidates,
       -- 🔴 THE MISSISSIPPI KEVIN FORD. Pinned so assertion 7 can prove nothing happened to him.
       (SELECT count(*) FROM essentials.office_terms
         WHERE politician_id = '8ac69128-f1d9-44ee-8abb-da344684ab46'
           AND term_end IS NULL)                         AS ms_ford_open_seats;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — the file lists what it says it lists, and it matches the data it was written against.
  SELECT count(*) INTO n FROM cc0495_people;
  IF n <> 85 THEN
    RAISE EXCEPTION 'P1: the file lists % people, expected 85.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0495_rc;
  IF n <> 85 THEN
    RAISE EXCEPTION 'P1: % winner rows matched the 85 (race, ballot name) pairs, expected 85. '
                    'The data moved under this file — a name respelt in race_candidates is '
                    'enough to do it.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0495_rc WHERE politician_id_before IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the 85 winner rows already carry a politician_id. This file would '
                    'overwrite a link it did not make.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0495_people WHERE create_row;
  IF n <> 25 THEN
    RAISE EXCEPTION 'P1: % rows are marked for creation, expected 25 (85 less the 55 sitting '
                    'members of the seat they won and the 5 Delegates moving to the Senate).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0495_people WHERE NOT create_row;
  IF n <> 60 THEN
    RAISE EXCEPTION 'P1: % rows are marked for linking, expected 60.', n;
  END IF;
  -- 🔴 EVERY ONE OF THE 85 IS A MARYLAND LEGISLATIVE SEAT PENDING FOR THIS ELECTION.
  SELECT count(DISTINCT pp.office_id) INTO n
    FROM cc0495_people pp
    JOIN essentials.office_pending_winner w ON w.office_id = pp.office_id
                                           AND w.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = pp.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> (SELECT count(DISTINCT office_id) FROM cc0495_people) THEN
    RAISE EXCEPTION 'P1: not every race named in this file is a pending Maryland legislative '
                    'race for 2026-11-03.';
  END IF;

  -- P2 — the 25 new ids do not exist. (Applied before?)
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0495_people pp ON pp.person_id = p.id WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 25 new politician ids already exist. Applied before.', n;
  END IF;

  -- P3 — 🔴🔴 THE DUPLICATE-NAME GUARD, WITH ITS ONE DELIBERATE EXCEPTION NAMED.
  -- 24 of the 25 names must be absent from the table entirely. The 25th is Kevin Ford, whose
  -- namesake sits in the MISSISSIPPI House of Representatives — see the header. Written as "the
  -- only collision is this one", not as "skip Kevin Ford", so a SECOND collision still fires.
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.politicians p
      ON p.first_name = pp.first_name AND p.last_name = pp.last_name
   WHERE pp.create_row AND pp.full_name <> 'Kevin Ford';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % existing politician row(s) already carry one of the 25 new names on '
                    '(first_name, last_name). ONE ROW PER PERSON — read the row before creating '
                    'a second. ⚠ The guard keys on (first_name, last_name), so an identical '
                    'full_name split differently is invisible to it; P3b is the other half.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.politicians p ON lower(p.full_name) = lower(pp.full_name)
   WHERE pp.create_row AND pp.full_name <> 'Kevin Ford';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3b: % existing politician row(s) carry one of the 25 full names, which '
                    'the (first_name, last_name) guard above did not see.', n;
  END IF;

  -- P4 — every one of the 60 link targets is an ACTIVE politician holding a Maryland seat today.
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.politicians p ON p.id = pp.person_id
   WHERE NOT pp.create_row
     AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices o   ON o.id = t.office_id
                   JOIN essentials.districts d ON d.id = o.district_id
                  WHERE t.politician_id = p.id AND lower(d.state) = 'md'
                    AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
                    AND t.term_end IS NULL);
  IF n <> 60 THEN
    RAISE EXCEPTION 'P4: only % of the 60 link targets are an active politician currently '
                    'holding a Maryland General Assembly seat, expected 60. A link that does '
                    'not rest on a seat rests on a name.', n;
  END IF;

  -- P5 — 🔴 THE 55 SAME-SEAT LINKS: each person currently holds an office INSIDE THAT RACE'S OWN
  -- ELIGIBLE SET — same district, same chamber, same title as the office carrying the race. This
  -- is what makes the match a seat match rather than a name match, and it is scoped to at most
  -- three sitting members rather than to the whole table.
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.offices ro ON ro.id = pp.office_id
   WHERE NOT pp.create_row
     AND EXISTS (SELECT 1
                   FROM essentials.offices o2
                   JOIN essentials.office_current_holder och ON och.office_id = o2.id
                  WHERE o2.district_id = ro.district_id
                    AND o2.chamber_id IS NOT DISTINCT FROM ro.chamber_id
                    AND o2.title = ro.title
                    AND och.politician_id = pp.person_id);
  IF n <> 55 THEN
    RAISE EXCEPTION 'P5: % of the 60 links are to the sitting holder of a seat in that race''s '
                    'own eligible set, expected 55. The other 5 are Delegates moving to the '
                    'Senate and are checked by P6.', n;
  END IF;

  -- P6 — 🔴 THE FIVE CHAMBER SWITCHERS, AND THE ONE WHOSE OLD SEAT THIS WAVE CANNOT FILL.
  -- Each holds a Maryland DELEGATE seat and wins a SENATE seat they do not hold.
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.offices ro  ON ro.id = pp.office_id
    JOIN essentials.districts rd ON rd.id = ro.district_id
    JOIN essentials.office_terms t ON t.politician_id = pp.person_id AND t.term_end IS NULL
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
                               AND d.district_type = 'STATE_LOWER' AND lower(d.state) = 'md'
   WHERE NOT pp.create_row AND rd.district_type = 'STATE_UPPER';
  IF n <> 5 THEN
    RAISE EXCEPTION 'P6: % Senate winner(s) in this file currently hold a Maryland Delegate '
                    'seat, expected exactly 5 (Alston 24, Wilson 28, Kipke 31, Chang 32, '
                    'Ruff 41). If this is fewer, a link rests on the name alone; if more, '
                    'somebody else is switching and the header does not describe them.', n;
  END IF;
  -- Four of the five vacate a Delegate seat that IS in this wave. Kipke's District 31 is one of
  -- the four contests with no recorded result, so his House seat is filled by nobody and he will
  -- hold two from 2027-01-13. Asserted as 4, with him named, rather than waved past.
  -- ⚠ "IN THIS WAVE" IS NOT "CARRIES A PENDING RACE". Under Ruling A a Delegate seat is filled
  -- by the race on ANY sibling office of its district, and office_pending_winner answers only
  -- for the one office the race hangs on. Asking the narrow question here returns 1 of 5 and
  -- reads as four broken links; it is the question that is wrong.
  SELECT count(*) INTO n
    FROM cc0495_people pp
    JOIN essentials.offices ro   ON ro.id = pp.office_id
    JOIN essentials.districts rd ON rd.id = ro.district_id
    JOIN essentials.office_terms t ON t.politician_id = pp.person_id AND t.term_end IS NULL
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
                                AND d.district_type = 'STATE_LOWER' AND lower(d.state) = 'md'
   WHERE NOT pp.create_row AND rd.district_type = 'STATE_UPPER'
     AND EXISTS (SELECT 1
                   FROM essentials.office_pending_winner w2
                   JOIN essentials.offices ro2 ON ro2.id = w2.office_id
                  WHERE w2.election_date = DATE '2026-11-03'
                    AND ro2.district_id = o.district_id
                    AND ro2.chamber_id IS NOT DISTINCT FROM o.chamber_id
                    AND ro2.title = o.title);
  IF n <> 4 THEN
    RAISE EXCEPTION 'P6: % of the 5 switchers vacate a Delegate seat that this wave fills, '
                    'expected 4. The fifth is Nicholaus Kipke, whose District 31 is one of the '
                    'four contests we hold no recorded result for — he will hold a Senate and a '
                    'Delegate seat from 2027-01-13, which is what a missing result looks like '
                    'and is not a defect to tidy here.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08'
     AND lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State Legislative District 31' AND t.term_end IS NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P6: Nicholaus Kipke holds % open Delegate District 31 term(s), expected 1. '
                    'That seat is the reason this file says he will hold two.', n;
  END IF;

  -- P7 — 🔴🔴 THE MISSISSIPPI KEVIN FORD IS NOT THE MARYLAND ONE, AND THIS FILE REFUSES TO LINK
  -- HIM. Asserted as a fact about the row, not as an absence.
  SELECT count(*) INTO n FROM essentials.politicians WHERE full_name = 'Kevin Ford';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: % politician row(s) are named Kevin Ford, expected exactly 1 before '
                    'this file runs. The header''s argument — that the only Kevin Ford we hold '
                    'is a sitting Mississippi representative — is about that one row.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '8ac69128-f1d9-44ee-8abb-da344684ab46'
     AND lower(d.state) = 'ms' AND d.district_type = 'STATE_LOWER' AND t.term_end IS NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: the existing Kevin Ford row holds % open Mississippi State House '
                    'seat(s), expected 1. THAT SEAT IS THE EVIDENCE for creating a second row '
                    'rather than linking his — a sitting Mississippi representative did not '
                    'also win Maryland Senate District 42, and he is in neither chamber of the '
                    'Maryland Manual''s roster.', n;
  END IF;
  IF EXISTS (SELECT 1 FROM cc0495_people
              WHERE person_id = '8ac69128-f1d9-44ee-8abb-da344684ab46') THEN
    RAISE EXCEPTION 'P7: this file links the Mississippi Kevin Ford''s id. It must not.';
  END IF;

  -- P8 — no person id appears on more than one seat.
  SELECT count(*) INTO n FROM (
    SELECT person_id FROM cc0495_people GROUP BY person_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % person id(s) appear on more than one seat.', n;
  END IF;

  -- P9 — the ballot name is reproduced exactly. cc0495_rc already joins on it, so a mismatch
  -- would have shown as a short count in P1; this states the claim so the next reader sees it.
  SELECT count(*) INTO n FROM cc0495_rc WHERE ballot_name IS DISTINCT FROM full_name;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P9: % winner row(s) carry a ballot name this file does not reproduce '
                    'exactly.', n;
  END IF;
END $$;

-- ── The 24 whose name is new to this table. ───────────────────────────────────────────────────
-- 🔴 THE DATABASE'S OWN DUPLICATE-NAME TRIGGER STAYS ARMED FOR THESE. The override below is a
-- SECOND statement, for one row, so that the guard still fires if any of these 24 collides with
-- somebody after this file was written. A `SET LOCAL … = 'on'` wrapped around all 25 would
-- disarm the guard for a name nobody has looked at.
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, true,
       'Winner of the 2026-11-03 general election for ' || pp.seat || ', Maryland. The result '
         || 'and the ballot spelling are AP''s per-state results feed, read 2026-11-13, '
         || 'confirmed candidate by candidate against the Maryland State Board of Elections'' '
         || 'own "Unofficial 2026 Gubernatorial General Election Results" '
         || '(https://elections.maryland.gov/elections/2026/general_results/'
         || 'gen_results_2026_5.html and …_6.html, last refreshed 2026-11-20 06:47:33 PM, read '
         || '2026-11-23): 47 Senate and 71 Delegate contests parsed, 188 seats, 178 of 178 of '
         || 'our winners present in the state''s own table, 0 disagreements, with one name '
         || 'deliberately corrupted first and the comparison watched going red. The whole '
         || 'politicians table was then swept three ways before this row was created — on '
         || '(first_name, last_name), on full_name, and by surname across every row including '
         || 'archived ones — and every winner was checked against the Maryland State Archives'' '
         || 'own roster of all 141 Delegates and 47 Senators '
         || '(https://msa.maryland.gov/msa/mdmanual/06hse/html/hsedist.html and '
         || '…/05sen/html/sendist.html, read 2026-11-23). That sweep is what found the 60 '
         || 'winners who ALREADY had a row and were linked rather than created. '
         || '`party` is deliberately NULL: parties are not something this platform records '
         || 'except where a one-party primary makes it load-bearing. Created by CC_0495; NOT '
         || 'seated here — CC_0496 seats, for 2027-01-13.'
  FROM cc0495_people pp
 WHERE pp.create_row AND pp.full_name <> 'Kevin Ford';

-- ── The 25th: the one deliberate duplicate. ───────────────────────────────────────────────────
-- 🔴🔴 `essentials.politicians` CARRIES A TRIGGER THAT REFUSES A SECOND ACTIVE ROW UNDER AN
-- EXISTING NAME, and it fired on this one — correctly. Its message is the right default: "A
-- sitting officeholder running for a different seat is the normal case, not a different person."
-- Here it is not. The Kevin Ford this table holds (8ac69128-…) sits in the MISSISSIPPI House of
-- Representatives, District 54, with an open term, and no Kevin Ford appears in either chamber
-- of the Maryland Manual's roster. The override is taken for ONE row, with the reason in that
-- row's own source, and handed straight back.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, true,
       'Winner of the 2026-11-03 general election for ' || pp.seat || ', Maryland. The result '
         || 'and the ballot spelling are AP''s per-state results feed, read 2026-11-13, '
         || 'confirmed against the Maryland State Board of Elections'' own "Unofficial 2026 '
         || 'Gubernatorial General Election Results" (…/general_results/gen_results_2026_5.html, '
         || 'read 2026-11-23), where Senate District 42 reads Kevin Ford. '
         || '🔴🔴 DUPLICATE FULL NAME, DELIBERATE, AND OWED A LOOK: this database already holds '
         || 'a "Kevin Ford" (8ac69128-f1d9-44ee-8abb-da344684ab46) who is a sitting member of '
         || 'the MISSISSIPPI House of Representatives, District 54, with an open term. He is a '
         || 'different person — a sitting Mississippi representative did not also win Maryland '
         || 'Senate District 42, and no Kevin Ford appears in either chamber of the Maryland '
         || 'State Archives'' roster of the General Assembly '
         || '(https://msa.maryland.gov/msa/mdmanual/05sen/html/sendist.html and '
         || '…/06hse/html/hsedist.html, read 2026-11-23, 47 + 141 members parsed). The two rows '
         || 'are NOT a merge candidate; this note exists so that a later duplicate-name sweep '
         || 'finds the reasoning instead of re-deriving it. The alternative — linking his row — '
         || 'would have published a false claim about two named real people at once, which is '
         || 'the error this repository already made shipping Mark Harris as NC-8. '
         || 'essentials.allow_duplicate_name was taken for this single row and handed back. '
         || '`party` is deliberately NULL. Created by CC_0495; NOT seated here — CC_0496 seats, '
         || 'for 2027-01-13.'
  FROM cc0495_people pp
 WHERE pp.create_row AND pp.full_name = 'Kevin Ford';
SET LOCAL essentials.allow_duplicate_name = 'off';

UPDATE essentials.race_candidates rc
   SET politician_id = c.person_id
  FROM cc0495_rc c
 WHERE rc.id = c.race_candidate_id
   AND rc.politician_id IS NULL;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0495_before;

  -- 1. Exactly 25 rows were created, and they read back as intended with a NULL party.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians + 25 THEN
    RAISE EXCEPTION '1: politicians went % -> %, a delta of %, expected 25.',
      b.politicians, n, n - b.politicians;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.politicians p JOIN cc0495_people pp ON pp.person_id = p.id
   WHERE pp.create_row AND p.full_name = pp.full_name AND p.first_name = pp.first_name
     AND p.last_name = pp.last_name AND p.is_active AND p.party IS NULL;
  IF n <> 25 THEN
    RAISE EXCEPTION '1: % of the 25 new rows read back correctly, with a NULL party.', n;
  END IF;

  -- 2. All 85 winner rows carry the intended politician_id.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN cc0495_rc c ON c.race_candidate_id = rc.id
   WHERE rc.politician_id = c.person_id;
  IF n <> 85 THEN
    RAISE EXCEPTION '2: % of 85 winner rows carry the intended politician_id.', n;
  END IF;

  -- 3. 🔴 NOTHING HAPPENED TO THE MISSISSIPPI KEVIN FORD.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id = '8ac69128-f1d9-44ee-8abb-da344684ab46' AND term_end IS NULL;
  IF n <> b.ms_ford_open_seats THEN
    RAISE EXCEPTION '3: the Mississippi Kevin Ford''s open terms went % -> %. This file creates '
                    'a separate row for the Maryland winner and touches his not at all.',
      b.ms_ford_open_seats, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.politicians WHERE full_name = 'Kevin Ford';
  IF n <> 2 THEN
    RAISE EXCEPTION '3: % politician row(s) are now named Kevin Ford, expected exactly 2 — the '
                    'sitting Mississippi representative and the new Maryland senator-elect.', n;
  END IF;

  -- 4. This file seats nobody and creates no race row.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms THEN
    RAISE EXCEPTION '4: office_terms moved % -> %. This file seats nobody.', b.terms, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates;
  IF n <> b.race_candidates THEN
    RAISE EXCEPTION '5: race_candidates moved % -> %. This file links rows; it creates none.',
      b.race_candidates, n;
  END IF;

  -- 6. 🔴 THE DUPLICATE IS WRITTEN DOWN. A duplicate nobody recorded is a duplicate nobody will
  --    ever look at again.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = '938d4f3b-c204-4059-84d1-6f4999548e69'
     AND source LIKE '%DUPLICATE FULL NAME%' AND source LIKE '%MISSISSIPPI%';
  IF n <> 1 THEN
    RAISE EXCEPTION '6: the new Kevin Ford row does not record the Mississippi namesake in its '
                    'own source. A deliberate duplicate that is not written down is '
                    'indistinguishable from a mistake.';
  END IF;

  -- 7. Every Maryland legislative winner now has a person record — the state CC_0496 needs.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03' AND (win.value ->> 'id') IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % Maryland legislative winner(s) still have no person record.', n;
  END IF;

  -- 8. The wave is still the size this file was written for.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 114 THEN
    RAISE EXCEPTION '8: % Maryland legislative races are pending, expected 114 (67 Delegate + '
                    '47 Senate).', n;
  END IF;
  SELECT sum(jsonb_array_length(w.winners)) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 178 THEN
    RAISE EXCEPTION '8: % Maryland legislative winners across those races, expected 178.', n;
  END IF;

  RAISE NOTICE 'CC_0495 OK: 60 Maryland General Assembly winners LINKED to the row this '
               'database already held and 25 created. The ledger recorded 85 winners "with no '
               'politicians row"; that was true of the race rows and wrong about the people — '
               '55 are the sitting holder of the very seat they won and 5 are Delegates moving '
               'to the Senate (Alston 24, Wilson 28, Kipke 31, Chang 32, Ruff 41). Every link '
               'is anchored on a SEAT inside the race''s own district and confirmed against the '
               'Maryland State Archives'' roster of all 141 Delegates and 47 Senators; four '
               'differ only in the first name (Ken/Kenneth P. Kerr, Jeff/Jefferson L. Ghrist, '
               'Tom/Thomas S. Hutchinson, Robert Julian/R. Julian Ivey). ⚠ Nicholaus Kipke''s '
               'Delegate District 31 is one of the four contests with no recorded result, so he '
               'will hold two seats from 2027-01-13 — the fix is the result. 🔴 Kevin Ford was '
               'deliberately NOT linked: our only Kevin Ford sits in the MISSISSIPPI House, and '
               'the duplicate is recorded in the new row''s own source. No terms written.';
END $$;

COMMIT;
