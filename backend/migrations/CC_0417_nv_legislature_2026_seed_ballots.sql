-- CC_0417 - 2026-11-03 Nevada legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the 53 races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. `CC_0381`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for Nevada.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The Nevada legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    `essentials.office_terms` is untouched, `essentials.offices` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--     95 candidacies across 53 races
--     52 won · 41 lost · 2 with NO result (1 race(s) AP has not called)
--     43 linked to a politician we already hold; the rest carry politician_id NULL
--      0 declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
--    The uncalled race(s) here:
--      Assembly District 22 (AP race 20261103NV35, Too Early to Call)
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read 2026-11-13:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/NV/
-- and the Secretary of State's own results feed behind silverstateelection.nv.gov,
-- read 2026-11-13 with Playwright:
--   https://silverstateelection.nv.gov/
--
-- The join, the differences and how each one was settled are in
-- `backend/data/state-leg-2026-seed/` — `nv-crosscheck-2026-11-13.json` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (`CC_0408`-`CC_0411`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. 14 of these 53 races are uncontested and 14 of the 95 rows carry a
-- published count of zero. We store no vote counts in any column, so the only place a count
-- could reach production is the citation text — and it does not. Where AP publishes a count the
-- citation names the SHARE it reported; where AP publishes none it says so.
--
-- ============================================================================================
-- THE KEY OF A CANDIDACY IS THE PAIR (AP RACE, AP CANDIDATE)
-- ============================================================================================
-- `external_id` reads `ap-2026-11-03-<AP race>-<AP candidate>`. ⚠ `CC_0413` and `CC_0414`
-- (Massachusetts and Maine, already applied) used the candidate id alone, and this file does
-- not, for a reason found in Maryland:
--
-- 🔴 A PUBLISHED CANDIDATE ID IS NOT A PERSON. Maryland's file carries one AP id used for two
--    different people in two districts, so the pair is the only safe key; this state has no
--    such collision, and the key is the same shape anyway rather than per-state.
--
-- ============================================================================================
-- HOW A CANDIDACY IS LINKED TO A PERSON WE ALREADY HOLD
-- ============================================================================================
-- ⚠ Most of these people are not in `essentials.politicians` at all, and SEEDING A PERSON IS A
--    SEPARATE ACT. A challenger therefore gets a candidacy with `politician_id` NULL, which is
--    the normal shape for a candidate here.
--
-- An incumbent is different, and the link rests on TWO FACTS, NEITHER OF THEM A NAME: AP flags
-- the ballot line as that seat's incumbent, and `essentials.office_current_holder`
-- independently names the politician holding that same office. That is `CC_0381`'s `holder`
-- basis. The name is then a CHECK on the pair, not the key, and each outcome is named:
--   holder-exact-full-name      31
--   holder-initial-in-first-name-field   6
--   holder-exact-first-last      3
--   holder-compound-surname      1
--   holder-surname-plus-roster   2
--
-- 🔴 A SURNAME DISAGREEMENT IS A FINDING AND IS NOT LINKED. Nothing in this file links a
--    candidacy to a politician whose surname differs from AP's — such a row is seeded with
--    politician_id NULL and reported instead.
--
-- 🔴 AND THE LINK IS RE-ASSERTED AGAINST PRODUCTION, NOT TRUSTED FROM THIS FILE. The pre-check
--    below refuses unless every politician this file names is still the current holder of that
--    race's office at the moment the migration runs.
--
-- ============================================================================================
-- Slot CC_0417 reserved via steward. Applied to production 2026-11-13 by Chris Cantrell.
-- ============================================================================================

BEGIN;

-- ─── 1. What is seeded ───
CREATE TEMP TABLE seed (
  race_id          uuid NOT NULL,
  office_id        uuid NOT NULL,
  district         text NOT NULL,
  office_title     text NOT NULL,
  seats            int  NOT NULL,
  ap_race_id       text NOT NULL,
  ap_candidate_id  text NOT NULL,
  full_name        text NOT NULL,
  first_name       text,
  last_name        text,
  is_write_in      boolean NOT NULL,
  ap_incumbent     boolean NOT NULL,
  party            text,            -- recorded here for the record ONLY: party in this repo
                                    -- lives on races.primary_party, never on a candidacy
  votes            int  NOT NULL,   -- for the gates below; NEVER written to any column
  pct              numeric NOT NULL,
  uncontested      boolean NOT NULL,
  called           boolean NOT NULL,
  outcome          text,            -- 'won' | 'lost' | NULL when AP has not called the race
  holder_id        uuid,            -- the politician to link, or NULL
  holder_basis     text,
  holder_name      text,
  PRIMARY KEY (ap_race_id, ap_candidate_id)   -- the candidacy, not the person: see the header
);

INSERT INTO seed VALUES
  ('c16d6f80-6c61-4c0a-b7e4-d2eb1a90b1ed', '5db8fa64-01ce-44d2-ac0b-5d9c8960a04b', 'Assembly District 42', 'Assemblymember', 1, '20261103NV39', '172849', 'Christopher Brandlin', 'Christopher', 'Brandlin', false, false, 'GOP', 7438, 35.3, false, true, 'lost', NULL, NULL, NULL),
  ('c16d6f80-6c61-4c0a-b7e4-d2eb1a90b1ed', '5db8fa64-01ce-44d2-ac0b-5d9c8960a04b', 'Assembly District 42', 'Assemblymember', 1, '20261103NV39', '132836', 'Tracy Brown-May', 'Tracy', 'Brown-May', false, true, 'Dem', 13630, 64.7, false, true, 'won', '190de314-e976-4df7-bad9-b3cdc0f2d887'::uuid, 'holder-exact-full-name', 'Tracy Brown-May'),
  ('40cb2464-3147-4597-a269-9b36604bf74e', 'b86066ac-2856-404f-97b4-a0819b388765', 'Assembly District 1', 'Assemblymember', 1, '20261103NV14', '172411', 'Alexis Elizabeth Esparza', 'Alexis', 'Esparza', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('378b59db-23b6-46d7-ab10-fd53f0355a90', 'fdd01e46-03b4-494c-9eef-ff5ce11d8c6a', 'Assembly District 2', 'Assemblymember', 1, '20261103NV15', '172413', 'Kamilah Bywaters', 'Kamilah', 'Bywaters', false, false, 'Dem', 15517, 52.5, false, true, 'won', NULL, NULL, NULL),
  ('378b59db-23b6-46d7-ab10-fd53f0355a90', 'fdd01e46-03b4-494c-9eef-ff5ce11d8c6a', 'Assembly District 2', 'Assemblymember', 1, '20261103NV15', '172415', 'Drew Teitelbaum', 'Drew', 'Teitelbaum', false, false, 'GOP', 14038, 47.5, false, true, 'lost', NULL, NULL, NULL),
  ('067f4550-5603-4948-a6d4-a36ad3c4774b', '55d9dd70-bea2-48e4-87df-98efd96b8946', 'Assembly District 3', 'Assemblymember', 1, '20261103NV16', '51349', 'Joseph P. Silvestri', 'Joseph', 'Silvestri', false, false, 'GOP', 6977, 35.19, false, true, 'lost', NULL, NULL, NULL),
  ('067f4550-5603-4948-a6d4-a36ad3c4774b', '55d9dd70-bea2-48e4-87df-98efd96b8946', 'Assembly District 3', 'Assemblymember', 1, '20261103NV16', '132489', 'Selena Torres-Fossett', 'Selena', 'Torres-Fossett', false, true, 'Dem', 12848, 64.81, false, true, 'won', '0f31ccad-c79c-43cb-bb06-9392b9b2c908'::uuid, 'holder-exact-full-name', 'Selena Torres-Fossett'),
  ('42bf3dd6-8389-4cb2-8a56-a524a9b388c7', 'b83c9282-c492-4e70-9d3a-22fd88c3f8a9', 'Assembly District 4', 'Assemblymember', 1, '20261103NV17', '164443', 'Lisa Cole', 'Lisa', 'Cole', false, true, 'GOP', 13661, 46.71, false, true, 'lost', 'b9f1ab35-5fb3-4177-80c2-29fd388b77a9'::uuid, 'holder-initial-in-first-name-field', 'Lisa K. Cole'),
  ('42bf3dd6-8389-4cb2-8a56-a524a9b388c7', 'b83c9282-c492-4e70-9d3a-22fd88c3f8a9', 'Assembly District 4', 'Assemblymember', 1, '20261103NV17', '172793', 'Eileen Eady', 'Eileen', 'Eady', false, false, 'Dem', 15586, 53.29, false, true, 'won', NULL, NULL, NULL),
  ('231267ba-2e57-4e9e-a133-af49bfbc0ea7', '47c390b1-7d52-4357-a5d5-bd4a21e73388', 'Assembly District 5', 'Assemblymember', 1, '20261103NV18', '132308', 'Brittney M. Miller', 'Brittney', 'Miller', false, true, 'Dem', 14032, 60.92, false, true, 'won', 'bc0a9215-e2dc-46a2-b325-80d90281847d'::uuid, 'holder-exact-full-name', 'Brittney M. Miller'),
  ('231267ba-2e57-4e9e-a133-af49bfbc0ea7', '47c390b1-7d52-4357-a5d5-bd4a21e73388', 'Assembly District 5', 'Assemblymember', 1, '20261103NV18', '132787', 'Kelly Quinn', 'Kelly', 'Quinn', false, false, 'GOP', 9000, 39.08, false, true, 'lost', NULL, NULL, NULL),
  ('49eac985-5ff8-4d43-90fa-0ce2c122a83f', '24934c73-a0f0-49b8-89bc-7d3be6b0ac42', 'Assembly District 6', 'Assemblymember', 1, '20261103NV19', '132669', 'Katherine Duncan', 'Katherine', 'Duncan', false, false, 'NPA', 1820, 13.9, false, true, 'lost', NULL, NULL, NULL),
  ('49eac985-5ff8-4d43-90fa-0ce2c122a83f', '24934c73-a0f0-49b8-89bc-7d3be6b0ac42', 'Assembly District 6', 'Assemblymember', 1, '20261103NV19', '164445', 'Jovan Alexander Jackson', 'Jovan', 'Jackson', false, true, 'Dem', 11277, 86.1, false, true, 'won', 'b61f2aa3-62c2-41fb-a8e9-a0589a8ee005'::uuid, 'holder-initial-in-first-name-field', 'Jovan A. Jackson'),
  ('8e4181d9-cf98-4c7b-bc59-ac142eecd5c6', '1e8cf3e9-619e-4dfe-bbb8-3bfa68acee2f', 'Assembly District 7', 'Assemblymember', 1, '20261103NV20', '132672', 'Cameron Miller', 'Cameron', 'Miller', false, false, 'Dem', 15948, 81.21, false, true, 'won', NULL, NULL, NULL),
  ('8e4181d9-cf98-4c7b-bc59-ac142eecd5c6', '1e8cf3e9-619e-4dfe-bbb8-3bfa68acee2f', 'Assembly District 7', 'Assemblymember', 1, '20261103NV20', '177939', 'Anthony Scott Willett', 'Anthony', 'Willett', false, false, 'Lib', 3691, 18.79, false, true, 'lost', NULL, NULL, NULL),
  ('0ca40fad-8d8f-45de-9eac-dcc5f0958fbb', 'a58f04e5-bdfa-485d-9271-28b7a3bc7b89', 'Assembly District 8', 'Assemblymember', 1, '20261103NV21', '172796', 'Joseph Charafi', 'Joseph', 'Charafi', false, false, 'GOP', 8567, 33.45, false, true, 'lost', NULL, NULL, NULL),
  ('0ca40fad-8d8f-45de-9eac-dcc5f0958fbb', 'a58f04e5-bdfa-485d-9271-28b7a3bc7b89', 'Assembly District 8', 'Assemblymember', 1, '20261103NV21', '132789', 'Duy Nguyen', 'Duy', 'Nguyen', false, true, 'Dem', 17047, 66.55, false, true, 'won', 'd2c7f3e5-d0c9-40d1-8527-49f2e41e015b'::uuid, 'holder-exact-full-name', 'Duy Nguyen'),
  ('a84aa685-74af-4ca0-b02c-bd06389da1bc', '211e3941-ef3e-43dc-ba84-daa06750556f', 'Assembly District 9', 'Assemblymember', 1, '20261103NV22', '164442', 'Ryan Hampton', 'Ryan', 'Hampton', false, false, 'Dem', 15518, 60.97, false, true, 'won', NULL, NULL, NULL),
  ('a84aa685-74af-4ca0-b02c-bd06389da1bc', '211e3941-ef3e-43dc-ba84-daa06750556f', 'Assembly District 9', 'Assemblymember', 1, '20261103NV22', '164453', 'Erica Alejandra Neely', 'Erica', 'Neely', false, false, 'GOP', 9935, 39.03, false, true, 'lost', NULL, NULL, NULL),
  ('8870760a-779b-4b15-a49f-781c2b76d1e0', 'fe876f84-cfc0-41d4-a71f-aa7d5a9de6ab', 'Assembly District 10', 'Assemblymember', 1, '20261103NV23', '164455', 'Venise L. Karris', 'Venise', 'Karris', false, true, 'Dem', 0, 0, true, true, 'won', 'aa172507-de77-4525-a765-220237c1a9be'::uuid, 'holder-exact-first-last', 'Venise Karris'),
  ('c2ae5355-65b6-46fb-ad9d-fef31e15b974', '8babef51-2c83-404c-ab4d-11f0edd4cbf5', 'Assembly District 11', 'Assemblymember', 1, '20261103NV24', '132515', 'Cinthia Moore', 'Cinthia', 'Moore', false, true, 'Dem', 0, 0, true, true, 'won', '1a9f683e-4ead-49fe-b6b3-30d6379738d4'::uuid, 'holder-compound-surname', 'Cinthia Zermeño Moore'),
  ('ed62feb0-edb7-4316-873f-060c074ccb7d', '01e49376-2894-4763-9d41-545b0f50229c', 'Assembly District 12', 'Assemblymember', 1, '20261103NV25', '132796', 'Max Carter II', 'Max', 'Carter', false, true, 'Dem', 15014, 61.23, false, true, 'won', '32278145-a538-4cb7-8a2e-d0a571e2b0b5'::uuid, 'holder-initial-in-first-name-field', 'Max E. Carter II'),
  ('ed62feb0-edb7-4316-873f-060c074ccb7d', '01e49376-2894-4763-9d41-545b0f50229c', 'Assembly District 12', 'Assemblymember', 1, '20261103NV25', '164462', 'Nancy Roecker', 'Nancy', 'Roecker', false, false, 'GOP', 9507, 38.77, false, true, 'lost', NULL, NULL, NULL),
  ('346717c8-a8b4-4767-be0b-7da29291e5d3', '8c332f48-e372-4dc7-aacf-77fb32fc1e0b', 'Assembly District 13', 'Assemblymember', 1, '20261103NV26', '132801', 'Daniel Andrews', 'Daniel', 'Andrews', false, false, 'Dem', 16522, 53.01, false, true, 'won', NULL, NULL, NULL),
  ('346717c8-a8b4-4767-be0b-7da29291e5d3', '8c332f48-e372-4dc7-aacf-77fb32fc1e0b', 'Assembly District 13', 'Assemblymember', 1, '20261103NV26', '177940', 'Gage C. Beck', 'Gage', 'Beck', false, false, 'Lib', 505, 1.62, false, true, 'lost', NULL, NULL, NULL),
  ('346717c8-a8b4-4767-be0b-7da29291e5d3', '8c332f48-e372-4dc7-aacf-77fb32fc1e0b', 'Assembly District 13', 'Assemblymember', 1, '20261103NV26', '132804', 'Brian Hibbetts', 'Brian', 'Hibbetts', false, true, 'GOP', 14140, 45.37, false, true, 'lost', '55370ca6-5c1a-4ab4-9a75-3ee266ec3d53'::uuid, 'holder-exact-full-name', 'Brian Hibbetts'),
  ('a21c3749-3b0e-45d6-9ec0-7ca99064413f', '230ff3cc-afb1-4312-8453-5df9c6140fa6', 'Assembly District 14', 'Assemblymember', 1, '20261103NV27', '132328', 'Erica Mosca', 'Erica', 'Mosca', false, true, 'Dem', 0, 0, true, true, 'won', '80bf7387-2917-464f-a9e1-58d136fa2b0b'::uuid, 'holder-exact-full-name', 'Erica Mosca'),
  ('2ce03824-e04e-496f-a708-0aa3d97e8e7e', '5ea69a06-2f2e-4ccf-9162-a0b547d2aea8', 'Assembly District 15', 'Assemblymember', 1, '20261103NV28', '172800', 'Miguel Davila', 'Miguel', 'Davila', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('bc9b026a-fb04-4254-9e3a-8a548c108860', '14b8ec20-67d2-45db-bd47-46b7520ec9ae', 'Assembly District 16', 'Assemblymember', 1, '20261103NV31101', '172801', 'John Carlo', 'John', 'Carlo', false, false, 'GOP', 6813, 36.89, false, true, 'lost', NULL, NULL, NULL),
  ('bc9b026a-fb04-4254-9e3a-8a548c108860', '14b8ec20-67d2-45db-bd47-46b7520ec9ae', 'Assembly District 16', 'Assemblymember', 1, '20261103NV31101', '132685', 'Cecelia González', 'Cecelia', 'González', false, true, 'Dem', 11654, 63.11, false, true, 'won', '4e31c709-96b4-4938-b01f-d8ba4ff474c8'::uuid, 'holder-exact-full-name', 'Cecelia González'),
  ('8d648693-1e97-421b-9e3e-cfccb43a73d6', '0a9838f4-19f3-417c-9a43-e7bd218c9ba0', 'Assembly District 17', 'Assemblymember', 1, '20261103NV30', '164472', 'Linda F. Hunt', 'Linda', 'Hunt', false, true, 'Dem', 0, 0, true, true, 'won', 'f59700c8-d453-425a-b3f9-f1189d87a976'::uuid, 'holder-exact-full-name', 'Linda F. Hunt'),
  ('e646ad94-71cc-49e5-a7bd-d0c8130c2ef8', '9d404f22-40f6-4da6-9c2d-1a33721f4cb6', 'Assembly District 18', 'Assemblymember', 1, '20261103NV31', '132693', 'Venicia Considine', 'Venicia', 'Considine', false, true, 'Dem', 14105, 70.1, false, true, 'won', 'c7fe9357-446f-4998-816a-dbfdd8b319ef'::uuid, 'holder-exact-full-name', 'Venicia Considine'),
  ('e646ad94-71cc-49e5-a7bd-d0c8130c2ef8', '9d404f22-40f6-4da6-9c2d-1a33721f4cb6', 'Assembly District 18', 'Assemblymember', 1, '20261103NV31', '172803', 'Crystal Newton', 'Crystal', 'Newton', false, false, 'GOP', 6015, 29.9, false, true, 'lost', NULL, NULL, NULL),
  ('7f6054f5-aac5-465e-be52-d33717de9aeb', '3106a3ab-19b8-4e0c-9482-25c384d25e8b', 'Assembly District 19', 'Assemblymember', 1, '20261103NV31066', '177941', 'Zackaraih Lysaght', 'Zackaraih', 'Lysaght', false, false, 'Lib', 9940, 31.79, false, true, 'lost', NULL, NULL, NULL),
  ('7f6054f5-aac5-465e-be52-d33717de9aeb', '3106a3ab-19b8-4e0c-9482-25c384d25e8b', 'Assembly District 19', 'Assemblymember', 1, '20261103NV31066', '172815', 'Jason Patchett', 'Jason', 'Patchett', false, true, 'GOP', 21327, 68.21, false, true, 'won', '11602abe-4866-483f-bcf6-1473de7d4e7d'::uuid, 'holder-exact-full-name', 'Jason Patchett'),
  ('efa8e037-63ec-49c9-8ca5-26c089350c4f', '01f2be3f-2f49-49f0-b599-e844b465e5bb', 'Assembly District 20', 'Assemblymember', 1, '20261103NV33', '132486', 'David Orentlicher', 'David', 'Orentlicher', false, true, 'Dem', 12185, 75.1, false, true, 'won', '90572ea8-acf1-4896-8b3d-8efdbd26ad58'::uuid, 'holder-exact-full-name', 'David Orentlicher'),
  ('efa8e037-63ec-49c9-8ca5-26c089350c4f', '01f2be3f-2f49-49f0-b599-e844b465e5bb', 'Assembly District 20', 'Assemblymember', 1, '20261103NV33', '62352', 'Stan Vaughan', 'Stan', 'Vaughan', false, false, 'IAP', 4041, 24.9, false, true, 'lost', NULL, NULL, NULL),
  ('628fd769-aadd-46c2-a676-23ebee55accf', '8e31ef18-850d-451a-8deb-772489ed5eb1', 'Assembly District 21', 'Assemblymember', 1, '20261103NV34', '172821', 'Patsy A. Carvalho', 'Patsy', 'Carvalho', false, false, 'GOP', 10390, 39.11, false, true, 'lost', NULL, NULL, NULL),
  ('628fd769-aadd-46c2-a676-23ebee55accf', '8e31ef18-850d-451a-8deb-772489ed5eb1', 'Assembly District 21', 'Assemblymember', 1, '20261103NV34', '177942', 'Tighe Galvin', 'Tighe', 'Galvin', false, false, 'Lib', 567, 2.13, false, true, 'lost', NULL, NULL, NULL),
  ('628fd769-aadd-46c2-a676-23ebee55accf', '8e31ef18-850d-451a-8deb-772489ed5eb1', 'Assembly District 21', 'Assemblymember', 1, '20261103NV34', '132707', 'Elaine Marzola', 'Elaine', 'Marzola', false, true, 'Dem', 15607, 58.75, false, true, 'won', '10957d22-c1ca-4a44-bddb-5bd606b12b76'::uuid, 'holder-initial-in-first-name-field', 'Elaine H. Marzola'),
  ('477dfa52-e65c-4d77-b63a-0bda52b4e122', 'df4bfebc-ed84-4c03-b62f-22eee8fbe09a', 'Assembly District 22', 'Assemblymember', 1, '20261103NV35', '172822', 'Shenea Booth', 'Shenea', 'Booth', false, false, 'Dem', 17273, 50.11, false, false, NULL, NULL, NULL, NULL),
  ('477dfa52-e65c-4d77-b63a-0bda52b4e122', 'df4bfebc-ed84-4c03-b62f-22eee8fbe09a', 'Assembly District 22', 'Assemblymember', 1, '20261103NV35', '132528', 'Melissa Hardy', 'Melissa', 'Hardy', false, true, 'GOP', 17196, 49.89, false, false, NULL, '02fa5b8b-2be7-4c5c-ae0b-ae01963625d1'::uuid, 'holder-initial-in-first-name-field', 'Melissa R. Hardy'),
  ('ce94ad22-b799-490a-8fa2-7b23ff8749f6', 'd9caa623-92e8-4a55-9b0a-9a868aa9d1bd', 'Assembly District 23', 'Assemblymember', 1, '20261103NV36', '172825', 'Jan Allen Aspelund', 'Jan', 'Aspelund', false, false, 'Dem', 17756, 45.12, false, true, 'lost', NULL, NULL, NULL),
  ('ce94ad22-b799-490a-8fa2-7b23ff8749f6', 'd9caa623-92e8-4a55-9b0a-9a868aa9d1bd', 'Assembly District 23', 'Assemblymember', 1, '20261103NV36', '172826', 'Denise Daniels Fanning', 'Denise', 'Fanning', false, false, 'GOP', 21598, 54.88, false, true, 'won', NULL, NULL, NULL),
  ('630b4f26-f4c0-498e-9a67-d72cd226a577', '1b49d843-865a-4a1c-b30b-85ea5f4a678d', 'Assembly District 24', 'Assemblymember', 1, '20261103NV29676', '164488', 'Erica Roth', 'Erica', 'Roth', false, true, 'Dem', 0, 0, true, true, 'won', '0181ed7a-410b-4dfe-b0ea-411ffd0f5720'::uuid, 'holder-initial-in-first-name-field', 'Erica P. Roth'),
  ('917c218c-2a24-4825-82f2-86f26e3005f9', '17cb5435-ac42-4215-aa44-5ef4e757e700', 'Assembly District 25', 'Assemblymember', 1, '20261103NV29677', '164486', 'Michael A. Ginsburg', 'Michael', 'Ginsburg', false, false, 'GOP', 13790, 40.64, false, true, 'lost', NULL, NULL, NULL),
  ('917c218c-2a24-4825-82f2-86f26e3005f9', '17cb5435-ac42-4215-aa44-5ef4e757e700', 'Assembly District 25', 'Assemblymember', 1, '20261103NV29677', '132853', 'Selena La Rue Hatch', 'Selena', 'La Rue Hatch', false, true, 'Dem', 20141, 59.36, false, true, 'won', '086ad172-94bb-4460-8984-4f5b7fa4d2a5'::uuid, 'holder-exact-full-name', 'Selena La Rue Hatch'),
  ('54c19c84-5817-48f1-87b8-396914962801', 'aae36b3e-b5bc-466b-8aee-a6ca9177d570', 'Assembly District 26', 'Assemblymember', 1, '20261103NV29678', '172829', 'Sam Baugh', 'Sam', 'Baugh', false, false, 'Dem', 19247, 47.63, false, true, 'lost', NULL, NULL, NULL),
  ('54c19c84-5817-48f1-87b8-396914962801', 'aae36b3e-b5bc-466b-8aee-a6ca9177d570', 'Assembly District 26', 'Assemblymember', 1, '20261103NV29678', '132857', 'Richard DeLong', 'Richard', 'DeLong', false, true, 'GOP', 21161, 52.37, false, true, 'won', 'b1499860-79d4-43b3-878c-def5f28037d8'::uuid, 'holder-surname-plus-roster', 'Rich DeLong'),
  ('715b47e8-9120-42f9-b90f-22e7c2701c23', '8bf5e3ae-a659-42b2-9061-52b5cea4e646', 'Assembly District 27', 'Assemblymember', 1, '20261103NV29679', '172830', 'Veronica Cortes', 'Veronica', 'Cortes', false, false, 'GOP', 7953, 32.69, false, true, 'lost', NULL, NULL, NULL),
  ('715b47e8-9120-42f9-b90f-22e7c2701c23', '8bf5e3ae-a659-42b2-9061-52b5cea4e646', 'Assembly District 27', 'Assemblymember', 1, '20261103NV29679', '164493', 'Heather Goulding', 'Heather', 'Goulding', false, true, 'Dem', 16372, 67.31, false, true, 'won', '74f07f06-747c-4e6a-adf3-68133bd2ccbc'::uuid, 'holder-exact-full-name', 'Heather Goulding'),
  ('e13d4c0e-1490-4cb5-b5e8-d4a8104ce18c', 'daf378ea-e0ce-465f-98c7-38446a84d2c6', 'Assembly District 28', 'Assemblymember', 1, '20261103NV37', '164477', 'Reuben D''Silva', 'Reuben', 'D''Silva', false, true, 'Dem', 0, 0, true, true, 'won', '3af59cfd-8cd6-4fc3-8c8c-82b07a10af69'::uuid, 'holder-exact-full-name', 'Reuben D''Silva'),
  ('3d5d6cbd-f194-47a7-8934-4cc23f2aa8f8', '4739e270-01dc-46ca-bfda-72a3abf48bbb', 'Assembly District 29', 'Assemblymember', 1, '20261103NV29681', '172834', 'Joe Ludwig', 'Joe', 'Ludwig', false, false, 'GOP', 9308, 38.59, false, true, 'lost', NULL, NULL, NULL),
  ('3d5d6cbd-f194-47a7-8934-4cc23f2aa8f8', '4739e270-01dc-46ca-bfda-72a3abf48bbb', 'Assembly District 29', 'Assemblymember', 1, '20261103NV29681', '172833', 'Alex J. Pereszlenyi', 'Alex', 'Pereszlenyi', false, false, 'Dem', 14810, 61.41, false, true, 'won', NULL, NULL, NULL),
  ('94a2773c-e36a-4ad1-a07b-2379ee784e9c', '056b9f88-1b91-49b3-ae6d-11e4dae9fdf8', 'Assembly District 30', 'Assemblymember', 1, '20261103NV29682', '132719', 'Natha C. Anderson', 'Natha', 'Anderson', false, true, 'Dem', 13347, 66.22, false, true, 'won', '4e6d26a0-747c-4ccd-8f83-384732c0f34a'::uuid, 'holder-exact-full-name', 'Natha C. Anderson'),
  ('94a2773c-e36a-4ad1-a07b-2379ee784e9c', '056b9f88-1b91-49b3-ae6d-11e4dae9fdf8', 'Assembly District 30', 'Assemblymember', 1, '20261103NV29682', '164605', 'Trista Gomez', 'Trista', 'Gomez', false, false, 'GOP', 6808, 33.78, false, true, 'lost', NULL, NULL, NULL),
  ('ced3bff9-cb7b-4eb5-bf94-5743d7a0aeca', 'a0b23039-a5d2-4d71-bd89-7249ed57ae1b', 'Assembly District 31', 'Assemblymember', 1, '20261103NV29683', '132172', 'Jill Dickman', 'Jill', 'Dickman', false, true, 'GOP', 18513, 51.33, false, true, 'won', '7c364920-62ba-4ae8-b982-739656b58f51'::uuid, 'holder-exact-full-name', 'Jill Dickman'),
  ('ced3bff9-cb7b-4eb5-bf94-5743d7a0aeca', 'a0b23039-a5d2-4d71-bd89-7249ed57ae1b', 'Assembly District 31', 'Assemblymember', 1, '20261103NV29683', '172835', 'Neal Schwartz', 'Neal', 'Schwartz', false, false, 'Dem', 17554, 48.67, false, true, 'lost', NULL, NULL, NULL),
  ('19b6908d-5278-489a-aac0-647eb4e0fd86', '9c69910f-e982-40e9-8e82-a97f62a434c0', 'Assembly District 32', 'Assemblymember', 1, '20261103NV29684', '132455', 'Alexis M. Hansen', 'Alexis', 'Hansen', false, true, 'GOP', 0, 0, true, true, 'won', 'ed5a5666-f5de-4b3e-aac9-34dca26eeb38'::uuid, 'holder-exact-full-name', 'Alexis M. Hansen'),
  ('d15767bd-3339-467c-8bc1-8177b8bf4649', 'ae44469e-0f03-448d-b561-cc122db5cb9d', 'Assembly District 33', 'Assemblymember', 1, '20261103NV29685', '132839', 'Bert K. Gurr', 'Bert', 'Gurr', false, true, 'GOP', 0, 0, true, true, 'won', '9dc6edd9-7406-476c-82b7-bee3f2865bcc'::uuid, 'holder-exact-full-name', 'Bert K. Gurr'),
  ('4bd2b5ef-f938-4bd3-83c9-3875997d0387', '56015e46-eb4a-4ef5-b673-add40fcdcd92', 'Assembly District 34', 'Assemblymember', 1, '20261103NV30165', '71708', 'Brandon Davis', 'Brandon', 'Davis', false, false, 'GOP', 8370, 37, false, true, 'lost', NULL, NULL, NULL),
  ('4bd2b5ef-f938-4bd3-83c9-3875997d0387', '56015e46-eb4a-4ef5-b673-add40fcdcd92', 'Assembly District 34', 'Assemblymember', 1, '20261103NV30165', '164480', 'Hanadi Nadeem', 'Hanadi', 'Nadeem', false, true, 'Dem', 14251, 63, false, true, 'won', '55db18bd-c4ed-487a-a5cf-6b672e5376b5'::uuid, 'holder-exact-full-name', 'Hanadi Nadeem'),
  ('333843ed-113c-4a08-aa58-3131c43c36df', '78273ecf-398a-4c99-861b-cc820bd5a6c3', 'Assembly District 35', 'Assemblymember', 1, '20261103NV29687', '164483', 'Rebecca Edgeworth', 'Rebecca', 'Edgeworth', false, true, 'GOP', 11718, 41.47, false, true, 'lost', '6a42f3ff-5ac8-40ff-a0ea-9b18e626c9aa'::uuid, 'holder-exact-full-name', 'Rebecca Edgeworth'),
  ('333843ed-113c-4a08-aa58-3131c43c36df', '78273ecf-398a-4c99-861b-cc820bd5a6c3', 'Assembly District 35', 'Assemblymember', 1, '20261103NV29687', '172837', 'Joe Spica', 'Joe', 'Spica', false, false, 'Dem', 16536, 58.53, false, true, 'won', NULL, NULL, NULL),
  ('7b36d6a6-57cd-4d09-b0a2-4282a58260bd', '637083a8-d941-4fac-99e6-2c37fbff36a4', 'Assembly District 36', 'Assemblymember', 1, '20261103NV29688', '132641', 'Gregory T. Hafen II', 'Gregory', 'Hafen', false, true, 'GOP', 21567, 56.72, false, true, 'won', '1172767a-6b61-44e7-a372-8455711046bc'::uuid, 'holder-exact-full-name', 'Gregory T. Hafen II'),
  ('7b36d6a6-57cd-4d09-b0a2-4282a58260bd', '637083a8-d941-4fac-99e6-2c37fbff36a4', 'Assembly District 36', 'Assemblymember', 1, '20261103NV29688', '172838', 'Jon Penn Junejo', 'Jon', 'Junejo', false, false, 'Dem', 16458, 43.28, false, true, 'lost', NULL, NULL, NULL),
  ('a763b662-cec6-478d-8ad1-4c0b73beedc3', '1db8848b-04c9-42aa-b9ac-ecf1138b5af4', 'Assembly District 37', 'Assemblymember', 1, '20261103NV29689', '132534', 'Shea M. Backus', 'Shea', 'Backus', false, true, 'Dem', 17956, 57.52, false, true, 'won', '06693066-c852-424f-b3f5-925edee51743'::uuid, 'holder-exact-full-name', 'Shea M. Backus'),
  ('a763b662-cec6-478d-8ad1-4c0b73beedc3', '1db8848b-04c9-42aa-b9ac-ecf1138b5af4', 'Assembly District 37', 'Assemblymember', 1, '20261103NV29689', '164433', 'Jill M. Douglass', 'Jill', 'Douglass', false, false, 'GOP', 13263, 42.48, false, true, 'lost', NULL, NULL, NULL),
  ('a20935f2-35a8-4e82-92d6-ddfd6e8cbfb2', '7cd2229f-5faa-4a9d-917c-917e00f73413', 'Assembly District 38', 'Assemblymember', 1, '20261103NV29690', '132842', 'Gregory S. Koenig', 'Gregory', 'Koenig', false, true, 'GOP', 0, 0, true, true, 'won', '36cba838-66a0-497c-a0c9-56f6f917f6c7'::uuid, 'holder-exact-full-name', 'Gregory S. Koenig'),
  ('291d0175-44d7-4b5b-9935-474cad0f909b', '8b46228f-7675-4a15-87a2-657a38261714', 'Assembly District 39', 'Assemblymember', 1, '20261103NV29691', '164422', 'Erich Obermayr', 'Erich', 'Obermayr', false, false, 'Dem', 12977, 32.99, false, true, 'lost', NULL, NULL, NULL),
  ('291d0175-44d7-4b5b-9935-474cad0f909b', '8b46228f-7675-4a15-87a2-657a38261714', 'Assembly District 39', 'Assemblymember', 1, '20261103NV29691', '132845', 'Blayne Osborn', 'Blayne', 'Osborn', false, true, 'GOP', 26354, 67.01, false, true, 'won', '5d544706-96b9-4eb6-8a45-1294d909f113'::uuid, 'holder-exact-full-name', 'Blayne Osborn'),
  ('f7d20314-cffc-44d3-9db8-40a882e48f75', '9c57c7bb-9d58-4ee9-9b27-81870e159cef', 'Assembly District 40', 'Assemblymember', 1, '20261103NV29692', '172842', 'Julie A. Butler', 'Julie', 'Butler', false, false, 'GOP', 18308, 54.69, false, true, 'won', NULL, NULL, NULL),
  ('f7d20314-cffc-44d3-9db8-40a882e48f75', '9c57c7bb-9d58-4ee9-9b27-81870e159cef', 'Assembly District 40', 'Assemblymember', 1, '20261103NV29692', '172841', 'Oscar Fuentes', 'Oscar', 'Fuentes', false, false, 'Dem', 15169, 45.31, false, true, 'lost', NULL, NULL, NULL),
  ('91988406-6ce8-4ae8-8562-c0625b511c65', 'c2fd147e-f146-4f8f-8c78-0caf74aaa3e9', 'Assembly District 41', 'Assemblymember', 1, '20261103NV38', '164449', 'Kelly Chapman', 'Kelly', 'Chapman', false, false, 'GOP', 10158, 40.05, false, true, 'lost', NULL, NULL, NULL),
  ('91988406-6ce8-4ae8-8562-c0625b511c65', 'c2fd147e-f146-4f8f-8c78-0caf74aaa3e9', 'Assembly District 41', 'Assemblymember', 1, '20261103NV38', '132336', 'Vinny Spotleson', 'Vinny', 'Spotleson', false, false, 'Dem', 15207, 59.95, false, true, 'won', NULL, NULL, NULL),
  ('b82202d5-03aa-4df0-b366-1257f2026da8', '67aa3eb2-c063-41d4-88c8-beed59109b4a', 'State Senate District 21', 'State Senator', 1, '20261103NV31011', '131723', 'James Ohrenschall', 'James', 'Ohrenschall', false, true, 'Dem', 25832, 66.17, false, true, 'won', '3a17cd52-2112-453f-9fbe-0799235072a6'::uuid, 'holder-exact-full-name', 'James Ohrenschall'),
  ('b82202d5-03aa-4df0-b366-1257f2026da8', '67aa3eb2-c063-41d4-88c8-beed59109b4a', 'State Senate District 21', 'State Senator', 1, '20261103NV31011', '132800', 'Al Rojas', 'Al', 'Rojas', false, false, 'GOP', 13207, 33.83, false, true, 'lost', NULL, NULL, NULL),
  ('e87a25f4-536d-433d-8a30-b26faea4d8a6', '75e754bb-48c4-4224-a252-0694a1f7176a', 'State Senate District 20', 'State Senator', 1, '20261103NV31010', '132819', 'Danielle Gallant', 'Danielle', 'Gallant', false, false, 'GOP', 41643, 56.42, false, true, 'won', NULL, NULL, NULL),
  ('e87a25f4-536d-433d-8a30-b26faea4d8a6', '75e754bb-48c4-4224-a252-0694a1f7176a', 'State Senate District 20', 'State Senator', 1, '20261103NV31010', '172409', 'Calvin Sandoval', 'Calvin', 'Sandoval', false, false, 'Dem', 32164, 43.58, false, true, 'lost', NULL, NULL, NULL),
  ('52c982b7-99c3-496c-a516-8d11f2c73158', '3d2448f7-2fab-49ae-b70e-53651c1e4924', 'State Senate District 17', 'State Senator', 1, '20261103NV31087', '172408', 'Lynne Ballatore', 'Lynne', 'Ballatore', false, false, 'Dem', 20482, 31.14, false, true, 'lost', NULL, NULL, NULL),
  ('52c982b7-99c3-496c-a516-8d11f2c73158', '3d2448f7-2fab-49ae-b70e-53651c1e4924', 'State Senate District 17', 'State Senator', 1, '20261103NV31087', '132163', 'Robin L. Titus', 'Robin', 'Titus', false, true, 'GOP', 45298, 68.86, false, true, 'won', 'c177ae7c-9da4-4ae4-9704-3fc9004427f2'::uuid, 'holder-exact-full-name', 'Robin L. Titus'),
  ('90df3a98-e17c-4271-923b-f000adc47a03', '485829e4-49c6-48c6-a079-54d7b0ffb61a', 'State Senate District 16', 'State Senator', 1, '20261103NV31012', '132203', 'Lisa Krasner', 'Lisa', 'Krasner', false, true, 'GOP', 40072, 53.96, false, true, 'won', 'c68dd099-1804-45bf-a1da-2cffba356e78'::uuid, 'holder-exact-full-name', 'Lisa Krasner'),
  ('90df3a98-e17c-4271-923b-f000adc47a03', '485829e4-49c6-48c6-a079-54d7b0ffb61a', 'State Senate District 16', 'State Senator', 1, '20261103NV31012', '172407', 'Chrystal L. Roll', 'Chrystal', 'Roll', false, false, 'Dem', 34193, 46.04, false, true, 'lost', NULL, NULL, NULL),
  ('a6cb105a-dc4a-4c21-8f79-9e0c7022363f', '5ff3de64-2e5f-4b93-99a3-658e43ccaa85', 'State Senate District 14', 'State Senator', 1, '20261103NV30993', '131903', 'Ira D. Hansen', 'Ira', 'Hansen', false, true, 'GOP', 0, 0, true, true, 'won', 'd7d372d1-e08e-4760-97bd-9edce9ffda05'::uuid, 'holder-exact-first-last', 'Ira Hansen'),
  ('692f9c77-f273-4083-8875-b578f4691985', 'c154e8ea-cf9f-4344-8734-0a013e57ab84', 'State Senate District 13', 'State Senator', 1, '20261103NV30995', '132620', 'Matthew R. Buehler', 'Matthew', 'Buehler', false, false, 'GOP', 11234, 27.83, false, true, 'lost', NULL, NULL, NULL),
  ('692f9c77-f273-4083-8875-b578f4691985', 'c154e8ea-cf9f-4344-8734-0a013e57ab84', 'State Senate District 13', 'State Senator', 1, '20261103NV30995', '131985', 'Richard Daly', 'Richard', 'Daly', false, true, 'Dem', 27602, 68.37, false, true, 'won', '0e80946b-8f57-43b7-af44-3c1c8469a51c'::uuid, 'holder-surname-plus-roster', 'Skip Daly'),
  ('692f9c77-f273-4083-8875-b578f4691985', 'c154e8ea-cf9f-4344-8734-0a013e57ab84', 'State Senate District 13', 'State Senator', 1, '20261103NV30995', '132599', 'Charlene Young', 'Charlene', 'Young', false, false, 'IAP', 1535, 3.8, false, true, 'lost', NULL, NULL, NULL),
  ('3ef9935c-9cf7-4411-8f53-cbb5015a6c33', '6760286e-ba67-445c-940a-1cc410886d6b', 'State Senate District 12', 'State Senator', 1, '20261103NV30158', '164484', 'Rafael Arroyo', 'Rafael', 'Arroyo', false, false, 'GOP', 20808, 39.96, false, true, 'lost', NULL, NULL, NULL),
  ('3ef9935c-9cf7-4411-8f53-cbb5015a6c33', '6760286e-ba67-445c-940a-1cc410886d6b', 'State Senate District 12', 'State Senator', 1, '20261103NV30158', '132482', 'Julie Ann Pazina', 'Julie', 'Pazina', false, true, 'Dem', 31261, 60.04, false, true, 'won', '0e6e4089-78fe-4090-a5d9-0541c3ec45c8'::uuid, 'holder-exact-first-last', 'Julie Pazina'),
  ('3eb3bc23-a54f-4c14-94af-117713660874', 'd5654bc9-e482-4604-82b8-19a654622326', 'State Senate District 10', 'State Senator', 1, '20261103NV30157', '132768', 'Fabian Donate', 'Fabian', 'Donate', false, true, 'Dem', 0, 0, true, true, 'won', '7b4022ca-9722-4947-a369-ee0e528b1af9'::uuid, 'holder-exact-full-name', 'Fabian Doñate'),
  ('a36aeec3-e7bc-4bd4-b25f-5d1905d1c0d9', '87b95915-7978-49a9-a296-6c53baee24f8', 'State Senate District 9', 'State Senator', 1, '20261103NV30156', '132478', 'Melanie Scheible', 'Melanie', 'Scheible', false, true, 'Dem', 29167, 62.47, false, true, 'won', '8d28af6f-1007-48f6-beb9-f81e33d6fd81'::uuid, 'holder-exact-full-name', 'Melanie Scheible'),
  ('a36aeec3-e7bc-4bd4-b25f-5d1905d1c0d9', '87b95915-7978-49a9-a296-6c53baee24f8', 'State Senate District 9', 'State Senator', 1, '20261103NV30156', '172406', 'Maria Thompson', 'Maria', 'Thompson', false, false, 'GOP', 17524, 37.53, false, true, 'lost', NULL, NULL, NULL),
  ('01392818-6e59-433f-91e5-2c3936f9e52e', '72fa015e-b13d-4309-b9a8-62bcdb6c732e', 'State Senate District 8', 'State Senator', 1, '20261103NV29848', '172405', 'George E. Harris', 'George', 'Harris', false, false, 'GOP', 22565, 42.67, false, true, 'lost', NULL, NULL, NULL),
  ('01392818-6e59-433f-91e5-2c3936f9e52e', '72fa015e-b13d-4309-b9a8-62bcdb6c732e', 'State Senate District 8', 'State Senator', 1, '20261103NV29848', '131703', 'Marilyn Dondero Loop', 'Marilyn', 'Dondero Loop', false, true, 'Dem', 30323, 57.33, false, true, 'won', '44c59b6c-de01-4c1b-b696-a57ad3947dba'::uuid, 'holder-exact-full-name', 'Marilyn Dondero Loop'),
  ('7f18f7f5-6c04-409a-8106-854767333172', '9d7ccaec-b482-410d-b647-0df80cd4cee3', 'State Senate District 2', 'State Senator', 1, '20261103NV29718', '132215', 'Edgar Flores', 'Edgar', 'Flores', false, true, 'Dem', 0, 0, true, true, 'won', 'b89ab6fe-ec36-4c03-a8ff-f1ef1afe1f8a'::uuid, 'holder-exact-full-name', 'Edgar Flores');

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> 95 THEN RAISE EXCEPTION 'CC_0417: expected 95 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> 53 THEN RAISE EXCEPTION 'CC_0417: expected 53 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> 52 THEN RAISE EXCEPTION 'CC_0417: expected 52 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> 41 THEN RAISE EXCEPTION 'CC_0417: expected 41 losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0417: expected 2 rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> 95 THEN RAISE EXCEPTION 'CC_0417: the race join sees % of the 95 rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 Nevada legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> 'nv'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % pinned row(s) are not in a 2026-11-03 Nevada legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: winner count does not match races.seats: %', txt; END IF;

  -- 🔴 THE ONLY GATE THAT CAN SEE A TRANSPOSED WIN. Every other check reads the outcome column
  --    beside the name, so a file with two outcomes swapped agrees with itself. AP publishes the
  --    winner flag and the vote count as INDEPENDENT fields, so where there are votes to order
  --    on, the winners must also be the top rows by count.
  --    ⚠ It is deliberately scoped to races AP tabulated: in an uncontested race every count is
  --    zero and this comparison would pass without comparing anything.
  SELECT string_agg(bad.district, '; ') INTO txt
    FROM (
      SELECT s.district
        FROM seed s
        JOIN (SELECT race_id, max(votes) AS top FROM seed WHERE NOT uncontested GROUP BY race_id) m
          ON m.race_id = s.race_id AND m.top > 0
       WHERE s.outcome = 'won' AND s.votes < (
         SELECT min(x.votes) FROM (
           SELECT votes FROM seed s2 WHERE s2.race_id = s.race_id ORDER BY votes DESC LIMIT s.seats
         ) x)
       GROUP BY s.district
    ) bad;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> 43 THEN RAISE EXCEPTION 'CC_0417: expected 43 incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_race_id || '-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: external_id already in use: %', txt; END IF;
END $$;

-- ─── 3. The write ───
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at)
SELECT s.race_id,
       s.holder_id,
       s.full_name,
       s.first_name,
       s.last_name,
       s.ap_incumbent,
       s.is_write_in,
       'active',
       'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id,
       'Associated Press ballot for the 2026-11-03 general election, read 2026-11-13 from AP''s own '
         || 'per-state results feed (interactives.apelections.org/election-results/data-live/'
         || '2026-11-03/results/races/NV/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against the Secretary of State''s own results feed behind silverstateelection.nv.gov '
         || '(https://silverstateelection.nv.gov/, read 2026-11-13). Seeded by CC_0417.'
         || CASE WHEN s.is_write_in THEN ' Declared write-in candidate.' ELSE '' END,
       s.outcome,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE 'called' END,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE
         'Associated Press race call for the 2026-11-03 general election, read 2026-11-13 from AP''s '
         || 'own per-state results feed (race ' || s.ap_race_id || ', candidate ' || s.ap_candidate_id
         || '), recorded as ' || s.outcome || '. '
         || CASE WHEN s.uncontested OR s.votes = 0
                 THEN 'AP publishes NO vote tabulation for this contest and calls it on the ballot at poll close, so no count is quoted here: a published zero is not a tally of zero.'
                 ELSE 'AP reported ' || s.pct || '% of the vote for this candidate.' END
         || ' This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. '
         || 'A call and a canvass are two facts.'
       END,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END
  FROM seed s
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id);

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id;
  IF n <> 95 THEN RAISE EXCEPTION 'CC_0417: expected 95 rows written, found %', n; END IF;

  -- The outcome, the name and the link each read back from production, not from the file's copy.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.race_id = s.race_id
     AND rc.full_name = s.full_name
     AND rc.result IS NOT DISTINCT FROM s.outcome
     AND rc.politician_id IS NOT DISTINCT FROM s.holder_id
     AND rc.is_write_in = s.is_write_in
     AND rc.is_incumbent = s.ap_incumbent;
  IF n <> 95 THEN RAISE EXCEPTION 'CC_0417: only % of 95 written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0417: a citation quotes a vote count: %', txt; END IF;

  -- The 53 races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = 'nv'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0417: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> 43 THEN RAISE EXCEPTION 'CC_0417: the seat holder changed for % of the 43 linked office(s) — this file seats nobody', 43 - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION 'CC_0417: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'CC_0417: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
