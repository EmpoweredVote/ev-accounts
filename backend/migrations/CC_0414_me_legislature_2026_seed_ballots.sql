-- CC_0414 - 2026-11-03 Maine legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the 186 races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. `CC_0381`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for Maine.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The Maine legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    `essentials.office_terms` is untouched, `essentials.offices` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--    344 candidacies across 186 races
--    183 won · 155 lost · 6 with NO result (3 race(s) AP has not called)
--    116 linked to a politician we already hold; the rest carry politician_id NULL
--      1 declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
--    The uncalled race(s) here:
--      State House District 86 (AP race 20261103ME20777, Too Early to Call)
--      State House District 96 (AP race 20261103ME20827, Too Early to Call)
--      State Senate District 18 (AP race 20261103ME20670, Too Early to Call)
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read 2026-11-13:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/ME/
-- and the Secretary of State's own "2026 General Candidate List - FINAL" spreadsheet,
-- read 2026-11-13 with Playwright:
--   https://www.maine.gov/sos/elections-voting/upcoming-elections
--
-- The join, the differences and how each one was settled are in
-- `backend/data/state-leg-2026-seed/` — `me-sos-crosscheck-2026-11-13.json` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (`CC_0408`-`CC_0411`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. 31 of these 186 races are uncontested and 31 of the 344 rows carry a
-- published count of zero. We store no vote counts in any column, so the only place a count
-- could reach production is the citation text — and it does not. Where AP publishes a count the
-- citation names the SHARE it reported; where AP publishes none it says so.
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
--   holder-exact-full-name      24
--   holder-surname-plus-roster   7
--   holder-exact-first-last     85
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
-- Slot CC_0414 reserved via steward. Applied to production 2026-11-13 by Chris Cantrell.
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
  ap_candidate_id  text PRIMARY KEY,
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
  holder_name      text
);

INSERT INTO seed VALUES
  ('1dbb54d6-8f55-4f1c-a96d-882c0b74d289', 'ddb05295-68a1-4247-8b69-476269e13840', 'State House District 29', 'Representative', 1, '20261103ME20709', '174194', 'Nancy Marie McDowell', 'Nancy', 'McDowell', false, false, 'Dem', 1477, 37.59, false, true, 'lost', NULL, NULL, NULL),
  ('1dbb54d6-8f55-4f1c-a96d-882c0b74d289', 'ddb05295-68a1-4247-8b69-476269e13840', 'State House District 29', 'Representative', 1, '20261103ME20709', '174196', 'Nancy J. Theriault', 'Nancy', 'Theriault', false, true, 'GOP', 2452, 62.41, false, true, 'won', '53d513a4-0725-433f-bc7c-9c1929b6d4d7'::uuid, 'holder-exact-full-name', 'Nancy J. Theriault'),
  ('0e7d40cf-c5d5-4e56-88e9-b9ff0289f9b0', 'cc176e13-9dfd-404f-85dc-39d2c948cfe6', 'State House District 117', 'Representative', 1, '20261103ME20746', '120223', 'Matthew Moonen', 'Matthew', 'Moonen', false, true, 'Dem', 0, 0, true, true, 'won', '0705d7cf-7e28-4543-9852-298bcafe4e66'::uuid, 'holder-surname-plus-roster', 'Matt Moonen'),
  ('6e1a4b15-9217-47bd-a083-86ca1a680a20', '80f87979-737a-4b0d-93ff-1b8bd76a5c35', 'State House District 118', 'Representative', 1, '20261103ME20819', '162239', 'Yusuf M. Yusuf', 'Yusuf', 'Yusuf', false, true, 'Dem', 0, 0, true, true, 'won', '8a68b1f1-52d6-442d-ba75-77885f30de58'::uuid, 'holder-exact-first-last', 'Yusuf Yusuf'),
  ('ebf4f141-a10a-465c-bde6-bc3d7e73d72d', '8350ef16-bf6f-4b7b-a952-2594d6fa7b3f', 'State House District 119', 'Representative', 1, '20261103ME20792', '174289', 'Michael P. Dixon', 'Michael', 'Dixon', false, false, 'Dem', 7117, 93.63, false, true, 'won', NULL, NULL, NULL),
  ('ebf4f141-a10a-465c-bde6-bc3d7e73d72d', '8350ef16-bf6f-4b7b-a952-2594d6fa7b3f', 'State House District 119', 'Representative', 1, '20261103ME20792', '162237', 'Jacob Murray Wakem', 'Jacob', 'Wakem', false, false, 'GOP', 484, 6.37, false, true, 'lost', NULL, NULL, NULL),
  ('d4298df8-73a0-4568-9c06-900b09f92955', '895e42f8-a3bb-43d6-9907-b973d2a4b118', 'State House District 120', 'Representative', 1, '20261103ME20793', '174290', 'Jason J. Shedlock', 'Jason', 'Shedlock', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('55c311c1-8ccd-46b1-bb65-8558d9b052da', '2832f4d1-3fe8-4951-afdc-340a79d032c8', 'State House District 121', 'Representative', 1, '20261103ME20818', '178681', 'Lucy Louisa Perkins', 'Lucy', 'Perkins', false, false, 'Dem', 4049, 77.01, false, true, 'won', NULL, NULL, NULL),
  ('55c311c1-8ccd-46b1-bb65-8558d9b052da', '2832f4d1-3fe8-4951-afdc-340a79d032c8', 'State House District 121', 'Representative', 1, '20261103ME20818', '174292', 'Meagan J. Smith', 'Meagan', 'Smith', false, false, 'GOP', 1209, 22.99, false, true, 'lost', NULL, NULL, NULL),
  ('ba8f2d51-ee07-4369-a68c-e569648620e2', '998dadae-5bc1-49b0-ab4a-d10188ba2604', 'State House District 122', 'Representative', 1, '20261103ME20802', '161519', 'Matthew D. Beck', 'Matthew', 'Beck', false, true, 'Dem', 0, 0, true, true, 'won', '6e1fd819-cbf6-4f93-9917-220ad3294902'::uuid, 'holder-exact-first-last', 'Matthew Beck'),
  ('22199d4c-d62f-400a-bcd4-a852a5ce96ae', 'd5ee3e98-d9bb-405b-85b3-73731f410626', 'State House District 123', 'Representative', 1, '20261103ME20804', '162242', 'Michelle N. Boyer', 'Michelle', 'Boyer', false, true, 'Dem', 0, 0, true, true, 'won', 'd3f89474-72f0-4a7a-a803-c32a865cec3a'::uuid, 'holder-exact-first-last', 'Michelle Boyer'),
  ('f05456c3-3ba8-4470-b564-f015f23c32d0', 'a13df238-94d6-4094-b974-9cecd2a02f4c', 'State House District 124', 'Representative', 1, '20261103ME20798', '174294', 'Scott W. Doherty', 'Scott', 'Doherty', false, false, 'GOP', 1506, 27.18, false, true, 'lost', NULL, NULL, NULL),
  ('f05456c3-3ba8-4470-b564-f015f23c32d0', 'a13df238-94d6-4094-b974-9cecd2a02f4c', 'State House District 124', 'Representative', 1, '20261103ME20798', '177866', 'Mary Shannon Lindstrom', 'Mary', 'Lindstrom', false, false, 'Ind', 1311, 23.66, false, true, 'lost', NULL, NULL, NULL),
  ('f05456c3-3ba8-4470-b564-f015f23c32d0', 'a13df238-94d6-4094-b974-9cecd2a02f4c', 'State House District 124', 'Representative', 1, '20261103ME20798', '174293', 'Eric James Nathanson', 'Eric', 'Nathanson', false, false, 'Dem', 2724, 49.16, false, true, 'won', NULL, NULL, NULL),
  ('c39eb7c4-4ec8-4a6c-bbb2-73dc8e14eaf4', 'a89c8e56-f69f-46eb-b9b6-2a56ab10c0a7', 'State House District 125', 'Representative', 1, '20261103ME20801', '122084', 'Kelly Noonan Murphy', 'Kelly', 'Murphy', false, true, 'Dem', 0, 0, true, true, 'won', '5d1feb93-3532-4e63-a175-5502fbcddae1'::uuid, 'holder-exact-first-last', 'Kelly Murphy'),
  ('37c4dbd9-6d11-4623-ad3e-097bd30db9ea', '09c62a73-bcd5-4ea4-bc73-9a9d47d4aefa', 'State House District 126', 'Representative', 1, '20261103ME20800', '121980', 'Andrew Gattine', 'Andrew', 'Gattine', false, true, 'Dem', 2763, 57.86, false, true, 'won', 'f7303b7d-0e06-4037-b9a4-9c7d12f37d6e'::uuid, 'holder-surname-plus-roster', 'Drew Gattine'),
  ('37c4dbd9-6d11-4623-ad3e-097bd30db9ea', '09c62a73-bcd5-4ea4-bc73-9a9d47d4aefa', 'State House District 126', 'Representative', 1, '20261103ME20800', '174295', 'Ethan E. Mongue', 'Ethan', 'Mongue', false, false, 'GOP', 2012, 42.14, false, true, 'lost', NULL, NULL, NULL),
  ('346efa9c-581e-49c9-82af-5c79e4d86b9c', 'e69534a9-13fa-4c9c-9e88-f75956c332cf', 'State House District 127', 'Representative', 1, '20261103ME20799', '121984', 'Morgan J. Rielly', 'Morgan', 'Rielly', false, true, 'Dem', 0, 0, true, true, 'won', '835e9c91-f373-4c9d-af75-6a5dd68539ec'::uuid, 'holder-exact-first-last', 'Morgan Rielly'),
  ('40029b3c-4cbb-4632-9150-84e16972c9b0', 'ad6f5dfd-ab4a-4b6b-9ffe-6e33cbadd4e1', 'State House District 128', 'Representative', 1, '20261103ME20796', '177867', 'Lawrence P. McWilliams', 'Lawrence', 'McWilliams', false, false, 'Unr', 1436, 30.31, false, true, 'lost', NULL, NULL, NULL),
  ('40029b3c-4cbb-4632-9150-84e16972c9b0', 'ad6f5dfd-ab4a-4b6b-9ffe-6e33cbadd4e1', 'State House District 128', 'Representative', 1, '20261103ME20796', '120344', 'Suzanne M. Salisbury', 'Suzanne', 'Salisbury', false, true, 'Dem', 3302, 69.69, false, true, 'won', 'd921e2be-d1e4-456a-915c-a4b3780dd633'::uuid, 'holder-exact-first-last', 'Suzanne Salisbury'),
  ('dc84020a-3d06-4311-80fa-97d73248ed3e', '4e3d2361-fcc5-4746-9971-1d44af0be712', 'State House District 129', 'Representative', 1, '20261103ME20797', '162245', 'Marshall F. Archer', 'Marshall', 'Archer', false, true, 'Dem', 0, 0, true, true, 'won', '453e9798-bbe1-45f3-9898-4cd13d91fc61'::uuid, 'holder-exact-first-last', 'Marshall Archer'),
  ('c5b8d757-162c-43cb-8ea0-755d7551ff68', '4fe26b25-07e3-4261-b592-6d1df9328982', 'State House District 130', 'Representative', 1, '20261103ME20794', '121689', 'Lynn Holland Copeland', 'Lynn', 'Copeland', false, true, 'Dem', 2661, 56.28, false, true, 'won', 'a44d3934-0db6-4fe4-9ba1-316098279e38'::uuid, 'holder-exact-first-last', 'Lynn Copeland'),
  ('c5b8d757-162c-43cb-8ea0-755d7551ff68', '4fe26b25-07e3-4261-b592-6d1df9328982', 'State House District 130', 'Representative', 1, '20261103ME20794', '177868', 'Todd M. Davis', 'Todd', 'Davis', false, false, 'Ind', 2067, 43.72, false, true, 'lost', NULL, NULL, NULL),
  ('139e6f40-8928-4fc8-bed9-4037ab989e7c', '3cebc93b-5119-4c01-95c1-0155317f5cd6', 'State House District 131', 'Representative', 1, '20261103ME20772', '177869', 'Kenneth Craig Blow', 'Kenneth', 'Blow', false, false, 'Unr', 2575, 48.7, false, true, 'lost', NULL, NULL, NULL),
  ('139e6f40-8928-4fc8-bed9-4037ab989e7c', '3cebc93b-5119-4c01-95c1-0155317f5cd6', 'State House District 131', 'Representative', 1, '20261103ME20772', '174296', 'Robert James Kelly', 'Robert', 'Kelly', false, false, 'Dem', 2713, 51.3, false, true, 'won', NULL, NULL, NULL),
  ('06540634-bdfa-4df4-bd60-6de6f3dfef2d', '6cba8c92-c3df-455b-a8e4-b9d08217693c', 'State House District 132', 'Representative', 1, '20261103ME20808', '120312', 'Ryan Fecteau', 'Ryan', 'Fecteau', false, true, 'Dem', 0, 0, true, true, 'won', '5b45bee6-4cdd-4800-83db-66e4e5b74c1d'::uuid, 'holder-exact-full-name', 'Ryan Fecteau'),
  ('54d6059f-effe-487c-ae29-cd2c46e74343', '32d33933-7305-4887-9dfc-540232c7e4c9', 'State House District 133', 'Representative', 1, '20261103ME20829', '177870', 'Marc P. Lessard', 'Marc', 'Lessard', false, false, 'UDC', 1604, 36.72, false, true, 'lost', NULL, NULL, NULL),
  ('54d6059f-effe-487c-ae29-cd2c46e74343', '32d33933-7305-4887-9dfc-540232c7e4c9', 'State House District 133', 'Representative', 1, '20261103ME20829', '121992', 'Marc G. Malon II', 'Marc', 'Malon', false, true, 'Dem', 2764, 63.28, false, true, 'won', '6465949e-7832-40cb-962f-839ebecf32ce'::uuid, 'holder-exact-first-last', 'Marc Malon'),
  ('6a0bf591-9b2c-49c9-824e-7d5163326f68', '2394aa28-f6da-495e-a768-8ddf6806ecb6', 'State House District 134', 'Representative', 1, '20261103ME20810', '177871', 'Allen Anthony Daggett', 'Allen', 'Daggett', false, false, 'Unr', 1992, 37.21, false, true, 'lost', NULL, NULL, NULL),
  ('6a0bf591-9b2c-49c9-824e-7d5163326f68', '2394aa28-f6da-495e-a768-8ddf6806ecb6', 'State House District 134', 'Representative', 1, '20261103ME20810', '121424', 'Traci Gere', 'Traci', 'Gere', false, true, 'Dem', 3362, 62.79, false, true, 'won', '6793f0eb-ddaa-4c72-ac99-70876295279a'::uuid, 'holder-exact-full-name', 'Traci Gere'),
  ('cc03de58-a28d-4bbe-9d9d-d35c62db109d', '292f35ae-e51f-48ca-b0c3-21b25896fe9e', 'State House District 135', 'Representative', 1, '20261103ME20811', '162247', 'Scott E. Craig', 'Scott', 'Craig', false, false, 'Ind', 2196, 37.8, false, true, 'lost', NULL, NULL, NULL),
  ('cc03de58-a28d-4bbe-9d9d-d35c62db109d', '292f35ae-e51f-48ca-b0c3-21b25896fe9e', 'State House District 135', 'Representative', 1, '20261103ME20811', '174298', 'Lisa Joy Pratt', 'Lisa', 'Pratt', false, false, 'Dem', 3614, 62.2, false, true, 'won', NULL, NULL, NULL),
  ('97653378-54c3-4ffe-b488-d2f55027c9dd', '2a8717d3-dc4d-44f8-8ba3-413fe04e2c5e', 'State House District 136', 'Representative', 1, '20261103ME20813', '162248', 'Michelle K. Conners', 'Michelle', 'Conners', false, false, 'Dem', 2227, 46.4, false, true, 'lost', NULL, NULL, NULL),
  ('97653378-54c3-4ffe-b488-d2f55027c9dd', '2a8717d3-dc4d-44f8-8ba3-413fe04e2c5e', 'State House District 136', 'Representative', 1, '20261103ME20813', '162249', 'John Eder', 'John', 'Eder', false, true, 'GOP', 2573, 53.6, false, true, 'won', '289e568d-a9e5-4e9d-9626-3b11891cd12b'::uuid, 'holder-exact-full-name', 'John Eder'),
  ('e60f1ec2-91a3-46fc-ad5d-757182ab2561', '27927d37-6be8-48a7-8a1b-623ea007ee82', 'State House District 137', 'Representative', 1, '20261103ME20815', '121434', 'Nathan M. Carlow', 'Nathan', 'Carlow', false, true, 'GOP', 2469, 48.8, false, true, 'lost', 'ebd1c39c-73cc-4346-a7f3-55a4274045a3'::uuid, 'holder-exact-first-last', 'Nathan Carlow'),
  ('e60f1ec2-91a3-46fc-ad5d-757182ab2561', '27927d37-6be8-48a7-8a1b-623ea007ee82', 'State House District 137', 'Representative', 1, '20261103ME20815', '174299', 'Charles Tilburg', 'Charles', 'Tilburg', false, false, 'Dem', 2590, 51.2, false, true, 'won', NULL, NULL, NULL),
  ('6c03873c-19d9-4fdb-97ea-4e90fdeb246b', 'ff860a26-3bc4-4ed0-9dc6-8e05fb055107', 'State House District 138', 'Representative', 1, '20261103ME20812', '120209', 'Jonathan Lee Kinney', 'Jonathan', 'Kinney', false, false, 'GOP', 2610, 55.7, false, true, 'won', NULL, NULL, NULL),
  ('6c03873c-19d9-4fdb-97ea-4e90fdeb246b', 'ff860a26-3bc4-4ed0-9dc6-8e05fb055107', 'State House District 138', 'Representative', 1, '20261103ME20812', '174300', 'Oliver D. McAvoy', 'Oliver', 'McAvoy', false, false, 'Dem', 2076, 44.3, false, true, 'lost', NULL, NULL, NULL),
  ('e337f64c-8664-4feb-b289-a0ab4547f04b', '7cec4591-2b60-4040-809a-7608a670ecbe', 'State House District 139', 'Representative', 1, '20261103ME20814', '174301', 'Dean P. LePage', 'Dean', 'LePage', false, false, 'Dem', 2064, 46.91, false, true, 'lost', NULL, NULL, NULL),
  ('e337f64c-8664-4feb-b289-a0ab4547f04b', '7cec4591-2b60-4040-809a-7608a670ecbe', 'State House District 139', 'Representative', 1, '20261103ME20814', '174302', 'Jamie K. Newton', 'Jamie', 'Newton', false, false, 'GOP', 2336, 53.09, false, true, 'won', NULL, NULL, NULL),
  ('2bcf2d73-13b7-49ab-8b3c-799c5acc1c58', '31552906-bf12-41f6-bb23-acc68bb1fe26', 'State House District 140', 'Representative', 1, '20261103ME20816', '120048', 'Wayne R. Parry', 'Wayne', 'Parry', false, true, 'GOP', 2732, 53.2, false, true, 'won', '6a008bbb-a2dd-4128-87cf-f2fe0278738b'::uuid, 'holder-exact-first-last', 'Wayne Parry'),
  ('2bcf2d73-13b7-49ab-8b3c-799c5acc1c58', '31552906-bf12-41f6-bb23-acc68bb1fe26', 'State House District 140', 'Representative', 1, '20261103ME20816', '122004', 'Kirstan L. Watson', 'Kirstan', 'Watson', false, false, 'Dem', 2403, 46.8, false, true, 'lost', NULL, NULL, NULL),
  ('0775f94e-8a5f-480a-a848-dbd8dbca9243', '0170d349-441e-4792-989f-75eee29c06a5', 'State House District 141', 'Representative', 1, '20261103ME20817', '174305', 'Marc A. Boisse', 'Marc', 'Boisse', false, false, 'GOP', 2295, 52.66, false, true, 'won', NULL, NULL, NULL),
  ('0775f94e-8a5f-480a-a848-dbd8dbca9243', '0170d349-441e-4792-989f-75eee29c06a5', 'State House District 141', 'Representative', 1, '20261103ME20817', '174303', 'Rebecca L. Flood Andrews', 'Rebecca', 'Flood Andrews', false, false, 'Dem', 1810, 41.53, false, true, 'lost', NULL, NULL, NULL),
  ('0775f94e-8a5f-480a-a848-dbd8dbca9243', '0170d349-441e-4792-989f-75eee29c06a5', 'State House District 141', 'Representative', 1, '20261103ME20817', '177872', 'David R. Mongeau II', 'David', 'Mongeau', false, false, 'Unr', 253, 5.81, false, true, 'lost', NULL, NULL, NULL),
  ('8be762b8-3ca2-4c8b-9926-d792e25a0c3a', '137f5c0a-1da3-48e4-85ba-ea34a49a68a3', 'State House District 142', 'Representative', 1, '20261103ME20821', '174306', 'Ayn M. Hanselmann', 'Ayn', 'Hanselmann', false, false, 'Dem', 1873, 62.25, false, true, 'won', NULL, NULL, NULL),
  ('8be762b8-3ca2-4c8b-9926-d792e25a0c3a', '137f5c0a-1da3-48e4-85ba-ea34a49a68a3', 'State House District 142', 'Representative', 1, '20261103ME20821', '178279', 'Domingo E. Torres', 'Domingo', 'Torres', false, false, 'GOP', 1136, 37.75, false, true, 'lost', NULL, NULL, NULL),
  ('f2f2be57-9c76-42b7-8f1a-5edd821a39d2', 'c273e2d2-b458-4b87-9c32-ed0f2649c98b', 'State House District 143', 'Representative', 1, '20261103ME20822', '174307', 'John R. Henkelman', 'John', 'Henkelman', false, false, 'Dem', 2066, 54.7, false, true, 'won', NULL, NULL, NULL),
  ('f2f2be57-9c76-42b7-8f1a-5edd821a39d2', 'c273e2d2-b458-4b87-9c32-ed0f2649c98b', 'State House District 143', 'Representative', 1, '20261103ME20822', '178280', 'Melissa A. Simpson', 'Melissa', 'Simpson', false, false, 'GOP', 1711, 45.3, false, true, 'lost', NULL, NULL, NULL),
  ('9857ef5a-f558-4268-b4c7-23756d6a9bda', 'be2b1141-523f-4cc4-9395-169f693d58d3', 'State House District 144', 'Representative', 1, '20261103ME20823', '122019', 'Corinna Cole', 'Corinna', 'Cole', false, false, 'Unr', 1395, 35.38, false, true, 'lost', NULL, NULL, NULL),
  ('9857ef5a-f558-4268-b4c7-23756d6a9bda', 'be2b1141-523f-4cc4-9395-169f693d58d3', 'State House District 144', 'Representative', 1, '20261103ME20823', '120325', 'Karen A. Gerrish', 'Karen', 'Gerrish', false, false, 'GOP', 2548, 64.62, false, true, 'won', NULL, NULL, NULL),
  ('ab5ab89f-78ef-4eb5-9c0f-0ec0669059c6', '688b4846-3f37-4091-8d45-3077f4bc3a16', 'State House District 145', 'Representative', 1, '20261103ME20824', '174310', 'Caleb J. Chase', 'Caleb', 'Chase', false, false, 'GOP', 2680, 43.97, false, true, 'lost', NULL, NULL, NULL),
  ('ab5ab89f-78ef-4eb5-9c0f-0ec0669059c6', '688b4846-3f37-4091-8d45-3077f4bc3a16', 'State House District 145', 'Representative', 1, '20261103ME20824', '174309', 'Kristin T. Davis', 'Kristin', 'Davis', false, false, 'Dem', 3415, 56.03, false, true, 'won', NULL, NULL, NULL),
  ('8ae74d9e-5187-4933-8aa4-3e70605467cd', 'e0f7683e-6973-4d3d-b719-c47cc69bc967', 'State House District 146', 'Representative', 1, '20261103ME20825', '120055', 'Bradley S. Moulton', 'Bradley', 'Moulton', false, false, 'GOP', 1998, 37.46, false, true, 'lost', NULL, NULL, NULL),
  ('8ae74d9e-5187-4933-8aa4-3e70605467cd', 'e0f7683e-6973-4d3d-b719-c47cc69bc967', 'State House District 146', 'Representative', 1, '20261103ME20825', '122023', 'Walter Gerard Runte Jr.', 'Walter', 'Runte', false, true, 'Dem', 3335, 62.54, false, true, 'won', 'a54704f7-023d-4351-80b5-9cfb397dfcf6'::uuid, 'holder-exact-first-last', 'Walter Runte'),
  ('6d5674f6-1853-4f93-9283-0b27317b80d2', '9c6bbbd8-8229-4a13-9d78-5b61e6819e1d', 'State House District 147', 'Representative', 1, '20261103ME20826', '122026', 'Holly T. Sargent', 'Holly', 'Sargent', false, true, 'Dem', 0, 0, true, true, 'won', '0199d6a7-271e-40b1-aad0-2cf262c7046b'::uuid, 'holder-exact-first-last', 'Holly Sargent'),
  ('43b44859-283f-42df-9d36-81e5cef05584', '2d652817-ef96-4f81-a7ce-dd9e27a71304', 'State House District 148', 'Representative', 1, '20261103ME20830', '122034', 'Thomas Arthur Lavigne', 'Thomas', 'Lavigne', false, true, 'GOP', 2248, 48.61, false, true, 'lost', 'b13ec962-0772-4fdd-8399-59c3bc7fa19a'::uuid, 'holder-exact-first-last', 'Thomas Lavigne'),
  ('43b44859-283f-42df-9d36-81e5cef05584', '2d652817-ef96-4f81-a7ce-dd9e27a71304', 'State House District 148', 'Representative', 1, '20261103ME20830', '178682', 'Marissa L. Tasker', 'Marissa', 'Tasker', false, false, 'Dem', 2377, 51.39, false, true, 'won', NULL, NULL, NULL),
  ('fce8aff8-5e99-4fa9-84ee-e6f0556eb6e5', '279cb520-0361-4170-a30d-05919f320807', 'State House District 149', 'Representative', 1, '20261103ME20828', '174311', 'Mallory A. Cook', 'Mallory', 'Cook', false, false, 'Dem', 2972, 60.46, false, true, 'won', NULL, NULL, NULL),
  ('fce8aff8-5e99-4fa9-84ee-e6f0556eb6e5', '279cb520-0361-4170-a30d-05919f320807', 'State House District 149', 'Representative', 1, '20261103ME20828', '174312', 'Timothy R. Towne', 'Timothy', 'Towne', false, false, 'GOP', 1944, 39.54, false, true, 'lost', NULL, NULL, NULL),
  ('fe7b6fc2-9070-4267-82af-6af237761232', '83f9b3c6-11e6-4e68-8541-289a40ac7e2d', 'State House District 150', 'Representative', 1, '20261103ME20831', '174313', 'Alexandros Orestis', 'Alexandros', 'Orestis', false, false, 'Dem', 3355, 64.09, false, true, 'won', NULL, NULL, NULL),
  ('fe7b6fc2-9070-4267-82af-6af237761232', '83f9b3c6-11e6-4e68-8541-289a40ac7e2d', 'State House District 150', 'Representative', 1, '20261103ME20831', '162257', 'Mark F. Zimmer', 'Mark', 'Zimmer', false, false, 'GOP', 1880, 35.91, false, true, 'lost', NULL, NULL, NULL),
  ('59aed986-c431-42cb-aeba-fae09d35eb02', 'f44832b5-d213-4fc8-bc1f-9bcea327f4a5', 'State House District 151', 'Representative', 1, '20261103ME20832', '162258', 'Suzanne Johnson', 'Suzanne', 'Johnson', false, false, 'GOP', 1223, 23.69, false, true, 'lost', NULL, NULL, NULL),
  ('59aed986-c431-42cb-aeba-fae09d35eb02', 'f44832b5-d213-4fc8-bc1f-9bcea327f4a5', 'State House District 151', 'Representative', 1, '20261103ME20832', '121412', 'Kristi M. Mathieson', 'Kristi', 'Mathieson', false, true, 'Dem', 3939, 76.31, false, true, 'won', '7ebe7923-3a6a-464e-9646-4e688459f614'::uuid, 'holder-exact-first-last', 'Kristi Mathieson'),
  ('1760786d-2d6b-4a99-b423-02cd29364f48', '11ae35e4-1267-428f-9fc0-51249878d06a', 'State House District 1', 'Representative', 1, '20261103ME20682', '178677', 'Jennifer L. Levesque', 'Jennifer', 'Levesque', false, false, 'Dem', 1412, 36.81, false, true, 'lost', NULL, NULL, NULL),
  ('1760786d-2d6b-4a99-b423-02cd29364f48', '11ae35e4-1267-428f-9fc0-51249878d06a', 'State House District 1', 'Representative', 1, '20261103ME20682', '121764', 'Austin Theriault', 'Austin', 'Theriault', false, false, 'GOP', 2424, 63.19, false, true, 'won', NULL, NULL, NULL),
  ('f09b1591-de5e-49dd-a80d-a60e75b4475d', 'e3530fe7-10e6-481b-abb8-b7d6f19d0f2d', 'State House District 2', 'Representative', 1, '20261103ME20683', '121768', 'Roger C. Albert', 'Roger', 'Albert', false, true, 'GOP', 2156, 52.61, false, true, 'won', 'a3ea95d3-cc5c-4867-a6b3-6004d5bd437a'::uuid, 'holder-exact-first-last', 'Roger Albert'),
  ('f09b1591-de5e-49dd-a80d-a60e75b4475d', 'e3530fe7-10e6-481b-abb8-b7d6f19d0f2d', 'State House District 2', 'Representative', 1, '20261103ME20683', '120504', 'Roland Daniel Martin', 'Roland', 'Martin', false, false, 'Dem', 1942, 47.39, false, true, 'lost', NULL, NULL, NULL),
  ('edaf0e3a-b892-4540-a902-16eaf8761c8d', 'b1d74bd9-4c8e-4057-8a4f-d9d37380f9ff', 'State House District 3', 'Representative', 1, '20261103ME20762', '121643', 'Susan Bernard', 'Susan', 'Bernard', false, false, 'GOP', 2165, 58.09, false, true, 'won', NULL, NULL, NULL),
  ('edaf0e3a-b892-4540-a902-16eaf8761c8d', 'b1d74bd9-4c8e-4057-8a4f-d9d37380f9ff', 'State House District 3', 'Representative', 1, '20261103ME20762', '121205', 'David H. McCrea', 'David', 'McCrea', false, false, 'Dem', 1562, 41.91, false, true, 'lost', NULL, NULL, NULL),
  ('dd29ec37-3492-4b39-9f86-5918d882a922', '5a20101c-4802-4f0a-937e-0e0cf799bc58', 'State House District 4', 'Representative', 1, '20261103ME20684', '120664', 'Timothy Conrad Guerrette', 'Timothy', 'Guerrette', false, true, 'GOP', 0, 0, true, true, 'won', '176c355c-b056-4131-8767-6805592af0d0'::uuid, 'holder-exact-first-last', 'Timothy Guerrette'),
  ('cb1d4d83-e764-4f94-9a67-1feb86b46430', 'ab1735d1-5550-4b4e-ab1b-d1c5e71c65ef', 'State House District 5', 'Representative', 1, '20261103ME20688', '174173', 'Douglas C. Carlisle Jr.', 'Douglas', 'Carlisle', false, false, 'GOP', 1778, 54.04, false, true, 'won', NULL, NULL, NULL),
  ('cb1d4d83-e764-4f94-9a67-1feb86b46430', 'ab1735d1-5550-4b4e-ab1b-d1c5e71c65ef', 'State House District 5', 'Representative', 1, '20261103ME20688', '178678', 'Lori G. Kenneson', 'Lori', 'Kenneson', false, false, 'Dem', 1512, 45.96, false, true, 'lost', NULL, NULL, NULL),
  ('57c90c71-a12b-4cd2-aa57-99061ade0931', 'bb6fc216-2057-4eb9-9547-77b48c157a5f', 'State House District 6', 'Representative', 1, '20261103ME20685', '121777', 'Donald James Ardell', 'Donald', 'Ardell', false, true, 'GOP', 1947, 63.77, false, true, 'won', 'c31211fb-24d8-4698-b2f1-e6a26b562b35'::uuid, 'holder-exact-first-last', 'Donald Ardell'),
  ('57c90c71-a12b-4cd2-aa57-99061ade0931', 'bb6fc216-2057-4eb9-9547-77b48c157a5f', 'State House District 6', 'Representative', 1, '20261103ME20685', '162141', 'Melanie Tompkins', 'Melanie', 'Tompkins', false, false, 'Dem', 1106, 36.23, false, true, 'lost', NULL, NULL, NULL),
  ('058351a7-85a8-4ac9-9814-e129c8340a2a', '01ee34b3-5ea9-4a6c-9eca-b4aeefc5cda1', 'State House District 7', 'Representative', 1, '20261103ME20686', '174174', 'Jantzen Stephen Craine', 'Jantzen', 'Craine', false, false, 'GOP', 1558, 56.86, false, true, 'won', NULL, NULL, NULL),
  ('058351a7-85a8-4ac9-9814-e129c8340a2a', '01ee34b3-5ea9-4a6c-9eca-b4aeefc5cda1', 'State House District 7', 'Representative', 1, '20261103ME20686', '162013', 'Matthew J. Rush', 'Matthew', 'Rush', false, false, 'Dem', 1182, 43.14, false, true, 'lost', NULL, NULL, NULL),
  ('4c0e8712-1478-445d-8b08-a1a008eebe5a', '0fd7e425-ceda-45c7-ba38-c3f0a7ee044e', 'State House District 8', 'Representative', 1, '20261103ME20687', '121684', 'Tracy Lynn Quint', 'Tracy', 'Quint', false, true, 'GOP', 0, 0, true, true, 'won', '7560948b-f1f1-422c-be0c-f92865c100f9'::uuid, 'holder-exact-first-last', 'Tracy Quint'),
  ('c50f0d13-78bc-48e3-9564-931e84bf020d', '9413f7a6-01aa-489c-8c19-81c085179e0b', 'State House District 9', 'Representative', 1, '20261103ME20690', '162145', 'Arthur K. Mingo', 'Arthur', 'Mingo', false, true, 'GOP', 2213, 60.9, false, true, 'won', '825c6de9-e46d-44ec-9093-fea10f93f60f'::uuid, 'holder-exact-first-last', 'Arthur Mingo'),
  ('c50f0d13-78bc-48e3-9564-931e84bf020d', '9413f7a6-01aa-489c-8c19-81c085179e0b', 'State House District 9', 'Representative', 1, '20261103ME20690', '174175', 'Nicole N. Richards', 'Nicole', 'Richards', false, false, 'Dem', 1421, 39.1, false, true, 'lost', NULL, NULL, NULL),
  ('5c0ec09b-226d-48e7-8763-9a874152caa7', '0aeb829d-9556-4e63-a207-7993aa5a3452', 'State House District 10', 'Representative', 1, '20261103ME20694', '174176', 'Genevieve M. Lemire', 'Genevieve', 'Lemire', false, false, 'Dem', 870, 28.55, false, true, 'lost', NULL, NULL, NULL),
  ('5c0ec09b-226d-48e7-8763-9a874152caa7', '0aeb829d-9556-4e63-a207-7993aa5a3452', 'State House District 10', 'Representative', 1, '20261103ME20694', '120494', 'William R. Tuell', 'William', 'Tuell', false, true, 'GOP', 2177, 71.45, false, true, 'won', 'e6155a4a-4fcf-4195-85c1-509f5d4c016d'::uuid, 'holder-exact-first-last', 'William Tuell'),
  ('172bcfa2-0100-4ca5-9cdf-cef8e7eed27d', '2c2fa049-da0b-47b0-a643-4fceb10cbdff', 'State House District 11', 'Representative', 1, '20261103ME20699', '174178', 'Keith A. Newman', 'Keith', 'Newman', false, false, 'Dem', 1536, 35.75, false, true, 'lost', NULL, NULL, NULL),
  ('172bcfa2-0100-4ca5-9cdf-cef8e7eed27d', '2c2fa049-da0b-47b0-a643-4fceb10cbdff', 'State House District 11', 'Representative', 1, '20261103ME20699', '121786', 'Tiffany Strout', 'Tiffany', 'Strout', false, true, 'GOP', 2760, 64.25, false, true, 'won', '8eaadc47-e2ed-475e-bf29-6235039b4a60'::uuid, 'holder-exact-full-name', 'Tiffany Strout'),
  ('624f9df9-2fae-4e73-aa26-cc094ebc85ea', '9b05741f-ba5e-4167-8251-dacd4bd2522e', 'State House District 12', 'Representative', 1, '20261103ME20700', '122048', 'Roy D. Gott', 'Roy', 'Gott', false, false, 'Unr', 2192, 46.71, false, true, 'lost', NULL, NULL, NULL),
  ('624f9df9-2fae-4e73-aa26-cc094ebc85ea', '9b05741f-ba5e-4167-8251-dacd4bd2522e', 'State House District 12', 'Representative', 1, '20261103ME20700', '174179', 'Thomas Arthur Hart Jr.', 'Thomas', 'Hart', false, false, 'GOP', 2501, 53.29, false, true, 'won', NULL, NULL, NULL),
  ('3813c2d1-9641-4f25-ae48-e569e97914b8', 'ec42b8a1-ade3-4ba4-805e-1f71cb54c799', 'State House District 13', 'Representative', 1, '20261103ME20701', '174180', 'Michael H. Cunningham II', 'Michael', 'Cunningham', false, false, 'Dem', 2153, 48.77, false, true, 'lost', NULL, NULL, NULL),
  ('3813c2d1-9641-4f25-ae48-e569e97914b8', 'ec42b8a1-ade3-4ba4-805e-1f71cb54c799', 'State House District 13', 'Representative', 1, '20261103ME20701', '162149', 'Russell P. White', 'Russell', 'White', false, true, 'GOP', 2262, 51.23, false, true, 'won', '6ca03396-08d7-43ff-a101-f5a1aec11e3e'::uuid, 'holder-exact-first-last', 'Russell White'),
  ('7cc92668-6245-44e8-b525-aa0cc0905050', 'e85cac58-7510-4c12-8f46-9eeb52866af1', 'State House District 14', 'Representative', 1, '20261103ME20696', '163115', 'Gary R. Friedmann', 'Gary', 'Friedmann', false, true, 'Dem', 0, 0, true, true, 'won', '047962c6-216a-4ff6-b63e-04c900fb8af9'::uuid, 'holder-exact-first-last', 'Gary Friedmann'),
  ('25e222b9-33e2-4ced-9948-5aa481b813b9', 'c93bed0c-53a8-4abc-87bb-7bcf116c8232', 'State House District 15', 'Representative', 1, '20261103ME20697', '121797', 'Holly R. Eaton', 'Holly', 'Eaton', false, true, 'Dem', 3534, 70.57, false, true, 'won', '1f171f1f-14e4-47ef-b715-0d676e815568'::uuid, 'holder-exact-first-last', 'Holly Eaton'),
  ('25e222b9-33e2-4ced-9948-5aa481b813b9', 'c93bed0c-53a8-4abc-87bb-7bcf116c8232', 'State House District 15', 'Representative', 1, '20261103ME20697', '177859', 'Clifford John Noyes', 'Clifford', 'Noyes', false, false, 'Unr', 1474, 29.43, false, true, 'lost', NULL, NULL, NULL),
  ('232af8a9-8b51-491a-aec8-68fab500cf48', 'e7188427-91ae-49c5-b803-c1f680b096bf', 'State House District 16', 'Representative', 1, '20261103ME20695', '121802', 'Nina Azella Milliken', 'Nina', 'Milliken', false, true, 'Dem', 3633, 65.15, false, true, 'won', '1037ec72-4bfe-4d5c-87b8-4eb2fa7d998b'::uuid, 'holder-exact-first-last', 'Nina Milliken'),
  ('232af8a9-8b51-491a-aec8-68fab500cf48', 'e7188427-91ae-49c5-b803-c1f680b096bf', 'State House District 16', 'Representative', 1, '20261103ME20695', '174181', 'Eric M. White', 'Eric', 'White', false, false, 'GOP', 1943, 34.85, false, true, 'lost', NULL, NULL, NULL),
  ('9824879e-70c9-4bb6-9bee-839a72272993', 'c3127329-4033-41ed-9597-dbb3fbb853dc', 'State House District 17', 'Representative', 1, '20261103ME20693', '162151', 'Steven Matthew Bishop', 'Steven', 'Bishop', false, true, 'GOP', 2528, 50.98, false, true, 'won', 'a5c70691-3834-48f8-aeca-79b95c131884'::uuid, 'holder-exact-first-last', 'Steven Bishop'),
  ('9824879e-70c9-4bb6-9bee-839a72272993', 'c3127329-4033-41ed-9597-dbb3fbb853dc', 'State House District 17', 'Representative', 1, '20261103ME20693', '121993', 'Ronald B. Russell', 'Ronald', 'Russell', false, false, 'Dem', 2431, 49.02, false, true, 'lost', NULL, NULL, NULL),
  ('d8420bf0-488c-4f31-9cf8-5b6902ee9ba7', 'fbeba730-ee87-481a-9a75-7b6cf312956a', 'State House District 18', 'Representative', 1, '20261103ME20691', '121702', 'Jonathan C. Goble', 'Jonathan', 'Goble', false, false, 'Dem', 1433, 37.1, false, true, 'lost', NULL, NULL, NULL),
  ('d8420bf0-488c-4f31-9cf8-5b6902ee9ba7', 'fbeba730-ee87-481a-9a75-7b6cf312956a', 'State House District 18', 'Representative', 1, '20261103ME20691', '162152', 'Mathew David McIntyre', 'Mathew', 'McIntyre', false, true, 'GOP', 2430, 62.9, false, true, 'won', '084e79da-0515-491e-99cd-a663d1f85819'::uuid, 'holder-exact-first-last', 'Mathew McIntyre'),
  ('29a4bc14-eb0b-4c3c-93b1-f5c018a23208', '8a1af120-b796-4633-8aaa-54016fe0ed8e', 'State House District 19', 'Representative', 1, '20261103ME20698', '22321', 'Richard H. Campbell', 'Richard', 'Campbell', false, true, 'GOP', 3298, 61.12, false, true, 'won', '1f6fb9ae-a29b-4174-baf3-1116371c4955'::uuid, 'holder-exact-first-last', 'Richard Campbell'),
  ('29a4bc14-eb0b-4c3c-93b1-f5c018a23208', '8a1af120-b796-4633-8aaa-54016fe0ed8e', 'State House District 19', 'Representative', 1, '20261103ME20698', '174182', 'David Ulrich', 'David', 'Ulrich', false, false, 'Dem', 2098, 38.88, false, true, 'lost', NULL, NULL, NULL),
  ('723bbb9b-ce03-4b66-b39e-91fa6726fd44', '58346407-dbb1-4e9b-8081-7c05b04b92e8', 'State House District 20', 'Representative', 1, '20261103ME20689', '167341', 'Patrick A. Jude', 'Patrick', 'Jude', false, false, 'GOP', 1879, 44.08, false, true, 'lost', NULL, NULL, NULL),
  ('723bbb9b-ce03-4b66-b39e-91fa6726fd44', '58346407-dbb1-4e9b-8081-7c05b04b92e8', 'State House District 20', 'Representative', 1, '20261103ME20689', '162153', 'Dani O''Halloran', 'Dani', 'O''Halloran', false, true, 'Dem', 2384, 55.92, false, true, 'won', '59df0b0d-f559-4e37-8f3a-1f8ae5b09485'::uuid, 'holder-exact-full-name', 'Dani O''Halloran'),
  ('4c9c845f-0784-420e-819d-b323bed0bb06', '2d902bd0-362c-4ff2-92cf-f7475b2b0c52', 'State House District 21', 'Representative', 1, '20261103ME20692', '174183', 'Frank Joseph Casella', 'Frank', 'Casella', false, false, 'GOP', 1267, 34.38, false, true, 'lost', NULL, NULL, NULL),
  ('4c9c845f-0784-420e-819d-b323bed0bb06', '2d902bd0-362c-4ff2-92cf-f7475b2b0c52', 'State House District 21', 'Representative', 1, '20261103ME20692', '121106', 'Ambureen Rana', 'Ambureen', 'Rana', false, true, 'Dem', 2418, 65.62, false, true, 'won', 'c9d094fe-1054-4804-bd24-f2cd6ceb748d'::uuid, 'holder-exact-full-name', 'Ambureen Rana'),
  ('bd50c35f-a9c9-4003-ad06-54b7b0813df6', '2a3dda35-95ab-4831-9fe5-f596d0f0553a', 'State House District 22', 'Representative', 1, '20261103ME20703', '121596', 'Laura D. Supica', 'Laura', 'Supica', false, true, 'Dem', 0, 0, true, true, 'won', 'e6bd2fa6-6e8c-46e2-b13d-59f340a1a38f'::uuid, 'holder-exact-first-last', 'Laura Supica'),
  ('15769f0a-dd82-4362-906b-3f2ff697bf40', '2df5a507-6dd4-43b8-b90a-3a431e50fbde', 'State House District 23', 'Representative', 1, '20261103ME20724', '174188', 'Brian A. Ames', 'Brian', 'Ames', false, false, 'GOP', 1755, 39.3, false, true, 'lost', NULL, NULL, NULL),
  ('15769f0a-dd82-4362-906b-3f2ff697bf40', '2df5a507-6dd4-43b8-b90a-3a431e50fbde', 'State House District 23', 'Representative', 1, '20261103ME20724', '120239', 'Victoria P. Kornfield', 'Victoria', 'Kornfield', false, false, 'Dem', 2711, 60.7, false, true, 'won', NULL, NULL, NULL),
  ('e95669c9-bfaf-4409-b2bf-3a03d620194e', '11fa1aaa-59a7-40ba-8506-8ca34fecd590', 'State House District 24', 'Representative', 1, '20261103ME20720', '174189', 'Sean F. Faircloth', 'Sean', 'Faircloth', false, true, 'Dem', 3360, 99.47, false, true, 'won', '9c446f79-a394-4d25-85a6-31304ae1ec58'::uuid, 'holder-exact-first-last', 'Sean Faircloth'),
  ('e95669c9-bfaf-4409-b2bf-3a03d620194e', '11fa1aaa-59a7-40ba-8506-8ca34fecd590', 'State House District 24', 'Representative', 1, '20261103ME20720', '120687', 'Daniel LaPointe', 'Daniel', 'LaPointe', true, false, 'GOP', 18, 0.53, false, true, 'lost', NULL, NULL, NULL),
  ('5112eddd-6ac0-48e0-83a2-6099c1d96d14', 'dc8d2c47-206a-4090-b981-038df9962213', 'State House District 25', 'Representative', 1, '20261103ME20773', '121590', 'Laurie Osher', 'Laurie', 'Osher', false, true, 'Dem', 2425, 82.71, false, true, 'won', 'dc70f61b-e541-4947-b09a-af8f983929a9'::uuid, 'holder-exact-full-name', 'Laurie Osher'),
  ('5112eddd-6ac0-48e0-83a2-6099c1d96d14', 'dc8d2c47-206a-4090-b981-038df9962213', 'State House District 25', 'Representative', 1, '20261103ME20773', '174190', 'Anthony M. Weaver', 'Anthony', 'Weaver', false, false, 'GOP', 507, 17.29, false, true, 'lost', NULL, NULL, NULL),
  ('ff3daccd-67eb-43ee-8595-36c5a56c6d2b', '4d92ff89-07df-46f2-a790-c9d379b98d8f', 'State House District 26', 'Representative', 1, '20261103ME20704', '119906', 'James F. Dill', 'James', 'Dill', false, true, 'Dem', 2927, 65.13, false, true, 'won', 'c0b96558-d6b2-4029-b680-40c5cc815688'::uuid, 'holder-exact-first-last', 'James Dill'),
  ('ff3daccd-67eb-43ee-8595-36c5a56c6d2b', '4d92ff89-07df-46f2-a790-c9d379b98d8f', 'State House District 26', 'Representative', 1, '20261103ME20704', '177860', 'Adam Joseph Shaw', 'Adam', 'Shaw', false, false, 'Ind', 1567, 34.87, false, true, 'lost', NULL, NULL, NULL),
  ('2227c1a3-c0fe-4a13-8dbd-9e967f06e816', '617ee970-023d-4354-9071-700a0448f225', 'State House District 27', 'Representative', 1, '20261103ME20760', '174191', 'Devan C. Arnold', 'Devan', 'Arnold', false, false, 'Dem', 1494, 33.97, false, true, 'lost', NULL, NULL, NULL),
  ('2227c1a3-c0fe-4a13-8dbd-9e967f06e816', '617ee970-023d-4354-9071-700a0448f225', 'State House District 27', 'Representative', 1, '20261103ME20760', '174192', 'David Giles', 'David', 'Giles', false, false, 'GOP', 2904, 66.03, false, true, 'won', NULL, NULL, NULL),
  ('b8458214-8367-429f-a64d-0d3d3c46f88c', '72d6c659-b63c-44fe-b9bc-3d6bb1367a79', 'State House District 28', 'Representative', 1, '20261103ME20702', '122070', 'Irene A. Gifford', 'Irene', 'Gifford', false, true, 'GOP', 2821, 67.02, false, true, 'won', '4d943425-994b-4761-a3a8-b77f69f6b4bf'::uuid, 'holder-exact-first-last', 'Irene Gifford'),
  ('b8458214-8367-429f-a64d-0d3d3c46f88c', '72d6c659-b63c-44fe-b9bc-3d6bb1367a79', 'State House District 28', 'Representative', 1, '20261103ME20702', '174193', 'Gordon P. Street', 'Gordon', 'Street', false, false, 'Dem', 1388, 32.98, false, true, 'lost', NULL, NULL, NULL),
  ('3d73eba8-0168-46a8-b856-227c46c8bd05', 'd77160bf-a9e2-4331-b750-803a6b56dbbf', 'State House District 30', 'Representative', 1, '20261103ME20706', '174197', 'John Contreni', 'John', 'Contreni', false, false, 'Dem', 1446, 33.67, false, true, 'lost', NULL, NULL, NULL),
  ('3d73eba8-0168-46a8-b856-227c46c8bd05', 'd77160bf-a9e2-4331-b750-803a6b56dbbf', 'State House District 30', 'Representative', 1, '20261103ME20706', '121824', 'James L. White', 'James', 'White', false, true, 'GOP', 2848, 66.33, false, true, 'won', 'cfa073a3-70af-4552-ae30-7c3236137cf0'::uuid, 'holder-exact-first-last', 'James White'),
  ('24132b9c-f927-483d-9e9f-abea802a2cab', '334dd517-72ac-4556-b396-621d89020e27', 'State House District 31', 'Representative', 1, '20261103ME20707', '174198', 'Eric J. Boothroyd', 'Eric', 'Boothroyd', false, false, 'Dem', 1460, 38.61, false, true, 'lost', NULL, NULL, NULL),
  ('24132b9c-f927-483d-9e9f-abea802a2cab', '334dd517-72ac-4556-b396-621d89020e27', 'State House District 31', 'Representative', 1, '20261103ME20707', '174199', 'Andrew R. Torbett', 'Andrew', 'Torbett', false, false, 'GOP', 2321, 61.39, false, true, 'won', NULL, NULL, NULL),
  ('8c6b6045-9900-416a-9521-9b7967495edb', 'ddd3da71-30bb-4d2b-a7e8-0796a9e138ee', 'State House District 32', 'Representative', 1, '20261103ME20705', '174200', 'Shawn L. Lancaster', 'Shawn', 'Lancaster', false, false, 'GOP', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('1431c4ab-5f8e-4ddb-8f04-5b93e6e0f631', '45ca7792-8dc7-46e3-80a0-7c98ea9c1562', 'State House District 33', 'Representative', 1, '20261103ME20708', '174201', 'Michael A. Brayson', 'Michael', 'Brayson', false, false, 'Dem', 1179, 31.17, false, true, 'lost', NULL, NULL, NULL),
  ('1431c4ab-5f8e-4ddb-8f04-5b93e6e0f631', '45ca7792-8dc7-46e3-80a0-7c98ea9c1562', 'State House District 33', 'Representative', 1, '20261103ME20708', '66373', 'Kenneth Wade Fredette', 'Kenneth', 'Fredette', false, true, 'GOP', 2604, 68.83, false, true, 'won', '2c454f77-c706-491c-87d5-0796b59371d4'::uuid, 'holder-exact-first-last', 'Kenneth Fredette'),
  ('76c3313e-d389-4254-8152-2881682cc894', 'f4ed555b-f848-4233-ae68-4cc9a9c3841d', 'State House District 34', 'Representative', 1, '20261103ME20710', '119911', 'Stacey K. Guerin', 'Stacey', 'Guerin', false, false, 'GOP', 3051, 68.44, false, true, 'won', NULL, NULL, NULL),
  ('76c3313e-d389-4254-8152-2881682cc894', 'f4ed555b-f848-4233-ae68-4cc9a9c3841d', 'State House District 34', 'Representative', 1, '20261103ME20710', '174202', 'James P. McClymer', 'James', 'McClymer', false, false, 'Dem', 1407, 31.56, false, true, 'lost', NULL, NULL, NULL),
  ('6eea79be-c33f-4c04-9d5e-9b25c17b6ec4', '4a833f85-134a-41dd-bd35-89671d1b12c6', 'State House District 35', 'Representative', 1, '20261103ME20711', '174203', 'Debora S. Farnham', 'Debora', 'Farnham', false, false, 'Dem', 1948, 38.91, false, true, 'lost', NULL, NULL, NULL),
  ('6eea79be-c33f-4c04-9d5e-9b25c17b6ec4', '4a833f85-134a-41dd-bd35-89671d1b12c6', 'State House District 35', 'Representative', 1, '20261103ME20711', '121564', 'James E. Thorne', 'James', 'Thorne', false, true, 'GOP', 3059, 61.09, false, true, 'won', 'ecb8eddd-c6e2-4e90-a239-d98f4d7e0542'::uuid, 'holder-exact-first-last', 'James Thorne'),
  ('8084e6b5-28c0-479e-8d04-b0bdf4f43a2b', '6f6f4051-dbd0-426b-9783-bf489c317e80', 'State House District 36', 'Representative', 1, '20261103ME20712', '174205', 'Clifton Guy Foster III', 'Clifton', 'Foster', false, false, 'Dem', 2260, 43.07, false, true, 'lost', NULL, NULL, NULL),
  ('8084e6b5-28c0-479e-8d04-b0bdf4f43a2b', '6f6f4051-dbd0-426b-9783-bf489c317e80', 'State House District 36', 'Representative', 1, '20261103ME20712', '162162', 'Kimberly M. Haggan', 'Kimberly', 'Haggan', false, true, 'GOP', 2987, 56.93, false, true, 'won', '1c64f6b9-cd4e-4482-9208-4d8fa74ad9e2'::uuid, 'holder-exact-first-last', 'Kimberly Haggan'),
  ('b34e3448-398b-4fe0-bc6b-b3e150289793', '2e58c467-58d4-4b64-98a1-8afbf8a18e2f', 'State House District 37', 'Representative', 1, '20261103ME20713', '174206', 'Alan Lee Orcutt', 'Alan', 'Orcutt', false, false, 'Dem', 2525, 48.27, false, true, 'lost', NULL, NULL, NULL),
  ('b34e3448-398b-4fe0-bc6b-b3e150289793', '2e58c467-58d4-4b64-98a1-8afbf8a18e2f', 'State House District 37', 'Representative', 1, '20261103ME20713', '121834', 'Reagan L. Paul', 'Reagan', 'Paul', false, true, 'GOP', 2706, 51.73, false, true, 'won', 'cce50333-2b4e-48f0-987c-7d1b579ee691'::uuid, 'holder-exact-first-last', 'Reagan Paul'),
  ('a77dcc13-c563-4e09-8c96-c4f6ba68cc42', '67859fbe-c457-4442-a159-00f1cfc51627', 'State House District 38', 'Representative', 1, '20261103ME20714', '121840', 'Benjamin C. Hymes', 'Benjamin', 'Hymes', false, true, 'GOP', 2342, 53.39, false, true, 'won', 'ee45697c-6dc7-4789-bfe0-c97a34835e6e'::uuid, 'holder-exact-first-last', 'Benjamin Hymes'),
  ('a77dcc13-c563-4e09-8c96-c4f6ba68cc42', '67859fbe-c457-4442-a159-00f1cfc51627', 'State House District 38', 'Representative', 1, '20261103ME20714', '174207', 'Kayla M.T. Miller', 'Kayla', 'Miller', false, false, 'Dem', 2045, 46.61, false, true, 'lost', NULL, NULL, NULL),
  ('fb9cffa7-0507-469d-9cc2-cafca8564f14', 'f9b096e5-1abc-4da0-88fd-9955cb82a8e5', 'State House District 39', 'Representative', 1, '20261103ME20715', '174208', 'Madison Crissey Cook', 'Madison', 'Cook', false, false, 'Dem', 3727, 69.85, false, true, 'won', NULL, NULL, NULL),
  ('fb9cffa7-0507-469d-9cc2-cafca8564f14', 'f9b096e5-1abc-4da0-88fd-9955cb82a8e5', 'State House District 39', 'Representative', 1, '20261103ME20715', '174209', 'Michael J. Nicholson', 'Michael', 'Nicholson', false, false, 'GOP', 1609, 30.15, false, true, 'lost', NULL, NULL, NULL),
  ('5ae48629-c5dd-47e8-ac10-d7ef51618ada', '001b4436-2713-427f-b166-0e63f92d3d3f', 'State House District 40', 'Representative', 1, '20261103ME20716', '122072', 'Joseph M. McLaughlin', 'Joseph', 'McLaughlin', false, false, 'GOP', 2238, 41.34, false, true, 'lost', NULL, NULL, NULL),
  ('5ae48629-c5dd-47e8-ac10-d7ef51618ada', '001b4436-2713-427f-b166-0e63f92d3d3f', 'State House District 40', 'Representative', 1, '20261103ME20716', '162164', 'D. Michael Ray', 'D. Michael', 'Ray', false, true, 'Dem', 3175, 58.66, false, true, 'won', 'bf3d8a5d-f5a6-4bfa-b144-513898d12ed5'::uuid, 'holder-exact-full-name', 'D. Michael Ray'),
  ('b628c36e-49d4-4a8e-9255-31ab6836face', 'c7fae8ff-3f94-46ea-9b60-831db046ffa0', 'State House District 41', 'Representative', 1, '20261103ME20717', '174210', 'Joshua D. Gerritsen', 'Joshua', 'Gerritsen', false, false, 'Dem', 4300, 76.58, false, true, 'won', NULL, NULL, NULL),
  ('b628c36e-49d4-4a8e-9255-31ab6836face', 'c7fae8ff-3f94-46ea-9b60-831db046ffa0', 'State House District 41', 'Representative', 1, '20261103ME20717', '162165', 'Cory Christopher Raymond', 'Cory', 'Raymond', false, false, 'GOP', 1315, 23.42, false, true, 'lost', NULL, NULL, NULL),
  ('14de4130-2f1e-49dd-ac53-39b330dc3a59', '1aaf92b4-8544-498d-88a8-fe69b366fe32', 'State House District 42', 'Representative', 1, '20261103ME20718', '174212', 'Melissa Joy Byer', 'Melissa', 'Byer', false, false, 'GOP', 1407, 31.36, false, true, 'lost', NULL, NULL, NULL),
  ('14de4130-2f1e-49dd-ac53-39b330dc3a59', '1aaf92b4-8544-498d-88a8-fe69b366fe32', 'State House District 42', 'Representative', 1, '20261103ME20718', '121557', 'Valli D. Geiger', 'Valli', 'Geiger', false, true, 'Dem', 3079, 68.64, false, true, 'won', '73f801b5-b71b-4f01-9043-9dc2638049ff'::uuid, 'holder-exact-first-last', 'Valli Geiger'),
  ('4e2d044c-f258-4357-b8e2-ba8cd76f1244', 'c8915162-7dbc-4f10-8801-38352d528dac', 'State House District 43', 'Representative', 1, '20261103ME20721', '174215', 'Christopher Paul Austin', 'Christopher', 'Austin', false, false, 'GOP', 2155, 42.55, false, true, 'lost', NULL, NULL, NULL),
  ('4e2d044c-f258-4357-b8e2-ba8cd76f1244', 'c8915162-7dbc-4f10-8801-38352d528dac', 'State House District 43', 'Representative', 1, '20261103ME20721', '174213', 'Rhiannon Corey Hampson', 'Rhiannon', 'Hampson', false, false, 'Dem', 2910, 57.45, false, true, 'won', NULL, NULL, NULL),
  ('af85aaa6-8996-47e3-8f60-37b63974b4e1', '7b545b37-325d-4245-a51b-10f25b918dea', 'State House District 44', 'Representative', 1, '20261103ME20723', '177861', 'Shawn Saindon', 'Shawn', 'Saindon', false, false, 'Ind', 1924, 51.71, false, true, 'won', NULL, NULL, NULL),
  ('af85aaa6-8996-47e3-8f60-37b63974b4e1', '7b545b37-325d-4245-a51b-10f25b918dea', 'State House District 44', 'Representative', 1, '20261103ME20723', '162167', 'Ray A. Thombs Jr.', 'Ray', 'Thombs', false, false, 'GOP', 1797, 48.29, false, true, 'lost', NULL, NULL, NULL),
  ('c2e43839-24d0-4b0b-9468-dfa9286df6c7', '0ccac3b9-f107-419b-9051-a9b04375ce54', 'State House District 45', 'Representative', 1, '20261103ME20722', '121856', 'Clinton E. Collamore', 'Clinton', 'Collamore', false, false, 'Ind', 2392, 51.83, false, true, 'won', NULL, NULL, NULL),
  ('c2e43839-24d0-4b0b-9468-dfa9286df6c7', '0ccac3b9-f107-419b-9051-a9b04375ce54', 'State House District 45', 'Representative', 1, '20261103ME20722', '174218', 'Rebecca M. Stephens', 'Rebecca', 'Stephens', false, false, 'GOP', 2223, 48.17, false, true, 'lost', NULL, NULL, NULL),
  ('00fc6080-468c-4772-b9dd-22096e61551e', '0683ecd5-d1ac-4bc0-bc8f-0f4197df0ce4', 'State House District 46', 'Representative', 1, '20261103ME20766', '174219', 'Jennifer F. Mayher', 'Jennifer', 'Mayher', false, false, 'Dem', 3430, 58.72, false, true, 'won', NULL, NULL, NULL),
  ('00fc6080-468c-4772-b9dd-22096e61551e', '0683ecd5-d1ac-4bc0-bc8f-0f4197df0ce4', 'State House District 46', 'Representative', 1, '20261103ME20766', '177862', 'Kristine A. Poland', 'Kristine', 'Poland', false, false, 'Ind', 2411, 41.28, false, true, 'lost', NULL, NULL, NULL),
  ('3e353694-24ea-459c-8bbd-a698d2ee94eb', '2ff5391e-43c5-45e2-aec4-5a20172a7212', 'State House District 47', 'Representative', 1, '20261103ME20725', '121547', 'Wayne K. Farrin', 'Wayne', 'Farrin', false, true, 'Dem', 2861, 52.53, false, true, 'won', '2d5859a0-18ba-42d2-b272-fb9acd9890a1'::uuid, 'holder-exact-first-last', 'Wayne Farrin'),
  ('3e353694-24ea-459c-8bbd-a698d2ee94eb', '2ff5391e-43c5-45e2-aec4-5a20172a7212', 'State House District 47', 'Representative', 1, '20261103ME20725', '174220', 'Chester B. Grover III', 'Chester', 'Grover', false, false, 'GOP', 2585, 47.47, false, true, 'lost', NULL, NULL, NULL),
  ('7343d8b7-b212-4be1-abda-ca4c97f1e7e7', 'e8ef2c54-29be-44ab-a482-e554af324670', 'State House District 48', 'Representative', 1, '20261103ME20729', '174221', 'Erik D. Hobson', 'Erik', 'Hobson', false, false, 'GOP', 2120, 37.55, false, true, 'lost', NULL, NULL, NULL),
  ('7343d8b7-b212-4be1-abda-ca4c97f1e7e7', 'e8ef2c54-29be-44ab-a482-e554af324670', 'State House District 48', 'Representative', 1, '20261103ME20729', '167361', 'Charlotte Nutt', 'Charlotte', 'Nutt', false, false, 'Dem', 3526, 62.45, false, true, 'won', NULL, NULL, NULL),
  ('74d0e215-a43e-4af7-b8d1-e355d1d7202b', '638c38eb-f1bb-49bd-a861-bf7c85a2953d', 'State House District 49', 'Representative', 1, '20261103ME20730', '174223', 'Suzanne R. Andresen', 'Suzanne', 'Andresen', false, false, 'GOP', 2653, 44.97, false, true, 'lost', NULL, NULL, NULL),
  ('74d0e215-a43e-4af7-b8d1-e355d1d7202b', '638c38eb-f1bb-49bd-a861-bf7c85a2953d', 'State House District 49', 'Representative', 1, '20261103ME20730', '174222', 'Trent E. Vellella', 'Trent', 'Vellella', false, false, 'Dem', 3246, 55.03, false, true, 'won', NULL, NULL, NULL),
  ('3855c275-daab-4107-8c1e-89e2ecbbcd01', '0626dc02-5c03-48ad-bbc2-910fa0e17814', 'State House District 50', 'Representative', 1, '20261103ME20731', '174225', 'Jedediah James Rice II', 'Jedediah', 'Rice', false, false, 'GOP', 1196, 26.08, false, true, 'lost', NULL, NULL, NULL),
  ('3855c275-daab-4107-8c1e-89e2ecbbcd01', '0626dc02-5c03-48ad-bbc2-910fa0e17814', 'State House District 50', 'Representative', 1, '20261103ME20731', '72920', 'David A. Sinclair', 'David', 'Sinclair', false, true, 'Dem', 3390, 73.92, false, true, 'won', '0316ee2f-fe0c-4122-a95a-2f43f55ce260'::uuid, 'holder-exact-first-last', 'David Sinclair'),
  ('a020a072-5deb-4b87-ab28-9677c102f8a9', 'f864ab92-099a-4d13-8c83-7f7ff975a636', 'State House District 51', 'Representative', 1, '20261103ME20732', '162173', 'Rafael Macias', 'Rafael', 'Macias', false, true, 'Dem', 3513, 65.06, false, true, 'won', 'c08c1cf6-c505-4490-a1a3-be7945b8f2f2'::uuid, 'holder-exact-full-name', 'Rafael Macias'),
  ('a020a072-5deb-4b87-ab28-9677c102f8a9', 'f864ab92-099a-4d13-8c83-7f7ff975a636', 'State House District 51', 'Representative', 1, '20261103ME20732', '174227', 'Annalyse O. Sarvinas', 'Annalyse', 'Sarvinas', false, false, 'GOP', 1887, 34.94, false, true, 'lost', NULL, NULL, NULL),
  ('ff53c174-008c-4d28-a432-a423416e7e20', '4cd21d42-7ccd-4fc3-bbd6-742102551740', 'State House District 52', 'Representative', 1, '20261103ME20736', '122076', 'Sally Jeane Cluchey', 'Sally Jeane', 'Cluchey', false, true, 'Dem', 2651, 53.25, false, true, 'won', '8b288fec-b935-40b3-a7b1-ecb65d184b51'::uuid, 'holder-surname-plus-roster', 'Sally Cluchey'),
  ('ff53c174-008c-4d28-a432-a423416e7e20', '4cd21d42-7ccd-4fc3-bbd6-742102551740', 'State House District 52', 'Representative', 1, '20261103ME20736', '162174', 'David W. Guilmette', 'David', 'Guilmette', false, false, 'GOP', 2327, 46.75, false, true, 'lost', NULL, NULL, NULL),
  ('604e9c31-e79d-4c0d-a588-33177e1c2306', '41d4eefb-a086-4efe-8b68-23679520d9af', 'State House District 53', 'Representative', 1, '20261103ME20739', '162176', 'Richard Marc Goldman', 'Richard', 'Goldman', false, false, 'Dem', 2160, 45.54, false, true, 'lost', NULL, NULL, NULL),
  ('604e9c31-e79d-4c0d-a588-33177e1c2306', '41d4eefb-a086-4efe-8b68-23679520d9af', 'State House District 53', 'Representative', 1, '20261103ME20739', '121076', 'Michael H. Lemelin', 'Michael', 'Lemelin', false, true, 'GOP', 2583, 54.46, false, true, 'won', '8b1dca67-2cfa-456f-81b0-27cab1690388'::uuid, 'holder-exact-first-last', 'Michael Lemelin'),
  ('4fa067fc-4796-4f40-afb9-a5e31ab91092', 'ded9f90f-429e-45d9-a231-e98ba5772dec', 'State House District 54', 'Representative', 1, '20261103ME20733', '121870', 'Karen L. Montell', 'Karen', 'Montell', false, true, 'Dem', 2734, 61.49, false, true, 'won', '54600569-46e8-4830-88c1-c86cabed4488'::uuid, 'holder-exact-first-last', 'Karen Montell'),
  ('4fa067fc-4796-4f40-afb9-a5e31ab91092', 'ded9f90f-429e-45d9-a231-e98ba5772dec', 'State House District 54', 'Representative', 1, '20261103ME20733', '174228', 'Michelle M. Tucker', 'Michelle', 'Tucker', false, false, 'GOP', 1712, 38.51, false, true, 'lost', NULL, NULL, NULL),
  ('6b478c0e-19b7-41da-916f-2a67804ec6c9', '465f0785-a507-4170-b16f-a674f7d106a8', 'State House District 55', 'Representative', 1, '20261103ME20734', '174229', 'Maureen AuCoin', 'Maureen', 'AuCoin', false, false, 'Dem', 2887, 52.97, false, true, 'won', NULL, NULL, NULL),
  ('6b478c0e-19b7-41da-916f-2a67804ec6c9', '465f0785-a507-4170-b16f-a674f7d106a8', 'State House District 55', 'Representative', 1, '20261103ME20734', '174231', 'Charles L. Hippler IV', 'Charles', 'Hippler', false, false, 'GOP', 2563, 47.03, false, true, 'lost', NULL, NULL, NULL),
  ('264a1228-d12f-4284-aba4-4b52ec1eb4c0', 'd77b3e20-85b6-4528-a081-4b4f1acbe260', 'State House District 56', 'Representative', 1, '20261103ME20765', '120422', 'Randall Adam Greenwood', 'Randall', 'Greenwood', false, true, 'GOP', 3127, 62.14, false, true, 'won', '85a1ae07-3743-4192-b516-b04f6035440a'::uuid, 'holder-exact-first-last', 'Randall Greenwood'),
  ('264a1228-d12f-4284-aba4-4b52ec1eb4c0', 'd77b3e20-85b6-4528-a081-4b4f1acbe260', 'State House District 56', 'Representative', 1, '20261103ME20765', '174233', 'Robin L. Upton-Sukeforth', 'Robin', 'Upton-Sukeforth', false, false, 'Dem', 1905, 37.86, false, true, 'lost', NULL, NULL, NULL),
  ('911b9ad6-7e35-4428-9823-37f002319271', '646f00a8-6fbf-46d8-8db1-8dc3d2fabc49', 'State House District 57', 'Representative', 1, '20261103ME20790', '121540', 'Tavis Rock Hasenfus', 'Tavis', 'Hasenfus', false, true, 'Dem', 2967, 59.55, false, true, 'won', '0c1b5005-e1e5-4ba1-9e85-ce858371cd6e'::uuid, 'holder-exact-first-last', 'Tavis Hasenfus'),
  ('911b9ad6-7e35-4428-9823-37f002319271', '646f00a8-6fbf-46d8-8db1-8dc3d2fabc49', 'State House District 57', 'Representative', 1, '20261103ME20790', '162178', 'David R. Potvin', 'David', 'Potvin', false, false, 'GOP', 2015, 40.45, false, true, 'lost', NULL, NULL, NULL),
  ('5175e8f6-2907-49b7-bf79-0d595fd8adac', 'cf97d3ed-37bd-4439-a15b-140dfb3818f0', 'State House District 58', 'Representative', 1, '20261103ME20767', '174236', 'Dexter E. Bridges Jr.', 'Dexter', 'Bridges', false, false, 'GOP', 2506, 45, false, true, 'lost', NULL, NULL, NULL),
  ('5175e8f6-2907-49b7-bf79-0d595fd8adac', 'cf97d3ed-37bd-4439-a15b-140dfb3818f0', 'State House District 58', 'Representative', 1, '20261103ME20767', '167347', 'Sharon C. Frost', 'Sharon', 'Frost', false, true, 'Ind', 3063, 55, false, true, 'won', '7e3b308c-05e2-4109-91c0-cae55bba4534'::uuid, 'holder-exact-first-last', 'Sharon Frost'),
  ('d04379a4-bbcf-4880-886a-58bc602983cf', '5fcc3f80-cd90-4dbb-aded-177fc584da34', 'State House District 59', 'Representative', 1, '20261103ME20768', '174238', 'Katrina Couch Ray-Saulis', 'Katrina', 'Couch Ray-Saulis', false, false, 'Dem', 2287, 55.55, false, true, 'won', NULL, NULL, NULL),
  ('d04379a4-bbcf-4880-886a-58bc602983cf', '5fcc3f80-cd90-4dbb-aded-177fc584da34', 'State House District 59', 'Representative', 1, '20261103ME20768', '174240', 'John Reny', 'John', 'Reny', false, false, 'GOP', 1830, 44.45, false, true, 'lost', NULL, NULL, NULL),
  ('784c5e8b-4c8d-4f17-ac23-98e1a5259436', '81eb8e10-1378-4d27-9be4-b590c8399042', 'State House District 60', 'Representative', 1, '20261103ME20769', '174241', 'Wyatt Albert Beaulieu', 'Wyatt', 'Beaulieu', false, false, 'GOP', 1699, 40.69, false, true, 'lost', NULL, NULL, NULL),
  ('784c5e8b-4c8d-4f17-ac23-98e1a5259436', '81eb8e10-1378-4d27-9be4-b590c8399042', 'State House District 60', 'Representative', 1, '20261103ME20769', '121887', 'William R. Bridgeo', 'William', 'Bridgeo', false, true, 'Dem', 2476, 59.31, false, true, 'won', '6ad1021e-5f98-4215-a879-a9b76a57b9e3'::uuid, 'holder-exact-first-last', 'William Bridgeo'),
  ('76b97456-54d5-425b-9aa6-acf398666ceb', '0721cf0f-6134-4e9e-91dc-b160291e5219', 'State House District 61', 'Representative', 1, '20261103ME20770', '162183', 'Alicia Carol Collins', 'Alicia', 'Collins', false, true, 'GOP', 2829, 59.8, false, true, 'won', 'ac47488f-8044-4f39-a33e-0e3ff1c450fb'::uuid, 'holder-exact-first-last', 'Alicia Collins'),
  ('76b97456-54d5-425b-9aa6-acf398666ceb', '0721cf0f-6134-4e9e-91dc-b160291e5219', 'State House District 61', 'Representative', 1, '20261103ME20770', '174242', 'Robin G. Crawley', 'Robin', 'Crawley', false, false, 'Dem', 1902, 40.2, false, true, 'lost', NULL, NULL, NULL),
  ('204b6e9f-86a5-467d-a71f-37aae9a4fb67', '6ea259ae-959f-46f4-bb78-a56e7d03912c', 'State House District 62', 'Representative', 1, '20261103ME20754', '121559', 'Katrina J. Smith', 'Katrina', 'Smith', false, true, 'GOP', 2677, 60.43, false, true, 'won', '05b465cb-f538-4a17-bb47-a12e4409b62b'::uuid, 'holder-exact-first-last', 'Katrina Smith'),
  ('204b6e9f-86a5-467d-a71f-37aae9a4fb67', '6ea259ae-959f-46f4-bb78-a56e7d03912c', 'State House District 62', 'Representative', 1, '20261103ME20754', '121889', 'Pamela Jo Swift', 'Pamela', 'Swift', false, false, 'Dem', 1753, 39.57, false, true, 'lost', NULL, NULL, NULL),
  ('e22124ad-7f51-4b02-844e-35491f63f2e5', '4ce94413-b291-44db-bf83-b8330b422f2a', 'State House District 63', 'Representative', 1, '20261103ME20755', '162185', 'Paul R. Flynn', 'Paul', 'Flynn', false, true, 'GOP', 2690, 54.81, false, true, 'won', 'a793b036-460a-4752-961f-53d460f8130a'::uuid, 'holder-exact-first-last', 'Paul Flynn'),
  ('e22124ad-7f51-4b02-844e-35491f63f2e5', '4ce94413-b291-44db-bf83-b8330b422f2a', 'State House District 63', 'Representative', 1, '20261103ME20755', '174243', 'Taylor Marie West', 'Taylor', 'West', false, false, 'Dem', 2218, 45.19, false, true, 'lost', NULL, NULL, NULL),
  ('38b57af6-5099-40bc-bdce-cec073e4f9f3', '06684913-790e-46d7-ac10-e18dd871d761', 'State House District 64', 'Representative', 1, '20261103ME20753', '162187', 'Flavia M. DeBrito', 'Flavia', 'DeBrito', false, true, 'Dem', 2367, 69.76, false, true, 'won', '21f45688-4e19-42bb-b1c0-e17b5dba2d3a'::uuid, 'holder-exact-first-last', 'Flavia DeBrito'),
  ('38b57af6-5099-40bc-bdce-cec073e4f9f3', '06684913-790e-46d7-ac10-e18dd871d761', 'State House District 64', 'Representative', 1, '20261103ME20753', '174244', 'Shawn M. Packard', 'Shawn', 'Packard', false, false, 'GOP', 1026, 30.24, false, true, 'lost', NULL, NULL, NULL),
  ('b5381f7f-784d-49ce-a0b9-60e1c924fee5', 'fc5c6de0-dcec-4e78-8a87-e15ffccfb6b0', 'State House District 65', 'Representative', 1, '20261103ME20719', '162189', 'Cassie Lynn Julia', 'Cassie', 'Julia', false, true, 'Dem', 2138, 65.26, false, true, 'won', 'ad28f54e-0639-4005-ade9-3be3b90c3d39'::uuid, 'holder-exact-first-last', 'Cassie Julia'),
  ('b5381f7f-784d-49ce-a0b9-60e1c924fee5', 'fc5c6de0-dcec-4e78-8a87-e15ffccfb6b0', 'State House District 65', 'Representative', 1, '20261103ME20719', '178679', 'Jeremy R. McArthur', 'Jeremy', 'McArthur', false, false, 'GOP', 1138, 34.74, false, true, 'lost', NULL, NULL, NULL),
  ('ddf24079-12e2-48e6-b8e5-30bd8616b0a6', '584cc0de-2a95-495d-8403-7fd9916d074a', 'State House District 66', 'Representative', 1, '20261103ME20752', '120726', 'Michael D. Perkins', 'Michael', 'Perkins', false, false, 'GOP', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('56e252fe-fe4b-463a-bc08-e81521510aab', 'd48a879f-cfe9-4a58-9bb9-a478292c53b0', 'State House District 67', 'Representative', 1, '20261103ME20745', '174245', 'Shawn M. Dixon', 'Shawn', 'Dixon', false, false, 'GOP', 2242, 53.73, false, true, 'won', NULL, NULL, NULL),
  ('56e252fe-fe4b-463a-bc08-e81521510aab', 'd48a879f-cfe9-4a58-9bb9-a478292c53b0', 'State House District 67', 'Representative', 1, '20261103ME20745', '162191', 'Matthew C. Townsend', 'Matthew', 'Townsend', false, false, 'Dem', 1931, 46.27, false, true, 'lost', NULL, NULL, NULL),
  ('e2dc6e0b-d9f3-46a6-93e5-af417685ffb4', 'a7806524-5f1c-4cf1-a2a7-d2c718563cee', 'State House District 68', 'Representative', 1, '20261103ME20728', '121567', 'Amanda Noelle Collamore', 'Amanda', 'Collamore', false, true, 'GOP', 2871, 72.39, false, true, 'won', 'ee2ff8c8-d9b6-46a3-a13e-d97b9fdc8cab'::uuid, 'holder-exact-first-last', 'Amanda Collamore'),
  ('e2dc6e0b-d9f3-46a6-93e5-af417685ffb4', 'a7806524-5f1c-4cf1-a2a7-d2c718563cee', 'State House District 68', 'Representative', 1, '20261103ME20728', '177863', 'Zachary S. Lejonhud', 'Zachary', 'Lejonhud', false, false, 'Unr', 1095, 27.61, false, true, 'lost', NULL, NULL, NULL),
  ('81d204f6-b2fc-4c58-a054-833ae17985a6', 'bfc4fb4e-daf9-4bd5-b7fb-796eaa20fa42', 'State House District 69', 'Representative', 1, '20261103ME20727', '167348', 'Jessica B. Blanchard', 'Jessica', 'Blanchard', false, false, 'Dem', 1202, 28.86, false, true, 'lost', NULL, NULL, NULL),
  ('81d204f6-b2fc-4c58-a054-833ae17985a6', 'bfc4fb4e-daf9-4bd5-b7fb-796eaa20fa42', 'State House District 69', 'Representative', 1, '20261103ME20727', '119916', 'Dean A. Cray', 'Dean', 'Cray', false, true, 'GOP', 2963, 71.14, false, true, 'won', 'fe465340-16b2-43c4-8d0a-d748b201f3d5'::uuid, 'holder-exact-first-last', 'Dean Cray'),
  ('7dff8165-62e1-4fe4-9391-6c8b0d9cd74d', 'c04c071b-4106-428d-b932-3e54b1d2972f', 'State House District 70', 'Representative', 1, '20261103ME20726', '174246', 'Joseph R. Almand', 'Joseph', 'Almand', false, false, 'Dem', 1594, 46.07, false, true, 'lost', NULL, NULL, NULL),
  ('7dff8165-62e1-4fe4-9391-6c8b0d9cd74d', 'c04c071b-4106-428d-b932-3e54b1d2972f', 'State House District 70', 'Representative', 1, '20261103ME20726', '121568', 'Jennifer Lynn Poirier', 'Jennifer', 'Poirier', false, true, 'GOP', 1866, 53.93, false, true, 'won', 'f4c74fad-1aa0-46d3-98ea-f377f4e639ba'::uuid, 'holder-exact-first-last', 'Jennifer Poirier'),
  ('852ab52e-744b-4a92-a52f-a0289d3f0d18', 'ac59e263-d8d5-4d41-8e02-ef46c27b433f', 'State House District 71', 'Representative', 1, '20261103ME20749', '121572', 'John E. Ducharme III', 'John', 'Ducharme', false, true, 'GOP', 0, 0, true, true, 'won', 'dc6a829a-5501-4f63-9d34-fa5210b80fc2'::uuid, 'holder-exact-first-last', 'John Ducharme'),
  ('5f5cd230-3b9d-4cb8-a936-99c045e0e0f2', 'a450cb67-e476-4461-adcd-39b52edda991', 'State House District 72', 'Representative', 1, '20261103ME20756', '121132', 'Cynthia J. Soma-Hernandez', 'Cynthia', 'Soma-Hernandez', false, false, 'Dem', 1242, 34.77, false, true, 'lost', NULL, NULL, NULL),
  ('5f5cd230-3b9d-4cb8-a936-99c045e0e0f2', 'a450cb67-e476-4461-adcd-39b52edda991', 'State House District 72', 'Representative', 1, '20261103ME20756', '119912', 'Douglas Andrew Thomas', 'Douglas', 'Thomas', false, false, 'GOP', 2330, 65.23, false, true, 'won', NULL, NULL, NULL),
  ('bebb30db-384a-4fac-b127-4c87e56570f4', '9e704a15-6aea-4395-8d9a-ceb2a371e3ce', 'State House District 73', 'Representative', 1, '20261103ME20750', '174247', 'Daniel J. Simonds', 'Daniel', 'Simonds', false, false, 'Dem', 2166, 44.27, false, true, 'lost', NULL, NULL, NULL),
  ('bebb30db-384a-4fac-b127-4c87e56570f4', '9e704a15-6aea-4395-8d9a-ceb2a371e3ce', 'State House District 73', 'Representative', 1, '20261103ME20750', '121906', 'Michael Soboleski', 'Michael', 'Soboleski', false, true, 'GOP', 2727, 55.73, false, true, 'won', '78c675a3-137e-4d9c-bf85-38bdf7f45c51'::uuid, 'holder-exact-full-name', 'Michael Soboleski'),
  ('e509dbe1-cdad-4985-b3e8-c81e5a3ec666', '381992d1-2f56-46b3-bd7f-652dbc892fec', 'State House District 74', 'Representative', 1, '20261103ME20774', '120008', 'Russell J. Black', 'Russell', 'Black', false, false, 'GOP', 2896, 62.55, false, true, 'won', NULL, NULL, NULL),
  ('e509dbe1-cdad-4985-b3e8-c81e5a3ec666', '381992d1-2f56-46b3-bd7f-652dbc892fec', 'State House District 74', 'Representative', 1, '20261103ME20774', '174249', 'Marc Edwards', 'Marc', 'Edwards', false, false, 'Dem', 1734, 37.45, false, true, 'lost', NULL, NULL, NULL),
  ('155dd5cb-afb3-4555-b2ab-d4ea7969adc5', '1a3bd9b3-f59a-45d4-a0bf-0612777be082', 'State House District 75', 'Representative', 1, '20261103ME20784', '162196', 'Randall D. Gauvin', 'Randall', 'Gauvin', false, false, 'GOP', 1839, 45.16, false, true, 'lost', NULL, NULL, NULL),
  ('155dd5cb-afb3-4555-b2ab-d4ea7969adc5', '1a3bd9b3-f59a-45d4-a0bf-0612777be082', 'State House District 75', 'Representative', 1, '20261103ME20784', '120840', 'H. Scott Landry', 'H. Scott', 'Landry', false, false, 'Dem', 2233, 54.84, false, true, 'won', NULL, NULL, NULL),
  ('990d8dd4-333b-412d-a98c-0d93111b537c', '2c4e9a15-085d-4135-a153-c0a979af8dbf', 'State House District 76', 'Representative', 1, '20261103ME20761', '174250', 'Trevor Alex Doiron', 'Trevor', 'Doiron', false, false, 'Dem', 1942, 45.07, false, true, 'lost', NULL, NULL, NULL),
  ('990d8dd4-333b-412d-a98c-0d93111b537c', '2c4e9a15-085d-4135-a153-c0a979af8dbf', 'State House District 76', 'Representative', 1, '20261103ME20761', '121535', 'Sheila Ann Lyman', 'Sheila', 'Lyman', false, true, 'GOP', 2367, 54.93, false, true, 'won', '7a9ebcbf-d2fa-4ca0-a133-178fb0d6fce1'::uuid, 'holder-exact-first-last', 'Sheila Lyman'),
  ('05c118d0-7acc-4d95-bbd7-c0e6f54ee129', 'efc03618-6111-498f-b025-9483b0a1a4a9', 'State House District 77', 'Representative', 1, '20261103ME20759', '174251', 'Arlie E. Hetrick Jr.', 'Arlie', 'Hetrick', false, false, 'Dem', 1410, 33.76, false, true, 'lost', NULL, NULL, NULL),
  ('05c118d0-7acc-4d95-bbd7-c0e6f54ee129', 'efc03618-6111-498f-b025-9483b0a1a4a9', 'State House District 77', 'Representative', 1, '20261103ME20759', '121911', 'Tammy L. Schmersal-Burgess', 'Tammy', 'Schmersal-Burgess', false, true, 'GOP', 2766, 66.24, false, true, 'won', 'b08821e4-7a92-498c-97f2-13138777e8ae'::uuid, 'holder-exact-first-last', 'Tammy Schmersal-Burgess'),
  ('f6fff543-13b2-45e3-ba44-d8a9cc8b3174', 'b718ab60-38c7-4080-809e-3431a946c1a5', 'State House District 78', 'Representative', 1, '20261103ME20783', '122078', 'Rachel A. Henderson', 'Rachel', 'Henderson', false, true, 'GOP', 2137, 53.87, false, true, 'won', 'a37ec3f9-faa6-4c06-8856-92fa618a28ad'::uuid, 'holder-exact-first-last', 'Rachel Henderson'),
  ('f6fff543-13b2-45e3-ba44-d8a9cc8b3174', 'b718ab60-38c7-4080-809e-3431a946c1a5', 'State House District 78', 'Representative', 1, '20261103ME20783', '174253', 'Woodleigh H. Hughes', 'Woodleigh', 'Hughes', false, false, 'Dem', 1830, 46.13, false, true, 'lost', NULL, NULL, NULL),
  ('317a8980-e94a-4206-abc4-fc5aeaa0c8b6', 'cb1ce008-463f-491e-9d0e-bf97c9b9816b', 'State House District 79', 'Representative', 1, '20261103ME20787', '162200', 'Michael J. Lance', 'Michael', 'Lance', false, true, 'GOP', 2522, 56.83, false, true, 'won', '6f9a255b-0f39-4907-8b96-682a59b91f39'::uuid, 'holder-exact-first-last', 'Michael Lance'),
  ('317a8980-e94a-4206-abc4-fc5aeaa0c8b6', 'cb1ce008-463f-491e-9d0e-bf97c9b9816b', 'State House District 79', 'Representative', 1, '20261103ME20787', '174254', 'Brianna Fern Lueck', 'Brianna', 'Lueck', false, false, 'Dem', 1916, 43.17, false, true, 'lost', NULL, NULL, NULL),
  ('f7f51113-944c-429e-a417-f89c9c6eb763', '3823fd51-eed9-4606-b3a6-1f5f9fcc3e34', 'State House District 80', 'Representative', 1, '20261103ME20775', '177864', 'Azalea D. Cormier', 'Azalea', 'Cormier', false, false, 'Unr', 1781, 37.34, false, true, 'lost', NULL, NULL, NULL),
  ('f7f51113-944c-429e-a417-f89c9c6eb763', '3823fd51-eed9-4606-b3a6-1f5f9fcc3e34', 'State House District 80', 'Representative', 1, '20261103ME20775', '174255', 'Ernest M. Fitts IV', 'Ernest', 'Fitts', false, false, 'GOP', 2989, 62.66, false, true, 'won', NULL, NULL, NULL),
  ('86a90cd1-ee22-40b5-b43f-0b7e0ec506ba', 'f3ff04d7-3e8e-43d0-a97c-88f53499b2e2', 'State House District 81', 'Representative', 1, '20261103ME20771', '174257', 'Christopher A. Easton', 'Christopher', 'Easton', false, false, 'Dem', 2634, 52.61, false, true, 'won', NULL, NULL, NULL),
  ('86a90cd1-ee22-40b5-b43f-0b7e0ec506ba', 'f3ff04d7-3e8e-43d0-a97c-88f53499b2e2', 'State House District 81', 'Representative', 1, '20261103ME20771', '162203', 'Peter C. Wood', 'Peter', 'Wood', false, true, 'GOP', 2373, 47.39, false, true, 'lost', 'c6b1a2ed-c20a-44ef-b9b0-58de24c5f837'::uuid, 'holder-exact-first-last', 'Peter Wood'),
  ('d36ed4ee-f6b9-4f1f-b4ad-2a64e8c96784', '1e260e08-d77a-4c16-87f4-ed8afcf42ed7', 'State House District 82', 'Representative', 1, '20261103ME20764', '174258', 'Christopher Alfred Lewey', 'Christopher', 'Lewey', false, false, 'Dem', 2453, 51.14, false, true, 'won', NULL, NULL, NULL),
  ('d36ed4ee-f6b9-4f1f-b4ad-2a64e8c96784', '1e260e08-d77a-4c16-87f4-ed8afcf42ed7', 'State House District 82', 'Representative', 1, '20261103ME20764', '121919', 'Caleb J. Ness', 'Caleb', 'Ness', false, false, 'GOP', 2344, 48.86, false, true, 'lost', NULL, NULL, NULL),
  ('3c170758-d782-4682-ab0f-1493dadda90f', '0c0a4a37-681d-4120-8485-accb518f880b', 'State House District 83', 'Representative', 1, '20261103ME20763', '174259', 'Timothy J. Becker', 'Timothy', 'Becker', false, false, 'Dem', 2754, 52.61, false, true, 'won', NULL, NULL, NULL),
  ('3c170758-d782-4682-ab0f-1493dadda90f', '0c0a4a37-681d-4120-8485-accb518f880b', 'State House District 83', 'Representative', 1, '20261103ME20763', '162206', 'Marygrace Caroline Cimino', 'Marygrace', 'Cimino', false, true, 'GOP', 2481, 47.39, false, true, 'lost', '26fa2e76-137e-4ace-b40a-fc49105c2a05'::uuid, 'holder-exact-first-last', 'Marygrace Cimino'),
  ('9a35e169-195e-4ee3-b494-52e0d5f01526', '0ae4db41-9b46-4a0c-a4a4-8ddebc3a7667', 'State House District 84', 'Representative', 1, '20261103ME20778', '162207', 'Cassandra Anne Dove', 'Cassandra', 'Dove', false, false, 'Dem', 2086, 42.44, false, true, 'lost', NULL, NULL, NULL),
  ('9a35e169-195e-4ee3-b494-52e0d5f01526', '0ae4db41-9b46-4a0c-a4a4-8ddebc3a7667', 'State House District 84', 'Representative', 1, '20261103ME20778', '121376', 'Mark Walker', 'Mark', 'Walker', false, true, 'GOP', 2829, 57.56, false, true, 'won', '96e540d3-cf64-412e-8a09-bf28f6689d15'::uuid, 'holder-exact-full-name', 'Mark Walker'),
  ('a9eb7226-e797-457f-81d7-0944be2d221f', '5c538a8f-60c5-462e-b4af-482bf3cada60', 'State House District 85', 'Representative', 1, '20261103ME20776', '174261', 'Adrienne Paul', 'Adrienne', 'Paul', false, false, 'GOP', 2378, 52.48, false, true, 'won', NULL, NULL, NULL),
  ('a9eb7226-e797-457f-81d7-0944be2d221f', '5c538a8f-60c5-462e-b4af-482bf3cada60', 'State House District 85', 'Representative', 1, '20261103ME20776', '174260', 'Paul Harris Welch', 'Paul', 'Welch', false, false, 'Dem', 2153, 47.52, false, true, 'lost', NULL, NULL, NULL),
  ('cdbc66e4-a24a-40c7-b7c4-c7285df14eec', 'f9a2e2f6-5edf-449b-bfc6-d6f0606a3619', 'State House District 86', 'Representative', 1, '20261103ME20777', '174263', 'Abigail N. Geer', 'Abigail', 'Geer', false, false, 'Dem', 2540, 50.34, false, false, NULL, NULL, NULL, NULL),
  ('cdbc66e4-a24a-40c7-b7c4-c7285df14eec', 'f9a2e2f6-5edf-449b-bfc6-d6f0606a3619', 'State House District 86', 'Representative', 1, '20261103ME20777', '162209', 'Rolf A. Olsen Jr.', 'Rolf', 'Olsen', false, true, 'GOP', 2506, 49.66, false, false, NULL, '775d8ed7-0f01-43e0-b7c3-cd7b7f80f9c2'::uuid, 'holder-exact-first-last', 'Rolf Olsen'),
  ('4a1d1a75-39ca-4caf-a8f4-2052bdf702b6', 'd6505e16-824c-4629-99cf-fd317bf7184e', 'State House District 87', 'Representative', 1, '20261103ME20738', '121925', 'David Wayne Boyer Jr.', 'David', 'Boyer', false, true, 'GOP', 0, 0, true, true, 'won', '14f6c68b-af34-495e-9179-9c767dd9f222'::uuid, 'holder-exact-first-last', 'David Boyer'),
  ('b8c65d02-d1fc-421b-983a-9afa9d7bd0a2', '0fec242b-7c08-4d07-9dde-bd483185d543', 'State House District 88', 'Representative', 1, '20261103ME20820', '162213', 'Quentin James Chapman', 'Quentin', 'Chapman', false, true, 'GOP', 2174, 48.39, false, true, 'lost', '233ca29f-b25c-4191-8cf4-3f529fb933e9'::uuid, 'holder-exact-first-last', 'Quentin Chapman'),
  ('b8c65d02-d1fc-421b-983a-9afa9d7bd0a2', '0fec242b-7c08-4d07-9dde-bd483185d543', 'State House District 88', 'Representative', 1, '20261103ME20820', '174264', 'Dana N. Staples', 'Dana', 'Staples', false, false, 'Dem', 2319, 51.61, false, true, 'won', NULL, NULL, NULL),
  ('8945f114-256a-4d0b-bb34-787a65e7d1de', 'd92efb92-4956-4669-953e-7c3bc2b0d382', 'State House District 89', 'Representative', 1, '20261103ME20735', '174265', 'James D. Berube', 'James', 'Berube', false, false, 'GOP', 981, 37.82, false, true, 'lost', NULL, NULL, NULL),
  ('8945f114-256a-4d0b-bb34-787a65e7d1de', 'd92efb92-4956-4669-953e-7c3bc2b0d382', 'State House District 89', 'Representative', 1, '20261103ME20735', '121928', 'Adam R. Lee', 'Adam', 'Lee', false, true, 'Dem', 1613, 62.18, false, true, 'won', '5200d94b-cca2-4927-89bf-48c2c4f527fd'::uuid, 'holder-exact-first-last', 'Adam Lee'),
  ('6706eba2-3038-40cf-a95c-8918447cf10d', '085952f4-2a3f-44f7-9101-008a3823ba3f', 'State House District 90', 'Representative', 1, '20261103ME20737', '174266', 'Pamela B. Hart', 'Pamela', 'Hart', false, false, 'Dem', 2835, 57.94, false, true, 'won', NULL, NULL, NULL),
  ('6706eba2-3038-40cf-a95c-8918447cf10d', '085952f4-2a3f-44f7-9101-008a3823ba3f', 'State House District 90', 'Representative', 1, '20261103ME20737', '120539', 'James W. Sorcek', 'James', 'Sorcek', false, false, 'GOP', 2058, 42.06, false, true, 'lost', NULL, NULL, NULL),
  ('ad25c711-1654-4c7a-baf5-6dfe4d0e8425', '40e0bebf-1ee9-48c7-831f-d008194afc53', 'State House District 91', 'Representative', 1, '20261103ME20741', '120013', 'Jeffrey L. Timberlake', 'Jeffrey', 'Timberlake', false, false, 'GOP', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('32ff3468-ade8-4180-b7db-abd8126199c6', '8ac326b2-02d8-45a5-97d5-9fe748289c96', 'State House District 92', 'Representative', 1, '20261103ME20742', '167362', 'Scott G. Girardin', 'Scott', 'Girardin', false, false, 'Ind', 1842, 38.29, false, true, 'lost', NULL, NULL, NULL),
  ('32ff3468-ade8-4180-b7db-abd8126199c6', '8ac326b2-02d8-45a5-97d5-9fe748289c96', 'State House District 92', 'Representative', 1, '20261103ME20742', '119980', 'Stephen J. Wood', 'Stephen', 'Wood', false, true, 'GOP', 2969, 61.71, false, true, 'won', '2640d53c-bcdc-4335-a4a8-04442babe033'::uuid, 'holder-exact-first-last', 'Stephen Wood'),
  ('32026cc6-69b0-4dd6-859e-67e85284232c', '8468b29b-ab23-4d1e-af6b-ed939fe54999', 'State House District 93', 'Representative', 1, '20261103ME20743', '178680', 'Susan G. Longchamps', 'Susan', 'Longchamps', false, false, 'GOP', 1227, 35.07, false, true, 'lost', NULL, NULL, NULL),
  ('32026cc6-69b0-4dd6-859e-67e85284232c', '8468b29b-ab23-4d1e-af6b-ed939fe54999', 'State House District 93', 'Representative', 1, '20261103ME20743', '162217', 'Julia McCabe', 'Julia', 'McCabe', false, true, 'Dem', 2272, 64.93, false, true, 'won', '0e4492df-b9b8-429c-8a1e-1ab909042d7d'::uuid, 'holder-exact-full-name', 'Julia McCabe'),
  ('56d7dd59-3c10-42f6-8593-7ff0bde2eba9', 'a0e62b0d-1df0-48e2-88ec-5bb54152f442', 'State House District 94', 'Representative', 1, '20261103ME20744', '121933', 'Janet Inger Beaudoin', 'Janet', 'Beaudoin', false, false, 'GOP', 1436, 44.53, false, true, 'lost', NULL, NULL, NULL),
  ('56d7dd59-3c10-42f6-8593-7ff0bde2eba9', 'a0e62b0d-1df0-48e2-88ec-5bb54152f442', 'State House District 94', 'Representative', 1, '20261103ME20744', '169533', 'Scott A. Harriman', 'Scott', 'Harriman', false, true, 'Dem', 1789, 55.47, false, true, 'won', '9664affa-96b6-461f-976e-6cdf077cbf11'::uuid, 'holder-exact-first-last', 'Scott Harriman'),
  ('fd5a8e2a-c943-4696-92e3-2a396490d431', '0a9751bb-c858-4e1d-aef4-31e35cfc78b7', 'State House District 95', 'Representative', 1, '20261103ME20740', '174270', 'Kiernan Innes Majerus-Collins', 'Kiernan', 'Majerus-Collins', false, false, 'Dem', 1699, 55.58, false, true, 'won', NULL, NULL, NULL),
  ('fd5a8e2a-c943-4696-92e3-2a396490d431', '0a9751bb-c858-4e1d-aef4-31e35cfc78b7', 'State House District 95', 'Representative', 1, '20261103ME20740', '174271', 'Bret M. Martel', 'Bret', 'Martel', false, false, 'GOP', 1358, 44.42, false, true, 'lost', NULL, NULL, NULL),
  ('83127372-fd2f-4d58-a042-fbd9f8a60722', '3a404d70-a259-495e-9e1d-35ded187931a', 'State House District 96', 'Representative', 1, '20261103ME20827', '162222', 'Kerryl Lee Clement', 'Kerryl', 'Clement', false, false, 'GOP', 2224, 50.43, false, false, NULL, NULL, NULL, NULL),
  ('83127372-fd2f-4d58-a042-fbd9f8a60722', '3a404d70-a259-495e-9e1d-35ded187931a', 'State House District 96', 'Representative', 1, '20261103ME20827', '120386', 'Luke Dylan Jensen', 'Luke', 'Jensen', false, false, 'Dem', 2186, 49.57, false, false, NULL, NULL, NULL, NULL),
  ('b3733fca-b211-44d9-91dd-d82f17edfc87', 'f4f313bb-9ac0-4d18-bbe7-2520a06066c1', 'State House District 97', 'Representative', 1, '20261103ME20786', '69175', 'Dale John Crafts', 'Dale', 'Crafts', false, false, 'GOP', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('3048aa47-0f22-4d15-9ca6-fc0fa14fff5a', '661199b4-c516-4409-a82b-53483abc7d40', 'State House District 98', 'Representative', 1, '20261103ME20809', '174272', 'William J. St. Michel', 'William', 'St. Michel', false, false, 'GOP', 2578, 47.12, false, true, 'lost', NULL, NULL, NULL),
  ('3048aa47-0f22-4d15-9ca6-fc0fa14fff5a', '661199b4-c516-4409-a82b-53483abc7d40', 'State House District 98', 'Representative', 1, '20261103ME20809', '162223', 'Kilton McCarthy Webb', 'Kilton', 'Webb', false, true, 'Dem', 2893, 52.88, false, true, 'won', '8b0fe853-b289-40ad-95ba-dc1ea25e1c34'::uuid, 'holder-exact-first-last', 'Kilton Webb'),
  ('c3374015-3422-482b-abab-217941a0081c', '13af9eb3-7d90-4e45-8646-f0cf3cf8f24c', 'State House District 99', 'Representative', 1, '20261103ME20788', '121940', 'Cheryl A. Golek', 'Cheryl', 'Golek', false, true, 'Dem', 3536, 64.06, false, true, 'won', 'd2c740be-74fc-4ab6-bca7-af9d6e7c7463'::uuid, 'holder-exact-first-last', 'Cheryl Golek'),
  ('c3374015-3422-482b-abab-217941a0081c', '13af9eb3-7d90-4e45-8646-f0cf3cf8f24c', 'State House District 99', 'Representative', 1, '20261103ME20788', '174273', 'Braeden D. Webber', 'Braeden', 'Webber', false, false, 'GOP', 1984, 35.94, false, true, 'lost', NULL, NULL, NULL),
  ('2e892872-c2c5-4939-92a9-d152f0b7a8af', '31995485-79e6-47e9-9c12-885458699a8d', 'State House District 100', 'Representative', 1, '20261103ME20806', '121941', 'Daniel Joseph Ankeles', 'Daniel', 'Ankeles', false, true, 'Dem', 4555, 83.36, false, true, 'won', 'fb5600ed-e81a-4e9d-b3e2-9d57237349ad'::uuid, 'holder-exact-first-last', 'Daniel Ankeles'),
  ('2e892872-c2c5-4939-92a9-d152f0b7a8af', '31995485-79e6-47e9-9c12-885458699a8d', 'State House District 100', 'Representative', 1, '20261103ME20806', '174274', 'Brett Y. Barrett', 'Brett', 'Barrett', false, false, 'GOP', 909, 16.64, false, true, 'lost', NULL, NULL, NULL),
  ('bf1d6800-3a6d-40b1-99ba-410026763657', '6a45c376-08ec-4d58-aa05-1cecdff36064', 'State House District 101', 'Representative', 1, '20261103ME20795', '121499', 'Poppy T. Arford', 'Poppy', 'Arford', false, true, 'Dem', 4386, 75.86, false, true, 'won', 'a82316c1-dc9f-4ed7-9f3c-3866ed4ebe6f'::uuid, 'holder-exact-first-last', 'Poppy Arford'),
  ('bf1d6800-3a6d-40b1-99ba-410026763657', '6a45c376-08ec-4d58-aa05-1cecdff36064', 'State House District 101', 'Representative', 1, '20261103ME20795', '121945', 'Ravi Jackson', 'Ravi', 'Jackson', false, false, 'GOP', 1396, 24.14, false, true, 'lost', NULL, NULL, NULL),
  ('2c72f38a-94a0-4f78-8647-3e4a033ed3f7', 'ec0bcc6d-e0fb-4783-b79a-8211d9dd8be7', 'State House District 102', 'Representative', 1, '20261103ME20803', '174275', 'Henry Lloyd Lawrence III', 'Henry', 'Lawrence', false, false, 'GOP', 1539, 28.23, false, true, 'lost', NULL, NULL, NULL),
  ('2c72f38a-94a0-4f78-8647-3e4a033ed3f7', 'ec0bcc6d-e0fb-4783-b79a-8211d9dd8be7', 'State House District 102', 'Representative', 1, '20261103ME20803', '174276', 'Maura H. Pillsbury', 'Maura', 'Pillsbury', false, false, 'Dem', 3912, 71.77, false, true, 'won', NULL, NULL, NULL),
  ('856415ae-740d-415a-9b74-259e8088f92c', 'e392c7d6-23f2-4b70-9658-a69d39d5f4df', 'State House District 103', 'Representative', 1, '20261103ME20805', '174277', 'Karin Orenstein', 'Karin', 'Orenstein', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('14192649-3505-4667-9735-78a2f165a966', '985771b9-33e4-4274-becf-7341b6920de0', 'State House District 104', 'Representative', 1, '20261103ME20807', '177865', 'L. Samuel Pfeifle', 'L.', 'Pfeifle', false, false, 'Ind', 2430, 46.41, false, true, 'lost', NULL, NULL, NULL),
  ('14192649-3505-4667-9735-78a2f165a966', '985771b9-33e4-4274-becf-7341b6920de0', 'State House District 104', 'Representative', 1, '20261103ME20807', '174278', 'R. Melissa Winslow', 'R.', 'Winslow', false, false, 'GOP', 2806, 53.59, false, true, 'won', NULL, NULL, NULL),
  ('37453f0c-8531-4994-b3be-46fbd39f36b8', 'b10caff0-081f-4998-bad7-95dd191ab9a2', 'State House District 105', 'Representative', 1, '20261103ME20789', '120024', 'Anne Palmer Graham', 'Anne', 'Graham', false, true, 'Dem', 0, 0, true, true, 'won', '0593d23d-88b2-4aa8-81e4-f974a7d9c793'::uuid, 'holder-exact-first-last', 'Anne Graham'),
  ('e41cc87c-c25e-479e-9659-2d8c681729c4', '35262abb-f222-49f8-85d2-67d83dcf90c7', 'State House District 106', 'Representative', 1, '20261103ME20785', '121950', 'Barbara Bagshaw', 'Barbara', 'Bagshaw', false, true, 'GOP', 2498, 48.65, false, true, 'lost', 'd2828ca3-78e1-4885-a93e-af3a1976215b'::uuid, 'holder-exact-full-name', 'Barbara Bagshaw'),
  ('e41cc87c-c25e-479e-9659-2d8c681729c4', '35262abb-f222-49f8-85d2-67d83dcf90c7', 'State House District 106', 'Representative', 1, '20261103ME20785', '174280', 'Bradley M. Youngs', 'Bradley', 'Youngs', false, false, 'Dem', 2637, 51.35, false, true, 'won', NULL, NULL, NULL),
  ('b67acc58-0abb-4db7-884e-1c7def8c87cc', 'a349de7e-d018-4240-84a4-427c3b0e0b3a', 'State House District 107', 'Representative', 1, '20261103ME20779', '174281', 'Joseph A. Campbell', 'Joseph', 'Campbell', false, false, 'Dem', 2631, 53.16, false, true, 'won', NULL, NULL, NULL),
  ('b67acc58-0abb-4db7-884e-1c7def8c87cc', 'a349de7e-d018-4240-84a4-427c3b0e0b3a', 'State House District 107', 'Representative', 1, '20261103ME20779', '162228', 'Mark C. Cooper', 'Mark', 'Cooper', false, true, 'GOP', 2318, 46.84, false, true, 'lost', '307081dc-33cc-4bd2-9343-06fa90d29f03'::uuid, 'holder-exact-first-last', 'Mark Cooper'),
  ('cb2c4896-72f4-4fff-abaa-def5ca7d29b9', '477b5604-947f-4787-821f-44d63512b4d8', 'State House District 108', 'Representative', 1, '20261103ME20782', '174282', 'Kelly L. Dearborn', 'Kelly', 'Dearborn', false, false, 'GOP', 1898, 40.92, false, true, 'lost', NULL, NULL, NULL),
  ('cb2c4896-72f4-4fff-abaa-def5ca7d29b9', '477b5604-947f-4787-821f-44d63512b4d8', 'State House District 108', 'Representative', 1, '20261103ME20782', '162229', 'Parnell W. Terry', 'Parnell', 'Terry', false, true, 'Dem', 2740, 59.08, false, true, 'won', '0cf86dbe-b7be-4cf1-977b-97a98fc60fa9'::uuid, 'holder-exact-first-last', 'Parnell Terry'),
  ('f84fa505-3657-41cc-88ce-b950606603fa', '04d7d9a3-9123-47b9-92b2-e7881be51a67', 'State House District 109', 'Representative', 1, '20261103ME20780', '174283', 'Diana Kushnar', 'Diana', 'Kushnar', false, false, 'GOP', 2101, 39.42, false, true, 'lost', NULL, NULL, NULL),
  ('f84fa505-3657-41cc-88ce-b950606603fa', '04d7d9a3-9123-47b9-92b2-e7881be51a67', 'State House District 109', 'Representative', 1, '20261103ME20780', '162232', 'Seven R. Siegel', 'Seven', 'Siegel', false, false, 'Dem', 3229, 60.58, false, true, 'won', NULL, NULL, NULL),
  ('802d209b-fbe9-4071-b0ca-ef1061089a59', '6ebd99b4-ec73-4923-babc-524f5892e7ee', 'State House District 110', 'Representative', 1, '20261103ME20781', '174284', 'Jason Lewis Copp', 'Jason', 'Copp', false, false, 'GOP', 1917, 31.27, false, true, 'lost', NULL, NULL, NULL),
  ('802d209b-fbe9-4071-b0ca-ef1061089a59', '6ebd99b4-ec73-4923-babc-524f5892e7ee', 'State House District 110', 'Representative', 1, '20261103ME20781', '162233', 'Christina R.C. Mitchell', 'Christina', 'Mitchell', false, true, 'Dem', 4214, 68.73, false, true, 'won', '1507e55f-fdce-4c66-8629-327444850fe7'::uuid, 'holder-exact-first-last', 'Christina Mitchell'),
  ('5b513d0b-4972-4ab9-b561-f0e423cee3c3', '22f7c026-3be9-4cb4-9312-36c09f7945de', 'State House District 111', 'Representative', 1, '20261103ME20757', '121960', 'Amy D. Kuhn', 'Amy', 'Kuhn', false, true, 'Dem', 0, 0, true, true, 'won', '403fb454-25fd-4c9f-9657-975715511b57'::uuid, 'holder-exact-first-last', 'Amy Kuhn'),
  ('19c7c0a0-7031-4b71-95d5-ddececd90d6f', 'ae1e74d3-5dc2-414e-87f6-1a99cbb18643', 'State House District 112', 'Representative', 1, '20261103ME20747', '174286', 'Lauren Chelsea Jones', 'Lauren', 'Jones', false, false, 'GOP', 1383, 24.96, false, true, 'lost', NULL, NULL, NULL),
  ('19c7c0a0-7031-4b71-95d5-ddececd90d6f', 'ae1e74d3-5dc2-414e-87f6-1a99cbb18643', 'State House District 112', 'Representative', 1, '20261103ME20747', '174285', 'Sean M. Mahoney', 'Sean', 'Mahoney', false, false, 'Dem', 4158, 75.04, false, true, 'won', NULL, NULL, NULL),
  ('bb1842cf-a7c0-444e-ad89-c1021763042a', 'cc84bcc7-eab2-4e6c-a855-daff98770262', 'State House District 113', 'Representative', 1, '20261103ME20791', '121462', 'Grayson Benjamin Lookner', 'Grayson', 'Lookner', false, true, 'Dem', 0, 0, true, true, 'won', '6794d63a-05d5-4bcc-99fc-f4f860529d16'::uuid, 'holder-exact-first-last', 'Grayson Lookner'),
  ('7ae8883d-b915-40bd-ab7c-34214c0bdf53', '2db692b3-c519-4ee3-8199-398d0195b1f1', 'State House District 114', 'Representative', 1, '20261103ME20758', '120978', 'April D. Fournier', 'April', 'Fournier', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('89337f6c-8ffa-4bf3-9c54-9f11740bbc08', '89613a5b-0266-4f1c-bda0-a223fac10551', 'State House District 115', 'Representative', 1, '20261103ME20751', '174288', 'Andrew J. Zarro', 'Andrew', 'Zarro', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('03950088-dd60-4c92-bcc6-f87a16bf0bbd', 'aef958e1-f664-4f9b-abd2-52eed5f4608a', 'State House District 116', 'Representative', 1, '20261103ME20748', '121476', 'Samuel Lewis Zager', 'Samuel', 'Zager', false, true, 'Dem', 0, 0, true, true, 'won', '8d45a199-5054-417f-b9a9-3874e113c5f4'::uuid, 'holder-exact-first-last', 'Samuel Zager'),
  ('6d945d47-c83d-4368-908b-d9f7b62cbf66', '654e4385-2340-4493-b9a7-600fd78c6a2e', 'State Senate District 2', 'Senator', 1, '20261103ME20648', '120767', 'Harold L. Stewart III', 'Harold', 'Stewart', false, true, 'GOP', 9870, 66.19, false, true, 'won', '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05'::uuid, 'holder-surname-plus-roster', 'Trey L. Stewart'),
  ('6d945d47-c83d-4368-908b-d9f7b62cbf66', '654e4385-2340-4493-b9a7-600fd78c6a2e', 'State Senate District 2', 'Senator', 1, '20261103ME20648', '178254', 'Janel C. Underwood-Charette', 'Janel', 'Underwood-Charette', false, false, 'Dem', 5042, 33.81, false, true, 'lost', NULL, NULL, NULL),
  ('d4d50b3f-76eb-49ae-a3e7-44610d5278ff', '6244cf8f-9c53-45b2-b6b3-7a81b6f12b90', 'State Senate District 3', 'Senator', 1, '20261103ME20659', '178255', 'Ester B. Franklin', 'Ester', 'Franklin', false, false, 'Dem', 6499, 39.46, false, true, 'lost', NULL, NULL, NULL),
  ('d4d50b3f-76eb-49ae-a3e7-44610d5278ff', '6244cf8f-9c53-45b2-b6b3-7a81b6f12b90', 'State Senate District 3', 'Senator', 1, '20261103ME20659', '120452', 'Joel R. Stetkis', 'Joel', 'Stetkis', false, false, 'GOP', 9971, 60.54, false, true, 'won', NULL, NULL, NULL),
  ('2ebb2ffe-6a8c-45e0-9be8-5628a1620363', '45fae155-817f-4b8b-9015-fb31b71fe393', 'State Senate District 4', 'Senator', 1, '20261103ME20653', '174150', 'Lisa G. Kalp', 'Lisa', 'Kalp', false, false, 'Dem', 6338, 32.92, false, true, 'lost', NULL, NULL, NULL),
  ('2ebb2ffe-6a8c-45e0-9be8-5628a1620363', '45fae155-817f-4b8b-9015-fb31b71fe393', 'State Senate District 4', 'Senator', 1, '20261103ME20653', '121582', 'Chad Richard Perkins', 'Chad', 'Perkins', false, false, 'GOP', 12914, 67.08, false, true, 'won', NULL, NULL, NULL),
  ('03e3bfa6-1af4-4bdf-aaf1-f24a44c75ad4', '45a2394b-78a1-485f-9522-f051988358d3', 'State Senate District 5', 'Senator', 1, '20261103ME20654', '70434', 'Elizabeth M. Caruso', 'Elizabeth', 'Caruso', false, false, 'GOP', 11265, 58.97, false, true, 'won', NULL, NULL, NULL),
  ('03e3bfa6-1af4-4bdf-aaf1-f24a44c75ad4', '45a2394b-78a1-485f-9522-f051988358d3', 'State Senate District 5', 'Senator', 1, '20261103ME20654', '174154', 'Robert F. Sullebarger', 'Robert', 'Sullebarger', false, false, 'Dem', 7837, 41.03, false, true, 'lost', NULL, NULL, NULL),
  ('695ad362-9a13-4902-aec8-232f944af67e', '5ce0544b-131b-45ca-b008-3a4e2dfeb247', 'State Senate District 6', 'Senator', 1, '20261103ME20651', '177854', 'Aaron M. Dana', 'Aaron', 'Dana', false, false, 'Ind', 7609, 41.24, false, true, 'lost', NULL, NULL, NULL),
  ('695ad362-9a13-4902-aec8-232f944af67e', '5ce0544b-131b-45ca-b008-3a4e2dfeb247', 'State Senate District 6', 'Senator', 1, '20261103ME20651', '121789', 'Billy Bob Faulkingham', 'Billy Bob', 'Faulkingham', false, false, 'GOP', 10841, 58.76, false, true, 'won', NULL, NULL, NULL),
  ('8b55c55e-fea4-4353-844d-bea9f4da832c', 'cbc012df-0e5a-41a5-9523-eefe5fdc2a4e', 'State Senate District 7', 'Senator', 1, '20261103ME20652', '121275', 'Nicole C. Grohoski', 'Nicole', 'Grohoski', false, true, 'Dem', 14421, 64.54, false, true, 'won', '1c14da77-9b45-478c-85b5-9b2f5dad1481'::uuid, 'holder-exact-full-name', 'Nicole C. Grohoski'),
  ('8b55c55e-fea4-4353-844d-bea9f4da832c', 'cbc012df-0e5a-41a5-9523-eefe5fdc2a4e', 'State Senate District 7', 'Senator', 1, '20261103ME20652', '162148', 'Cheryl A. Hewes', 'Cheryl', 'Hewes', false, false, 'GOP', 7922, 35.46, false, true, 'lost', NULL, NULL, NULL),
  ('ce67878c-b5d2-47bb-9b7e-b07e0fd93cfd', '28c59a3e-3a9e-4e21-ad7f-a3d84d85b207', 'State Senate District 8', 'Senator', 1, '20261103ME20650', '162016', 'Leo C. Kenney', 'Leo', 'Kenney', false, false, 'GOP', 7297, 43.67, false, true, 'lost', NULL, NULL, NULL),
  ('ce67878c-b5d2-47bb-9b7e-b07e0fd93cfd', '28c59a3e-3a9e-4e21-ad7f-a3d84d85b207', 'State Senate District 8', 'Senator', 1, '20261103ME20650', '121709', 'Michael Tipping', 'Michael', 'Tipping', false, true, 'Dem', 9413, 56.33, false, true, 'won', '653b504d-e5fd-4bc5-ab86-fc2b8129caf5'::uuid, 'holder-surname-plus-roster', 'Mike Tipping'),
  ('5cf4a385-29fa-4f05-b36d-da3616701479', '20511820-9fe6-4828-aa28-79699b91aada', 'State Senate District 9', 'Senator', 1, '20261103ME20655', '177855', 'Stephen Richard Carey', 'Stephen', 'Carey', false, false, 'Unr', 6202, 39.33, false, true, 'lost', NULL, NULL, NULL),
  ('5cf4a385-29fa-4f05-b36d-da3616701479', '20511820-9fe6-4828-aa28-79699b91aada', 'State Senate District 9', 'Senator', 1, '20261103ME20655', '121594', 'Amy J. Roeder', 'Amy', 'Roeder', false, false, 'Dem', 9569, 60.67, false, true, 'won', NULL, NULL, NULL),
  ('5a1e4239-e8dd-4b71-a77a-364ea24651b9', '8270582c-554a-49a1-8b06-6255236a0e00', 'State Senate District 10', 'Senator', 1, '20261103ME20656', '120268', 'Jaric T. Fontaine', 'Jaric', 'Fontaine', false, false, 'Dem', 9256, 42.73, false, true, 'lost', NULL, NULL, NULL),
  ('5a1e4239-e8dd-4b71-a77a-364ea24651b9', '8270582c-554a-49a1-8b06-6255236a0e00', 'State Senate District 10', 'Senator', 1, '20261103ME20656', '120667', 'David G. Haggan', 'David', 'Haggan', false, true, 'GOP', 12404, 57.27, false, true, 'won', 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3'::uuid, 'holder-exact-first-last', 'David Haggan'),
  ('4f292e71-1fd9-4f0e-ae36-a33de29f4acb', '59d07e35-3fd4-40c5-a678-115ec11813ed', 'State Senate District 11', 'Senator', 1, '20261103ME20657', '121364', 'Glenn Chip Curry', 'Glenn', 'Curry', false, true, 'Dem', 12592, 57.06, false, true, 'won', 'ff20c338-594f-4f9b-b667-08c29dc735b8'::uuid, 'holder-surname-plus-roster', 'Chip Curry'),
  ('4f292e71-1fd9-4f0e-ae36-a33de29f4acb', '59d07e35-3fd4-40c5-a678-115ec11813ed', 'State Senate District 11', 'Senator', 1, '20261103ME20657', '174156', 'Ryan C. Otis', 'Ryan', 'Otis', false, false, 'GOP', 9477, 42.94, false, true, 'lost', NULL, NULL, NULL),
  ('35584ba7-c120-4db1-9833-36226173c8a9', '5ce32a6b-1c8c-481d-a838-525ada68f569', 'State Senate District 12', 'Senator', 1, '20261103ME20658', '177856', 'Nicole Lynn Kalloch', 'Nicole', 'Kalloch', false, false, 'Ind', 8712, 42.1, false, true, 'lost', NULL, NULL, NULL),
  ('35584ba7-c120-4db1-9833-36226173c8a9', '5ce32a6b-1c8c-481d-a838-525ada68f569', 'State Senate District 12', 'Senator', 1, '20261103ME20658', '121086', 'Ann H. Matlack', 'Ann', 'Matlack', false, false, 'Dem', 11982, 57.9, false, true, 'won', NULL, NULL, NULL),
  ('d7f530f0-3bae-4c02-9382-ff76ffd3168f', '379f03d6-359d-4637-bc95-df77078ce80f', 'State Senate District 13', 'Senator', 1, '20261103ME20662', '177857', 'Edwin M. Mitchell Jr.', 'Edwin', 'Mitchell', false, false, 'Unr', 7730, 36.09, false, true, 'lost', NULL, NULL, NULL),
  ('d7f530f0-3bae-4c02-9382-ff76ffd3168f', '379f03d6-359d-4637-bc95-df77078ce80f', 'State Senate District 13', 'Senator', 1, '20261103ME20662', '121722', 'Cameron Reny', 'Cameron', 'Reny', false, true, 'Dem', 13686, 63.91, false, true, 'won', 'ceace463-1299-4c49-b5aa-e73af2534e0a'::uuid, 'holder-exact-first-last', 'Cameron D. Reny'),
  ('5953e0cc-6588-4d41-8f40-7b8027092ac4', 'f8f61827-4196-4058-a899-398e461f33ed', 'State Senate District 14', 'Senator', 1, '20261103ME20664', '119997', 'Craig V. Hickman', 'Craig', 'Hickman', false, true, 'Dem', 11625, 53.71, false, true, 'won', '838be693-3b76-413d-a37a-f1da2f3f1286'::uuid, 'holder-exact-full-name', 'Craig V. Hickman'),
  ('5953e0cc-6588-4d41-8f40-7b8027092ac4', 'f8f61827-4196-4058-a899-398e461f33ed', 'State Senate District 14', 'Senator', 1, '20261103ME20664', '174157', 'Steven A. McGee', 'Steven', 'McGee', false, false, 'GOP', 10020, 46.29, false, true, 'lost', NULL, NULL, NULL),
  ('417eda2b-1906-4714-8d1a-95dd5a2eee0a', 'c60d181d-44b4-4e11-88e2-ec3977d78215', 'State Senate District 15', 'Senator', 1, '20261103ME20661', '174158', 'Amanda Ann Heath', 'Amanda', 'Heath', false, false, 'Dem', 9544, 52.04, false, true, 'won', NULL, NULL, NULL),
  ('417eda2b-1906-4714-8d1a-95dd5a2eee0a', 'c60d181d-44b4-4e11-88e2-ec3977d78215', 'State Senate District 15', 'Senator', 1, '20261103ME20661', '174159', 'Kati McCormick', 'Kati', 'McCormick', false, false, 'GOP', 8797, 47.96, false, true, 'lost', NULL, NULL, NULL),
  ('7691655f-99f5-4cb3-889a-14173463a89b', 'f72a0ac0-d9c9-47cf-b22f-3c76ad8ed0d4', 'State Senate District 16', 'Senator', 1, '20261103ME20660', '120548', 'Scott Wynn Cyrway', 'Scott', 'Cyrway', false, true, 'GOP', 7973, 46.96, false, true, 'lost', 'dc583785-9207-41b7-a790-1bc87e0685de'::uuid, 'holder-exact-first-last', 'Scott Cyrway'),
  ('7691655f-99f5-4cb3-889a-14173463a89b', 'f72a0ac0-d9c9-47cf-b22f-3c76ad8ed0d4', 'State Senate District 16', 'Senator', 1, '20261103ME20660', '174160', 'Patric Aaron Moore', 'Patric', 'Moore', false, false, 'Dem', 9005, 53.04, false, true, 'won', NULL, NULL, NULL),
  ('c2dcf2ed-c2fe-4d10-9b80-c889aebb8e63', '2ae092d3-7ff1-401e-82a9-ec83d84de30b', 'State Senate District 17', 'Senator', 1, '20261103ME20663', '121729', 'Jo-Jean C. Keller', 'Jo-Jean', 'Keller', false, false, 'Dem', 7653, 39.4, false, true, 'lost', NULL, NULL, NULL),
  ('c2dcf2ed-c2fe-4d10-9b80-c889aebb8e63', '2ae092d3-7ff1-401e-82a9-ec83d84de30b', 'State Senate District 17', 'Senator', 1, '20261103ME20663', '120866', 'Richard G. Mason', 'Richard', 'Mason', false, false, 'GOP', 11770, 60.6, false, true, 'won', NULL, NULL, NULL),
  ('ce6f47e7-80f6-4c0a-9502-bfd202fd283f', '70f52b08-6c7d-4bfc-85bd-108a2daeb7a0', 'State Senate District 18', 'Senator', 1, '20261103ME20670', '121038', 'John E. Andrews', 'John', 'Andrews', false, false, 'GOP', 10351, 50.03, false, false, NULL, NULL, NULL, NULL),
  ('ce6f47e7-80f6-4c0a-9502-bfd202fd283f', '70f52b08-6c7d-4bfc-85bd-108a2daeb7a0', 'State Senate District 18', 'Senator', 1, '20261103ME20670', '174161', 'Elizabeth D. Bosworth', 'Elizabeth', 'Bosworth', false, false, 'Dem', 10337, 49.97, false, false, NULL, NULL, NULL, NULL),
  ('f4abaffb-b731-4c0b-b54d-7ad7f23af49f', '2d4bd602-4d03-490b-b77f-fdf1b2645b1a', 'State Senate District 19', 'Senator', 1, '20261103ME20672', '162130', 'David A. Duguay', 'David', 'Duguay', false, false, 'Ind', 2992, 15.63, false, true, 'lost', NULL, NULL, NULL),
  ('f4abaffb-b731-4c0b-b54d-7ad7f23af49f', '2d4bd602-4d03-490b-b77f-fdf1b2645b1a', 'State Senate District 19', 'Senator', 1, '20261103ME20672', '120530', 'Joseph E. Martin', 'Joseph', 'Martin', false, true, 'GOP', 9404, 49.13, false, true, 'won', '90e18f37-3ae3-4466-8f56-1f1bcecdac7d'::uuid, 'holder-exact-first-last', 'Joseph Martin'),
  ('f4abaffb-b731-4c0b-b54d-7ad7f23af49f', '2d4bd602-4d03-490b-b77f-fdf1b2645b1a', 'State Senate District 19', 'Senator', 1, '20261103ME20672', '174162', 'Peter J. Southam', 'Peter', 'Southam', false, false, 'Dem', 6747, 35.25, false, true, 'lost', NULL, NULL, NULL),
  ('2cd8bfd4-f7a4-4eb7-87e8-da4806451eab', 'ac6789e3-4899-4da5-813d-0a1e964b9f63', 'State Senate District 20', 'Senator', 1, '20261103ME20668', '119970', 'Bruce A. Bickford', 'Bruce', 'Bickford', false, true, 'GOP', 9237, 47.66, false, true, 'lost', 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238'::uuid, 'holder-exact-first-last', 'Bruce Bickford'),
  ('2cd8bfd4-f7a4-4eb7-87e8-da4806451eab', 'ac6789e3-4899-4da5-813d-0a1e964b9f63', 'State Senate District 20', 'Senator', 1, '20261103ME20668', '119971', 'Michael R. Scott', 'Michael', 'Scott', false, false, 'Dem', 10142, 52.34, false, true, 'won', NULL, NULL, NULL),
  ('cfc7b1dd-62f3-4f02-80ac-1fbca9c5f43d', '15b51a46-105b-4946-8c76-350c142a7703', 'State Senate District 21', 'Senator', 1, '20261103ME20667', '174163', 'Shanna Cox', 'Shanna', 'Cox', false, false, 'Dem', 8491, 61.76, false, true, 'won', NULL, NULL, NULL),
  ('cfc7b1dd-62f3-4f02-80ac-1fbca9c5f43d', '15b51a46-105b-4946-8c76-350c142a7703', 'State Senate District 21', 'Senator', 1, '20261103ME20667', '177858', 'Eryn M. Soule', 'Eryn', 'Soule', false, false, 'Unr', 5258, 38.24, false, true, 'lost', NULL, NULL, NULL),
  ('032ff18c-520c-423d-8bee-b8117cdb713d', '719f0367-d1bf-45b0-adf3-14c571977e8e', 'State Senate District 22', 'Senator', 1, '20261103ME20649', '121027', 'Nathan Burnett', 'Nathan', 'Burnett', false, false, 'Dem', 9016, 44.53, false, true, 'lost', NULL, NULL, NULL),
  ('032ff18c-520c-423d-8bee-b8117cdb713d', '719f0367-d1bf-45b0-adf3-14c571977e8e', 'State Senate District 22', 'Senator', 1, '20261103ME20649', '121924', 'Kimberly J. Pomerleau', 'Kimberly', 'Pomerleau', false, false, 'GOP', 11233, 55.47, false, true, 'won', NULL, NULL, NULL),
  ('3560e2a3-6b93-47d6-b268-aa9736f03bc6', '60ed605e-11ea-4d77-a2a7-6e5e8373423a', 'State Senate District 23', 'Senator', 1, '20261103ME20665', '120244', 'Matthea Elisabeth Daughtry', 'Matthea', 'Daughtry', false, true, 'Dem', 18682, 73.71, false, true, 'won', '0ed25b30-633f-45f5-99f1-a32009b134f5'::uuid, 'holder-exact-first-last', 'Matthea E. L. Daughtry'),
  ('3560e2a3-6b93-47d6-b268-aa9736f03bc6', '60ed605e-11ea-4d77-a2a7-6e5e8373423a', 'State Senate District 23', 'Senator', 1, '20261103ME20665', '174164', 'Bernard Porter', 'Bernard', 'Porter', false, false, 'GOP', 6664, 26.29, false, true, 'lost', NULL, NULL, NULL),
  ('c9b14104-6fc1-48ea-a917-df072cca2230', '6d42a748-5b1d-4d2b-805c-f3db392f71e6', 'State Senate District 24', 'Senator', 1, '20261103ME20669', '119951', 'Denise Tepler', 'Denise', 'Tepler', false, true, 'Dem', 0, 0, true, true, 'won', '71522fd3-94ba-442a-b52e-50b5f77adfcd'::uuid, 'holder-exact-full-name', 'Denise Tepler'),
  ('fbc4b0f8-c23c-47bf-8cfb-fbdbd5339b37', 'ae39b872-4a33-4d43-8575-68f40fd97b5e', 'State Senate District 25', 'Senator', 1, '20261103ME21246', '120362', 'Teresa S. Pierce', 'Teresa', 'Pierce', false, true, 'Dem', 0, 0, true, true, 'won', '69fece92-eade-468e-bf34-82bbac5b3da9'::uuid, 'holder-exact-full-name', 'Teresa S. Pierce'),
  ('6b4d4e8a-b3fe-49b5-95de-06c696ae9864', 'efb7352a-c694-4f72-aa49-38cbf0e69153', 'State Senate District 26', 'Senator', 1, '20261103ME20666', '162136', 'Kenneth James Cianchette', 'Kenneth', 'Cianchette', false, false, 'GOP', 8893, 41.96, false, true, 'lost', NULL, NULL, NULL),
  ('6b4d4e8a-b3fe-49b5-95de-06c696ae9864', 'efb7352a-c694-4f72-aa49-38cbf0e69153', 'State Senate District 26', 'Senator', 1, '20261103ME20666', '121745', 'Timothy E. Nangle', 'Timothy', 'Nangle', false, true, 'Dem', 12299, 58.04, false, true, 'won', 'b8bac865-38a9-45f7-8641-ebdedf416f30'::uuid, 'holder-exact-full-name', 'Timothy E. Nangle'),
  ('02c980c4-5851-402e-a297-35bba8390206', '13ac14f5-dfa9-493c-9aa7-152d878c4d09', 'State Senate District 27', 'Senator', 1, '20261103ME20673', '120632', 'Jill C. Duson', 'Jill', 'Duson', false, true, 'Dem', 0, 0, true, true, 'won', '4eda22f0-a6db-485b-9d76-e76cf7a9a716'::uuid, 'holder-exact-full-name', 'Jill C. Duson'),
  ('8c4d8a11-12d3-487c-a92e-9bf1d7d0ab7e', '53cb553f-5a6a-48e5-82da-9af9a515fbac', 'State Senate District 28', 'Senator', 1, '20261103ME20674', '121474', 'Rachel Talbot Ross', 'Rachel', 'Ross', false, true, 'Dem', 0, 0, true, true, 'won', 'ab357826-a155-4d8a-872f-de865129a256'::uuid, 'holder-exact-full-name', 'Rachel Talbot Ross'),
  ('f437c7c1-06e8-4815-8d1a-6e9ebb4825cc', '3750b707-2d42-4c26-b9e0-1b1e64c06867', 'State Senate District 29', 'Senator', 1, '20261103ME20676', '120955', 'Anne M. Carney', 'Anne', 'Carney', false, true, 'Dem', 17154, 78.54, false, true, 'won', '0b0e2f33-d54b-486b-abe8-70c30b7c33eb'::uuid, 'holder-exact-full-name', 'Anne M. Carney'),
  ('f437c7c1-06e8-4815-8d1a-6e9ebb4825cc', '3750b707-2d42-4c26-b9e0-1b1e64c06867', 'State Senate District 29', 'Senator', 1, '20261103ME20676', '174166', 'Vincent A. Maietta', 'Vincent', 'Maietta', false, false, 'GOP', 4687, 21.46, false, true, 'lost', NULL, NULL, NULL),
  ('6d254740-0e50-4d94-886c-0caf6450759e', '8cbeea8e-bfae-4f06-bea5-f9f61ead3aee', 'State Senate District 30', 'Senator', 1, '20261103ME20675', '162230', 'M. Thad Moody', 'M. Thad', 'Moody', false, false, 'GOP', 8131, 35.99, false, true, 'lost', NULL, NULL, NULL),
  ('6d254740-0e50-4d94-886c-0caf6450759e', '8cbeea8e-bfae-4f06-bea5-f9f61ead3aee', 'State Senate District 30', 'Senator', 1, '20261103ME20675', '121656', 'Sophia Bailey Warren', 'Sophia', 'Warren', false, false, 'Dem', 14463, 64.01, false, true, 'won', NULL, NULL, NULL),
  ('f47e5cc7-dd0b-438d-831b-d826f99a3ee0', '2aa0f1b1-4ba0-455e-8cdb-a3da6f7549c2', 'State Senate District 31', 'Senator', 1, '20261103ME20677', '120587', 'Donna Bailey', 'Donna', 'Bailey', false, true, 'Dem', 13644, 65.58, false, true, 'won', '514dc276-d1a3-4ca2-9ee0-743684cd4bc9'::uuid, 'holder-exact-full-name', 'Donna Bailey'),
  ('f47e5cc7-dd0b-438d-831b-d826f99a3ee0', '2aa0f1b1-4ba0-455e-8cdb-a3da6f7549c2', 'State Senate District 31', 'Senator', 1, '20261103ME20677', '121989', 'Scott Benedetto Eccleston', 'Scott', 'Eccleston', false, false, 'GOP', 7162, 34.42, false, true, 'lost', NULL, NULL, NULL),
  ('8a2881d3-28fe-45a9-9b20-b23f4af7c66c', '8f9c3ea0-b668-4d19-972d-12fadbec7f62', 'State Senate District 32', 'Senator', 1, '20261103ME20678', '120927', 'Henry L. Ingwersen', 'Henry', 'Ingwersen', false, true, 'Dem', 10191, 56.5, false, true, 'won', 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e'::uuid, 'holder-exact-full-name', 'Henry L. Ingwersen'),
  ('8a2881d3-28fe-45a9-9b20-b23f4af7c66c', '8f9c3ea0-b668-4d19-972d-12fadbec7f62', 'State Senate District 32', 'Senator', 1, '20261103ME20678', '121307', 'Jason G. Litalien', 'Jason', 'Litalien', false, false, 'Ind', 7847, 43.5, false, true, 'lost', NULL, NULL, NULL),
  ('06dc0be2-6831-4ba4-9578-ec2fd2f7995b', '07e4413d-46d6-4c5b-8720-b2011fa69cba', 'State Senate District 33', 'Senator', 1, '20261103ME20680', '120531', 'Matthew A. Harrington', 'Matthew', 'Harrington', false, true, 'GOP', 8901, 52.83, false, true, 'won', '4248ed15-3a23-47e7-a24d-6235379b8e43'::uuid, 'holder-surname-plus-roster', 'Matt A. Harrington'),
  ('06dc0be2-6831-4ba4-9578-ec2fd2f7995b', '07e4413d-46d6-4c5b-8720-b2011fa69cba', 'State Senate District 33', 'Senator', 1, '20261103ME20680', '174169', 'Mark H. Vigliotta', 'Mark', 'Vigliotta', false, false, 'Dem', 7948, 47.17, false, true, 'lost', NULL, NULL, NULL),
  ('e6b24d75-c15b-4837-b357-56a8748c81df', 'ffd5659f-b094-42e9-80f0-88476e164f93', 'State Senate District 34', 'Senator', 1, '20261103ME20679', '174170', 'Jonathan R. Fallon', 'Jonathan', 'Fallon', false, false, 'GOP', 9696, 40.86, false, true, 'lost', NULL, NULL, NULL),
  ('e6b24d75-c15b-4837-b357-56a8748c81df', 'ffd5659f-b094-42e9-80f0-88476e164f93', 'State Senate District 34', 'Senator', 1, '20261103ME20679', '121998', 'Daniel R. Sayre', 'Daniel', 'Sayre', false, false, 'Dem', 14032, 59.14, false, true, 'won', NULL, NULL, NULL),
  ('5069f56b-30cc-422f-800f-6bde0c0d678d', 'ac78d2b8-7e47-45c3-967e-2d8e1c81b8fc', 'State Senate District 35', 'Senator', 1, '20261103ME20681', '120921', 'Michele Meyer', 'Michele', 'Meyer', false, false, 'Dem', 15735, 68.78, false, true, 'won', NULL, NULL, NULL),
  ('5069f56b-30cc-422f-800f-6bde0c0d678d', 'ac78d2b8-7e47-45c3-967e-2d8e1c81b8fc', 'State Senate District 35', 'Senator', 1, '20261103ME20681', '121761', 'Julie N. Rakic', 'Julie', 'Rakic', false, false, 'GOP', 7141, 31.22, false, true, 'lost', NULL, NULL, NULL),
  ('fb72e72a-54ba-4a65-8845-f12964188d79', '0f4ca657-f581-4810-aec2-4060a203b65e', 'State Senate District 1', 'Senator', 1, '20261103ME20647', '162139', 'Lucien J.B. Daigle', 'Lucien', 'Daigle', false, false, 'GOP', 9940, 60.57, false, true, 'won', NULL, NULL, NULL),
  ('fb72e72a-54ba-4a65-8845-f12964188d79', '0f4ca657-f581-4810-aec2-4060a203b65e', 'State Senate District 1', 'Senator', 1, '20261103ME20647', '162012', 'Vaughn J. McLaughlin', 'Vaughn', 'McLaughlin', false, false, 'Dem', 6471, 39.43, false, true, 'lost', NULL, NULL, NULL);

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> 344 THEN RAISE EXCEPTION 'CC_0414: expected 344 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> 186 THEN RAISE EXCEPTION 'CC_0414: expected 186 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> 183 THEN RAISE EXCEPTION 'CC_0414: expected 183 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> 155 THEN RAISE EXCEPTION 'CC_0414: expected 155 losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> 6 THEN RAISE EXCEPTION 'CC_0414: expected 6 rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> 344 THEN RAISE EXCEPTION 'CC_0414: the race join sees % of the 344 rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 Maine legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> 'me'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % pinned row(s) are not in a 2026-11-03 Maine legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: winner count does not match races.seats: %', txt; END IF;

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
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> 116 THEN RAISE EXCEPTION 'CC_0414: expected 116 incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: external_id already in use: %', txt; END IF;
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
       'ap-2026-11-03-' || s.ap_candidate_id,
       'Associated Press ballot for the 2026-11-03 general election, read 2026-11-13 from AP''s own '
         || 'per-state results feed (interactives.apelections.org/election-results/data-live/'
         || '2026-11-03/results/races/ME/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against the Secretary of State''s own "2026 General Candidate List - FINAL" spreadsheet '
         || '(https://www.maine.gov/sos/elections-voting/upcoming-elections, read 2026-11-13). Seeded by CC_0414.'
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
    WHERE rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id);

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id;
  IF n <> 344 THEN RAISE EXCEPTION 'CC_0414: expected 344 rows written, found %', n; END IF;

  -- The outcome, the name and the link each read back from production, not from the file's copy.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.race_id = s.race_id
     AND rc.full_name = s.full_name
     AND rc.result IS NOT DISTINCT FROM s.outcome
     AND rc.politician_id IS NOT DISTINCT FROM s.holder_id
     AND rc.is_write_in = s.is_write_in
     AND rc.is_incumbent = s.ap_incumbent;
  IF n <> 344 THEN RAISE EXCEPTION 'CC_0414: only % of 344 written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0414: a citation quotes a vote count: %', txt; END IF;

  -- The 186 races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = 'me'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0414: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> 116 THEN RAISE EXCEPTION 'CC_0414: the seat holder changed for % of the 116 linked office(s) — this file seats nobody', 116 - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION 'CC_0414: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'CC_0414: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
