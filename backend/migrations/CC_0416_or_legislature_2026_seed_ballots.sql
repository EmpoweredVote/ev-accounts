-- CC_0416 - 2026-11-03 Oregon legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the 73 races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. `CC_0381`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for Oregon.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The Oregon legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    `essentials.office_terms` is untouched, `essentials.offices` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--    143 candidacies across 73 races
--     73 won · 70 lost · 0 with NO result (0 race(s) AP has not called)
--     59 linked to a politician we already hold; the rest carry politician_id NULL
--      0 declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
--    Every race in this file is called.
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read 2026-11-13:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/OR/
-- and the Secretary of State's own machine-readable Legislative Export,
-- read 2026-11-13 with Playwright:
--   https://results.oregonvotes.gov/ResultsExport.aspx
--
-- The join, the differences and how each one was settled are in
-- `backend/data/state-leg-2026-seed/` — `or-crosscheck-2026-11-13.json` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (`CC_0408`-`CC_0411`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. 11 of these 73 races are uncontested and 11 of the 143 rows carry a
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
--   holder-exact-full-name      48
--   holder-exact-first-last      9
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
-- Slot CC_0416 reserved via steward. Applied to production 2026-11-13 by Chris Cantrell.
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
  ('1030ac7a-4fd0-4167-a809-9244d7502510', '76855d38-a709-4291-ac22-f1d84e903923', 'State House District 8', 'Representative', 1, '20261103OR38105', '172223', 'Bill Vivian', 'Bill', 'Vivian', false, false, 'GOP', 4308, 14.61, false, true, 'lost', NULL, NULL, NULL),
  ('1030ac7a-4fd0-4167-a809-9244d7502510', '76855d38-a709-4291-ac22-f1d84e903923', 'State House District 8', 'Representative', 1, '20261103OR38105', '162850', 'Lisa Fragala', 'Lisa', 'Fragala', false, true, 'Dem', 25108, 85.17, false, true, 'won', '763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac'::uuid, 'holder-exact-full-name', 'Lisa Fragala'),
  ('9a6c0241-1879-42ce-922b-994b0251b1b9', 'c2cb6564-dfe1-4732-80ca-f26306d79ce4', 'State House District 7', 'Representative', 1, '20261103OR38103', '172222', 'Adam Wilson', 'Adam', 'Wilson', false, false, 'GOP', 12556, 42.53, false, true, 'lost', NULL, NULL, NULL),
  ('9a6c0241-1879-42ce-922b-994b0251b1b9', 'c2cb6564-dfe1-4732-80ca-f26306d79ce4', 'State House District 7', 'Representative', 1, '20261103OR38103', '172220', 'Kori Rodley', 'Kori', 'Rodley', false, false, 'Dem', 16809, 56.94, false, true, 'won', NULL, NULL, NULL),
  ('dae67586-c722-4413-bb97-435d3a1f6ec0', '872f7e3c-a6b8-4bab-a2be-b02e71ec4403', 'State House District 6', 'Representative', 1, '20261103OR38101', '140555', 'Kim Wallan', 'Kim', 'Wallan', false, true, 'GOP', 15048, 55.43, false, true, 'won', '3778353d-cbc9-43cf-866a-a7c01397503a'::uuid, 'holder-exact-full-name', 'Kim Wallan'),
  ('dae67586-c722-4413-bb97-435d3a1f6ec0', '872f7e3c-a6b8-4bab-a2be-b02e71ec4403', 'State House District 6', 'Representative', 1, '20261103OR38101', '68644', 'John P. Holm', 'John', 'Holm', false, false, 'Dem', 12013, 44.25, false, true, 'lost', NULL, NULL, NULL),
  ('98d48226-079f-4dbc-b252-7ceaf46a6a72', '91c11be2-e849-4ac8-b67f-4cc2aa5deaad', 'State House District 5', 'Representative', 1, '20261103OR38099', '172218', 'Alexander Krigsvold', 'Alexander', 'Krigsvold', false, false, 'GOP', 11374, 31.64, false, true, 'lost', NULL, NULL, NULL),
  ('98d48226-079f-4dbc-b252-7ceaf46a6a72', '91c11be2-e849-4ac8-b67f-4cc2aa5deaad', 'State House District 5', 'Representative', 1, '20261103OR38099', '140004', 'Pam Marsh', 'Pam', 'Marsh', false, true, 'Dem', 24519, 68.22, false, true, 'won', '03af5908-a069-4ab7-91db-2f388a885bf9'::uuid, 'holder-exact-full-name', 'Pam Marsh'),
  ('b13a04e5-a4f4-496c-8575-e2f2a2d7421e', 'e59181a6-a87f-486f-acae-b04fdf6c8d13', 'State House District 4', 'Representative', 1, '20261103OR38097', '68661', 'Alek Skarlatos', 'Alek', 'Skarlatos', false, true, 'GOP', 0, 0, true, true, 'won', '35d2729c-b754-4fad-b124-10ee437a116f'::uuid, 'holder-exact-full-name', 'Alek Skarlatos'),
  ('06ac2278-4192-41fd-9f97-66d0e1868449', '711d6d67-38e7-4a3e-a142-877c24e2c003', 'State House District 3', 'Representative', 1, '20261103OR38095', '162844', 'Dwayne Yunker', 'Dwayne', 'Yunker', false, true, 'GOP', 17897, 59.63, false, true, 'won', 'f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d'::uuid, 'holder-exact-full-name', 'Dwayne Yunker'),
  ('06ac2278-4192-41fd-9f97-66d0e1868449', '711d6d67-38e7-4a3e-a142-877c24e2c003', 'State House District 3', 'Representative', 1, '20261103OR38095', '172216', 'Susan Fischer-Maki', 'Susan', 'Fischer-Maki', false, false, 'Dem', 12050, 40.15, false, true, 'lost', NULL, NULL, NULL),
  ('e9b56946-5b02-4c2f-aec1-cac2dc262854', '82e5fc8f-58e3-4881-86ba-54e6ebe8c38a', 'State House District 2', 'Representative', 1, '20261103OR38093', '141545', 'Virgle J. Osborne', 'Virgle', 'Osborne', false, true, 'GOP', 0, 0, true, true, 'won', '558e9c8c-5e52-4685-9e24-1367810f8030'::uuid, 'holder-exact-first-last', 'Virgle Osborne'),
  ('a4228611-62e1-4b9d-92f4-58558280fdd9', '74263a7b-afde-4ca7-9b91-e442472a01f2', 'State House District 1', 'Representative', 1, '20261103OR38091', '66726', 'Court Boice', 'Court', 'Boice', false, true, 'GOP', 22211, 64.54, false, true, 'won', '0e3b9216-cfb9-411f-b80e-684ccaae593f'::uuid, 'holder-exact-full-name', 'Court Boice'),
  ('a4228611-62e1-4b9d-92f4-58558280fdd9', '74263a7b-afde-4ca7-9b91-e442472a01f2', 'State House District 1', 'Representative', 1, '20261103OR38091', '141537', 'Bret Cecil', 'Bret', 'Cecil', false, false, 'Dem', 12116, 35.21, false, true, 'lost', NULL, NULL, NULL),
  ('b79e5df3-ee4e-4d9a-9099-039245f4f331', '5c0e8395-cf2b-413e-a421-84ba9a76a480', 'State House District 20', 'Representative', 1, '20261103OR38129', '139771', 'Paul Evans', 'Paul', 'Evans', false, true, 'Dem', 16802, 54.67, false, true, 'won', 'e5c0549e-4454-4cea-b7dc-67eb17d28b49'::uuid, 'holder-exact-full-name', 'Paul Evans'),
  ('b79e5df3-ee4e-4d9a-9099-039245f4f331', '5c0e8395-cf2b-413e-a421-84ba9a76a480', 'State House District 20', 'Representative', 1, '20261103OR38129', '172244', 'Andrew Fudge', 'Andrew', 'Fudge', false, false, 'GOP', 13058, 42.48, false, true, 'lost', NULL, NULL, NULL),
  ('b79e5df3-ee4e-4d9a-9099-039245f4f331', '5c0e8395-cf2b-413e-a421-84ba9a76a480', 'State House District 20', 'Representative', 1, '20261103OR38129', '141302', 'Taylor A. Rickey', 'Taylor', 'Rickey', false, false, 'Lib', 811, 2.64, false, true, 'lost', NULL, NULL, NULL),
  ('eab7867c-9e3e-4bc0-b406-32d4cef8b385', 'd24e2f76-4e10-47ee-9367-0d21c67e4a30', 'State House District 18', 'Representative', 1, '20261103OR38125', '172238', 'Amanda Staehely', 'Amanda', 'Staehely', false, false, 'GOP', 20167, 63.85, false, true, 'won', NULL, NULL, NULL),
  ('eab7867c-9e3e-4bc0-b406-32d4cef8b385', 'd24e2f76-4e10-47ee-9367-0d21c67e4a30', 'State House District 18', 'Representative', 1, '20261103OR38125', '177728', 'Roy Kaufmann', 'Roy', 'Kaufmann', false, false, 'Dem', 10924, 34.58, false, true, 'lost', NULL, NULL, NULL),
  ('eab7867c-9e3e-4bc0-b406-32d4cef8b385', 'd24e2f76-4e10-47ee-9367-0d21c67e4a30', 'State House District 18', 'Representative', 1, '20261103OR38125', '140370', 'Patrick Marnell', 'Patrick', 'Marnell', false, false, 'Lib', 475, 1.5, false, true, 'lost', NULL, NULL, NULL),
  ('cdbb36b7-56fe-4ddf-990a-ef5d1d3550f0', '256d18b4-8cc2-43b3-92e6-dbd55426df57', 'State House District 17', 'Representative', 1, '20261103OR38123', '57510', 'David Nelson', 'David', 'Nelson', false, false, 'Dem', 9989, 36.41, false, true, 'lost', NULL, NULL, NULL),
  ('cdbb36b7-56fe-4ddf-990a-ef5d1d3550f0', '256d18b4-8cc2-43b3-92e6-dbd55426df57', 'State House District 17', 'Representative', 1, '20261103OR38123', '139105', 'Dan Farrington', 'Dan', 'Farrington', false, false, 'GOP', 17413, 63.47, false, true, 'won', NULL, NULL, NULL),
  ('4a336f96-90c3-49b9-92b8-92a21877a752', 'b8b1b901-b50c-4ba3-9547-9c9547e7947b', 'State House District 16', 'Representative', 1, '20261103OR38121', '162853', 'Sarah Finger McDonald', 'Sarah', 'McDonald', false, true, 'Dem', 0, 0, true, true, 'won', '2a116530-8d06-41b5-b965-50d943eae8c2'::uuid, 'holder-exact-full-name', 'Sarah Finger McDonald'),
  ('d6b8c0b4-8539-4500-9ace-9c441029285f', 'b04443aa-8723-4253-ba23-7038dbd936f3', 'State House District 15', 'Representative', 1, '20261103OR38119', '140588', 'Shelly Boshart Davis', 'Shelly', 'Boshart Davis', false, true, 'GOP', 17756, 51.73, false, true, 'won', '4919fd6a-c250-47b2-a37d-37b1eec8c63d'::uuid, 'holder-exact-full-name', 'Shelly Boshart Davis'),
  ('d6b8c0b4-8539-4500-9ace-9c441029285f', 'b04443aa-8723-4253-ba23-7038dbd936f3', 'State House District 15', 'Representative', 1, '20261103OR38119', '172234', 'Joanna Robinson', 'Joanna', 'Robinson', false, false, 'Dem', 16539, 48.18, false, true, 'lost', NULL, NULL, NULL),
  ('c3504404-cc5e-4661-999e-aee97d23f82c', 'fbe7ea14-9f50-4009-afd8-a3801269782b', 'State House District 14', 'Representative', 1, '20261103OR38117', '172233', 'Kevin T. Burton', 'Kevin', 'Burton', false, false, 'GOP', 10973, 35.44, false, true, 'lost', NULL, NULL, NULL),
  ('c3504404-cc5e-4661-999e-aee97d23f82c', 'fbe7ea14-9f50-4009-afd8-a3801269782b', 'State House District 14', 'Representative', 1, '20261103OR38117', '140104', 'Julie Fahey', 'Julie', 'Fahey', false, true, 'Dem', 19946, 64.42, false, true, 'won', '24398310-8e0c-487e-a11c-253e3060f77c'::uuid, 'holder-exact-full-name', 'Julie Fahey'),
  ('53eb8a62-dfb9-43d9-9cf1-7a4c6682905f', '6a9b77ab-1441-4bc7-9dba-383ad0449b67', 'State House District 13', 'Representative', 1, '20261103OR38115', '137863', 'Nancy Nathanson', 'Nancy', 'Nathanson', false, true, 'Dem', 25959, 70.57, false, true, 'won', 'ca404c61-11af-43d9-9563-07dde3f7b8e7'::uuid, 'holder-exact-full-name', 'Nancy Nathanson'),
  ('53eb8a62-dfb9-43d9-9cf1-7a4c6682905f', '6a9b77ab-1441-4bc7-9dba-383ad0449b67', 'State House District 13', 'Representative', 1, '20261103OR38115', '172231', 'Jonathan T. Abrahamsen', 'Jonathan', 'Abrahamsen', false, false, 'GOP', 10766, 29.27, false, true, 'lost', NULL, NULL, NULL),
  ('2a232cad-03d6-42ff-9d21-379c539434e6', 'd0bc63aa-dc54-4864-8386-c58afff177ce', 'State House District 12', 'Representative', 1, '20261103OR38113', '172229', 'Amber Smith', 'Amber', 'Smith', false, false, 'Dem', 15193, 42.15, false, true, 'lost', NULL, NULL, NULL),
  ('2a232cad-03d6-42ff-9d21-379c539434e6', 'd0bc63aa-dc54-4864-8386-c58afff177ce', 'State House District 12', 'Representative', 1, '20261103OR38113', '70166', 'Darin Harbick', 'Darin', 'Harbick', false, true, 'GOP', 20480, 56.82, false, true, 'won', 'f3fb09eb-adb0-4543-b6a2-32f90003569b'::uuid, 'holder-exact-full-name', 'Darin Harbick'),
  ('96087752-c299-411c-ae28-09771efc106e', '8a748e6d-201b-448a-95df-266bc58cbc8d', 'State House District 11', 'Representative', 1, '20261103OR38111', '167930', 'Ivan Maluski', 'Ivan', 'Maluski', false, false, 'Dem', 10525, 31.82, false, true, 'lost', NULL, NULL, NULL),
  ('96087752-c299-411c-ae28-09771efc106e', '8a748e6d-201b-448a-95df-266bc58cbc8d', 'State House District 11', 'Representative', 1, '20261103OR38111', '172227', 'Ken Jackola', 'Ken', 'Jackola', false, false, 'GOP', 22496, 68.01, false, true, 'won', NULL, NULL, NULL),
  ('24503ded-8443-4ef6-85eb-3e24a14e76a8', '432579e3-e304-4ee9-8711-8cb3f830eb37', 'State House District 10', 'Representative', 1, '20261103OR38109', '139080', 'David Gomberg', 'David', 'Gomberg', false, true, 'Dem', 0, 0, true, true, 'won', '00ddecfd-648a-4118-82e6-a60327068b32'::uuid, 'holder-exact-full-name', 'David Gomberg'),
  ('4aed443d-e833-48de-a136-83c3b0a2b5fc', 'f087ae89-9f4b-40ca-b59f-809fc4c580ea', 'State House District 9', 'Representative', 1, '20261103OR38107', '172224', 'John Ezra Scheirman', 'John', 'Scheirman', false, false, 'Dem', 14397, 43.62, false, true, 'lost', NULL, NULL, NULL),
  ('4aed443d-e833-48de-a136-83c3b0a2b5fc', 'f087ae89-9f4b-40ca-b59f-809fc4c580ea', 'State House District 9', 'Representative', 1, '20261103OR38107', '172226', 'Claire Lynn', 'Claire', 'Lynn', false, false, 'GOP', 18555, 56.22, false, true, 'won', NULL, NULL, NULL),
  ('b66b4f46-bc3f-40e0-9534-fe100fd01a3f', '39182515-50b7-4f5d-84d0-9952e8b01571', 'State House District 49', 'Representative', 1, '20261103OR38187', '172311', 'Ann Walker', 'Ann', 'Walker', false, false, 'GOP', 8314, 38.56, false, true, 'lost', NULL, NULL, NULL),
  ('b66b4f46-bc3f-40e0-9534-fe100fd01a3f', '39182515-50b7-4f5d-84d0-9952e8b01571', 'State House District 49', 'Representative', 1, '20261103OR38187', '141130', 'Zach Hudson', 'Zach', 'Hudson', false, true, 'Dem', 13198, 61.21, false, true, 'won', '37247ac1-5444-4fdd-b58e-123b5db4d0fe'::uuid, 'holder-exact-full-name', 'Zach Hudson'),
  ('e68d25a4-8211-4302-bdfd-334efa9cb86c', '895e66bd-b18c-4590-9305-6566f9e21132', 'State House District 48', 'Representative', 1, '20261103OR38185', '172310', 'Lamar Wise', 'Lamar', 'Wise', false, true, 'Dem', 13839, 58.3, false, true, 'won', 'e0b21a1d-8c55-4aa9-a58a-d6b69db9f716'::uuid, 'holder-exact-full-name', 'Lamar Wise'),
  ('e68d25a4-8211-4302-bdfd-334efa9cb86c', '895e66bd-b18c-4590-9305-6566f9e21132', 'State House District 48', 'Representative', 1, '20261103OR38185', '162876', 'Andrew Morrison', 'Andrew', 'Morrison', false, false, 'GOP', 9841, 41.46, false, true, 'lost', NULL, NULL, NULL),
  ('c60a2086-1a13-4ec6-a59e-9630ede2e36a', '0c53e06a-587b-4c7a-b35c-6c8adf37d046', 'State House District 47', 'Representative', 1, '20261103OR38183', '141825', 'Andrea Valderrama', 'Andrea', 'Valderrama', false, true, 'Dem', 0, 0, true, true, 'won', 'a5a3918c-3e24-44fa-9573-440436a05b04'::uuid, 'holder-exact-full-name', 'Andrea Valderrama'),
  ('fdc6428b-1d56-4464-9497-0ebaf63669e1', '472ea591-ed86-4b8f-addc-5af21ee030bc', 'State House District 46', 'Representative', 1, '20261103OR38181', '162873', 'Willy Chotzen', 'Willy', 'Chotzen', false, true, 'Dem', 26171, 86.9, false, true, 'won', 'd3371858-924e-4f76-b756-f2d7bb3c9b8d'::uuid, 'holder-exact-full-name', 'Willy Chotzen'),
  ('fdc6428b-1d56-4464-9497-0ebaf63669e1', '472ea591-ed86-4b8f-addc-5af21ee030bc', 'State House District 46', 'Representative', 1, '20261103OR38181', '172309', 'Leo Morley', 'Leo', 'Morley', false, false, 'GOP', 3903, 12.96, false, true, 'lost', NULL, NULL, NULL),
  ('871b64ec-ed2d-4636-9aec-75cf677ee2f0', '6f5ded32-e45e-4c23-990d-ecee7ab63165', 'State House District 45', 'Representative', 1, '20261103OR38179', '172308', 'Jason Boyce', 'Jason', 'Boyce', false, false, 'GOP', 3801, 10.93, false, true, 'lost', NULL, NULL, NULL),
  ('871b64ec-ed2d-4636-9aec-75cf677ee2f0', '6f5ded32-e45e-4c23-990d-ecee7ab63165', 'State House District 45', 'Representative', 1, '20261103OR38179', '139175', 'Thuy Tran', 'Thuy', 'Tran', false, true, 'Dem', 30916, 88.91, false, true, 'won', '9ada0539-e66c-444f-b220-86a8138b5277'::uuid, 'holder-exact-full-name', 'Thủy Trần'),
  ('423d0029-7a09-488a-8e75-b7adb7ba208f', '9c96cc81-2852-4658-b3a0-6e08eaa02aa5', 'State House District 44', 'Representative', 1, '20261103OR38177', '141810', 'Travis Nelson', 'Travis', 'Nelson', false, true, 'Dem', 29010, 90.78, false, true, 'won', '0f7439ad-5832-42e9-a1c5-75f1720e14d3'::uuid, 'holder-exact-full-name', 'Travis Nelson'),
  ('423d0029-7a09-488a-8e75-b7adb7ba208f', '9c96cc81-2852-4658-b3a0-6e08eaa02aa5', 'State House District 44', 'Representative', 1, '20261103OR38177', '141114', 'Margo Logan', 'Margo', 'Logan', false, false, 'GOP', 2873, 8.99, false, true, 'lost', NULL, NULL, NULL),
  ('0c62078e-3371-41e9-a4a6-09364989b0bd', '890e6a0c-f310-4c8e-b101-d01edc3f42b5', 'State House District 43', 'Representative', 1, '20261103OR38175', '140220', 'Tawna Sanchez', 'Tawna', 'Sanchez', false, true, 'Dem', 35768, 93.57, false, true, 'won', '051b4e9a-6966-45b3-9b65-e23ad4672364'::uuid, 'holder-exact-first-last', 'Tawna D. Sanchez'),
  ('0c62078e-3371-41e9-a4a6-09364989b0bd', '890e6a0c-f310-4c8e-b101-d01edc3f42b5', 'State House District 43', 'Representative', 1, '20261103OR38175', '141807', 'Tim LeMaster', 'Tim', 'LeMaster', false, false, 'GOP', 2402, 6.28, false, true, 'lost', NULL, NULL, NULL),
  ('c5ac3517-d5d6-43cf-88da-f2c4ffc9e0fa', '399c946b-932c-4708-8525-f26825c43149', 'State House District 42', 'Representative', 1, '20261103OR38173', '179180', 'Morey Straus', 'Morey', 'Straus', false, false, 'Lib', 2402, 6.18, false, true, 'lost', NULL, NULL, NULL),
  ('c5ac3517-d5d6-43cf-88da-f2c4ffc9e0fa', '399c946b-932c-4708-8525-f26825c43149', 'State House District 42', 'Representative', 1, '20261103OR38173', '139867', 'Rob Nosse', 'Rob', 'Nosse', false, true, 'Dem', 36354, 93.47, false, true, 'won', 'c5c49832-aa2d-477e-b44e-d6059a98d426'::uuid, 'holder-exact-full-name', 'Rob Nosse'),
  ('54fab4ed-b8b4-406b-86a9-dbf3cbdc946b', '425e576f-0ad5-4f9c-8b44-689cf0f7aefa', 'State House District 41', 'Representative', 1, '20261103OR38171', '68664', 'Mark Gamba', 'Mark', 'Gamba', false, true, 'Dem', 31727, 81.75, false, true, 'won', '36db8c55-4b20-408c-bd99-b8488d0ef344'::uuid, 'holder-exact-full-name', 'Mark Gamba'),
  ('54fab4ed-b8b4-406b-86a9-dbf3cbdc946b', '425e576f-0ad5-4f9c-8b44-689cf0f7aefa', 'State House District 41', 'Representative', 1, '20261103OR38171', '162871', 'Elvis Clark', 'Elvis', 'Clark', false, false, 'GOP', 7039, 18.14, false, true, 'lost', NULL, NULL, NULL),
  ('aecf1a82-d282-40fe-831a-71d767b3842d', '986fe7c3-83d6-4794-b346-fb8184e35d37', 'State House District 40', 'Representative', 1, '20261103OR38169', '172305', 'Michael W. Sugar', 'Michael', 'Sugar', false, false, 'Dem', 19274, 57.38, false, true, 'won', NULL, NULL, NULL),
  ('aecf1a82-d282-40fe-831a-71d767b3842d', '986fe7c3-83d6-4794-b346-fb8184e35d37', 'State House District 40', 'Representative', 1, '20261103OR38169', '141791', 'Adam Baker', 'Adam', 'Baker', false, false, 'GOP', 13309, 39.62, false, true, 'lost', NULL, NULL, NULL),
  ('aecf1a82-d282-40fe-831a-71d767b3842d', '986fe7c3-83d6-4794-b346-fb8184e35d37', 'State House District 40', 'Representative', 1, '20261103OR38169', '178927', 'Pat Hubbell', 'Pat', 'Hubbell', false, false, 'Ind', 991, 2.95, false, true, 'lost', NULL, NULL, NULL),
  ('ecba61f8-4a3b-424e-a540-396392e09bb7', '5a89a1e7-ab78-4118-aaea-2fad01b5cb8d', 'State House District 39', 'Representative', 1, '20261103OR38167', '162868', 'April Dobson', 'April', 'Dobson', false, true, 'Dem', 0, 0, true, true, 'won', '0bffa985-c83b-41c3-8901-19b7dac86cd7'::uuid, 'holder-exact-full-name', 'April Dobson'),
  ('1836afa4-9989-47d1-99a1-03864c61174d', '988933f9-5251-4666-b381-5e1f4f5b5637', 'State House District 38', 'Representative', 1, '20261103OR38165', '141769', 'Daniel Loc Nguyen', 'Daniel', 'Nguyen', false, true, 'Dem', 0, 0, true, true, 'won', '73519742-09c3-4204-871b-076ff1397a14'::uuid, 'holder-exact-first-last', 'Daniel Nguyễn'),
  ('75e411be-f1dc-49a8-beb4-7adca380ee10', 'f4bb688c-dbd1-4bfa-a7ad-cbf1a74f4966', 'State House District 37', 'Representative', 1, '20261103OR38163', '172303', 'Chad Parker', 'Chad', 'Parker', false, false, 'GOP', 12912, 37.8, false, true, 'lost', NULL, NULL, NULL),
  ('75e411be-f1dc-49a8-beb4-7adca380ee10', 'f4bb688c-dbd1-4bfa-a7ad-cbf1a74f4966', 'State House District 37', 'Representative', 1, '20261103OR38163', '141760', 'Jules Walters', 'Jules', 'Walters', false, true, 'Dem', 21226, 62.14, false, true, 'won', 'b5d3a442-3229-412a-8da4-e8eb8b9fdb3a'::uuid, 'holder-exact-full-name', 'Jules Walters'),
  ('7ebfb28f-4b9b-471b-ad38-10ad104b104f', 'd3912edc-eb83-461b-84fb-3dfe409f64ee', 'State House District 36', 'Representative', 1, '20261103OR38161', '141753', 'Hai Pham', 'Hai', 'Pham', false, true, 'Dem', 21216, 65.94, false, true, 'won', '2e668344-f025-489a-b870-1803269c11fc'::uuid, 'holder-exact-full-name', 'Hai Pham'),
  ('7ebfb28f-4b9b-471b-ad38-10ad104b104f', 'd3912edc-eb83-461b-84fb-3dfe409f64ee', 'State House District 36', 'Representative', 1, '20261103OR38161', '172302', 'Michael Orth', 'Michael', 'Orth', false, false, 'GOP', 10926, 33.96, false, true, 'lost', NULL, NULL, NULL),
  ('bd0f6910-0729-4b9e-b5f0-d5e3229b1150', '5e352df7-91c3-4081-a818-c6ab29cd2530', 'State House District 35', 'Representative', 1, '20261103OR38159', '141749', 'Farrah Chaichi', 'Farrah', 'Chaichi', false, true, 'Dem', 15020, 72.99, false, true, 'won', '62decede-7149-40a1-a68a-16e2d3eb62a6'::uuid, 'holder-exact-full-name', 'Farrah Chaichi'),
  ('bd0f6910-0729-4b9e-b5f0-d5e3229b1150', '5e352df7-91c3-4081-a818-c6ab29cd2530', 'State House District 35', 'Representative', 1, '20261103OR38159', '140161', 'Dan Martin', 'Dan', 'Martin', false, false, 'GOP', 5509, 26.77, false, true, 'lost', NULL, NULL, NULL),
  ('4c4b8a8c-6734-40de-a226-4db73872228d', '496eed1b-8ed2-4eca-971e-6e57758248c4', 'State House District 34', 'Representative', 1, '20261103OR38157', '172299', 'Mari Watanabe', 'Mari', 'Watanabe', false, true, 'Dem', 19396, 72.97, false, true, 'won', 'bcc608a3-abf0-4a30-9c4b-0721dcf04be5'::uuid, 'holder-exact-full-name', 'Mari Watanabe'),
  ('4c4b8a8c-6734-40de-a226-4db73872228d', '496eed1b-8ed2-4eca-971e-6e57758248c4', 'State House District 34', 'Representative', 1, '20261103OR38157', '172300', 'Shaunie Cousins', 'Shaunie', 'Cousins', false, false, 'GOP', 7153, 26.91, false, true, 'lost', NULL, NULL, NULL),
  ('85bd8533-7e90-4891-94c9-7d3b370f939e', '89590ebd-0e75-42b9-b32a-9c6a63510f46', 'State House District 33', 'Representative', 1, '20261103OR38155', '162861', 'Shannon Jones Isadore', 'Shannon Jones', 'Isadore', false, true, 'Dem', 27444, 87.37, false, true, 'won', '2b9da845-9fab-406f-97c3-1afe895c254b'::uuid, 'holder-surname-plus-roster', 'Shannon Isadore'),
  ('85bd8533-7e90-4891-94c9-7d3b370f939e', '89590ebd-0e75-42b9-b32a-9c6a63510f46', 'State House District 33', 'Representative', 1, '20261103OR38155', '172298', 'Ciatta R. Thompson', 'Ciatta', 'Thompson', false, false, 'GOP', 3912, 12.45, false, true, 'lost', NULL, NULL, NULL),
  ('8d9220af-0615-4217-9144-6d5ff51f796d', '89df6d2a-87d7-4acf-b396-edb0c25bfdda', 'State House District 32', 'Representative', 1, '20261103OR38153', '140961', 'Max Sherman', 'Max', 'Sherman', false, false, 'GOP', 16799, 47.68, false, true, 'lost', NULL, NULL, NULL),
  ('8d9220af-0615-4217-9144-6d5ff51f796d', '89df6d2a-87d7-4acf-b396-edb0c25bfdda', 'State House District 32', 'Representative', 1, '20261103OR38153', '141724', 'Cyrus Javadi', 'Cyrus', 'Javadi', false, true, 'Dem', 18361, 52.11, false, true, 'won', 'cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e'::uuid, 'holder-exact-full-name', 'Cyrus Javadi'),
  ('c270d126-d912-4718-83a9-91c8f29d61d9', 'c9eb240c-baff-4cbd-9865-65dc3c990b42', 'State House District 31', 'Representative', 1, '20261103OR38151', '162859', 'Darcey Edwards', 'Darcey', 'Edwards', false, true, 'GOP', 20020, 56.44, false, true, 'won', 'eab1011b-0cf3-4538-8842-292e7ab22291'::uuid, 'holder-exact-full-name', 'Darcey Edwards'),
  ('c270d126-d912-4718-83a9-91c8f29d61d9', 'c9eb240c-baff-4cbd-9865-65dc3c990b42', 'State House District 31', 'Representative', 1, '20261103OR38151', '172295', 'Tom L. Forest', 'Tom', 'Forest', false, false, 'Dem', 15397, 43.41, false, true, 'lost', NULL, NULL, NULL),
  ('3aecd537-89e5-4df6-9324-3c786dd20c53', '3b0a8b02-2e34-4d98-85d7-1c23780e5055', 'State House District 30', 'Representative', 1, '20261103OR38149', '141705', 'Nathan Sosa', 'Nathan', 'Sosa', false, true, 'Dem', 17492, 72.39, false, true, 'won', 'f2bc3bbf-0d29-4ad9-b675-9c53cf081969'::uuid, 'holder-exact-full-name', 'Nathan Sosa'),
  ('3aecd537-89e5-4df6-9324-3c786dd20c53', '3b0a8b02-2e34-4d98-85d7-1c23780e5055', 'State House District 30', 'Representative', 1, '20261103OR38149', '172255', 'Charles A. Ross', 'Charles', 'Ross', false, false, 'GOP', 6632, 27.45, false, true, 'lost', NULL, NULL, NULL),
  ('6bd7d635-9879-48a6-82de-9a573158f15b', '3242bf0e-5549-4ce4-94a4-01e84a816b4d', 'State House District 29', 'Representative', 1, '20261103OR38147', '177742', 'Brian Schimmel', 'Brian', 'Schimmel', false, false, 'GOP', 10155, 40.8, false, true, 'lost', NULL, NULL, NULL),
  ('6bd7d635-9879-48a6-82de-9a573158f15b', '3242bf0e-5549-4ce4-94a4-01e84a816b4d', 'State House District 29', 'Representative', 1, '20261103OR38147', '139805', 'Susan McLain', 'Susan', 'McLain', false, true, 'Dem', 14678, 58.98, false, true, 'won', '3fbaa80c-be2d-411f-a3ab-95add9ae6c84'::uuid, 'holder-exact-full-name', 'Susan McLain'),
  ('67c5e8fb-b0cd-43ac-82b2-89a6560dbfdc', 'f5ac9150-9a2c-4ebe-a537-2b7e58eb22e9', 'State House District 28', 'Representative', 1, '20261103OR38145', '141072', 'Dacia Grayber', 'Dacia', 'Grayber', false, true, 'Dem', 30215, 84.35, false, true, 'won', 'c5640f05-239a-47fd-97f3-e284859c1cc9'::uuid, 'holder-exact-full-name', 'Dacia Grayber'),
  ('67c5e8fb-b0cd-43ac-82b2-89a6560dbfdc', 'f5ac9150-9a2c-4ebe-a537-2b7e58eb22e9', 'State House District 28', 'Representative', 1, '20261103OR38145', '172253', 'Randall Fryer', 'Randall', 'Fryer', false, false, 'GOP', 5576, 15.57, false, true, 'lost', NULL, NULL, NULL),
  ('a9624a01-6a49-42ef-ad3a-8732586f7952', '40e2b73e-4f5e-4f1a-919f-da47a9f5002d', 'State House District 27', 'Representative', 1, '20261103OR38143', '141693', 'Tammy Carpenter', 'Tammy', 'Carpenter', false, false, 'Dem', 21156, 72.59, false, true, 'won', NULL, NULL, NULL),
  ('a9624a01-6a49-42ef-ad3a-8732586f7952', '40e2b73e-4f5e-4f1a-919f-da47a9f5002d', 'State House District 27', 'Representative', 1, '20261103OR38143', '172252', 'G. Mark Norman', 'G.', 'Norman', false, false, 'GOP', 7934, 27.22, false, true, 'lost', NULL, NULL, NULL),
  ('4cc48042-66a3-474b-b125-3dc5bf15efa3', '8607145a-8b47-4af6-86d2-84ebf1433638', 'State House District 26', 'Representative', 1, '20261103OR38141', '172250', 'Stephanie Carkin', 'Stephanie', 'Carkin', false, false, 'GOP', 13430, 41.33, false, true, 'lost', NULL, NULL, NULL),
  ('4cc48042-66a3-474b-b125-3dc5bf15efa3', '8607145a-8b47-4af6-86d2-84ebf1433638', 'State House District 26', 'Representative', 1, '20261103OR38141', '178245', 'Steph Terrio', 'Steph', 'Terrio', false, false, 'PAG', 944, 2.91, false, true, 'lost', NULL, NULL, NULL),
  ('4cc48042-66a3-474b-b125-3dc5bf15efa3', '8607145a-8b47-4af6-86d2-84ebf1433638', 'State House District 26', 'Representative', 1, '20261103OR38141', '172249', 'Sue R. Rieke Smith', 'Sue', 'Rieke Smith', false, true, 'Dem', 18092, 55.68, false, true, 'won', '0d5a4aeb-121f-461c-b379-a8a00c3b1ba1'::uuid, 'holder-exact-first-last', 'Sue Rieke Smith'),
  ('066cacd0-a5ce-4237-b4a4-2220fe7a30a3', '465d7894-ca9e-42af-9c89-0601c6e0790c', 'State House District 25', 'Representative', 1, '20261103OR38139', '140914', 'Ben Bowman', 'Ben', 'Bowman', false, true, 'Dem', 20620, 70.39, false, true, 'won', '5e29b685-1f2e-4963-83a8-a7bde5b5250e'::uuid, 'holder-exact-full-name', 'Ben Bowman'),
  ('066cacd0-a5ce-4237-b4a4-2220fe7a30a3', '465d7894-ca9e-42af-9c89-0601c6e0790c', 'State House District 25', 'Representative', 1, '20261103OR38139', '63557', 'Bob Niemeyer', 'Bob', 'Niemeyer', false, false, 'GOP', 8638, 29.49, false, true, 'lost', NULL, NULL, NULL),
  ('d4de78ae-d879-4f71-979b-964af4ad6d64', '55ead30f-d27b-44c0-8677-abeccae45f92', 'State House District 24', 'Representative', 1, '20261103OR38137', '141676', 'Lucetta A. Elmer', 'Lucetta', 'Elmer', false, true, 'GOP', 0, 0, true, true, 'won', '7bba19f8-0a1f-4ee2-852f-63bb38ffef6e'::uuid, 'holder-exact-first-last', 'Lucetta Elmer'),
  ('6df1eab8-6589-4a7d-a625-1a05530896d5', '4a67234a-6f4f-4556-a3c2-0b225a0637cf', 'State House District 23', 'Representative', 1, '20261103OR38135', '141669', 'Anna M. Scharf', 'Anna', 'Scharf', false, true, 'GOP', 21370, 59.93, false, true, 'won', '0cd6ccff-e02d-4cbe-a1df-381226292840'::uuid, 'holder-exact-first-last', 'Anna Scharf'),
  ('6df1eab8-6589-4a7d-a625-1a05530896d5', '4a67234a-6f4f-4556-a3c2-0b225a0637cf', 'State House District 23', 'Representative', 1, '20261103OR38135', '141660', 'Kriss Wright', 'Kriss', 'Wright', false, false, 'Dem', 14256, 39.98, false, true, 'lost', NULL, NULL, NULL),
  ('a784275c-c8d0-42bd-9039-27fa85d7e289', '505de0f5-f25e-4b21-9870-a51d6227d55a', 'State House District 22', 'Representative', 1, '20261103OR38133', '162857', 'Lesly M. Munoz', 'Lesly', 'Munoz', false, true, 'Dem', 9572, 59.94, false, true, 'won', '7360da53-a6df-42d9-89b4-fff76af23de6'::uuid, 'holder-exact-first-last', 'Lesly Muñoz'),
  ('a784275c-c8d0-42bd-9039-27fa85d7e289', '505de0f5-f25e-4b21-9870-a51d6227d55a', 'State House District 22', 'Representative', 1, '20261103OR38133', '172247', 'Noemi Legaspi', 'Noemi', 'Legaspi', false, false, 'GOP', 6364, 39.85, false, true, 'lost', NULL, NULL, NULL),
  ('9ced4516-af3e-4821-9d2b-d267af86d5c9', '2973f4b4-0011-4937-9b62-bd2f2aa496f9', 'State House District 21', 'Representative', 1, '20261103OR38131', '172245', 'Michael Welsh', 'Michael', 'Welsh', false, false, 'Dem', 12321, 54.52, false, true, 'won', NULL, NULL, NULL),
  ('9ced4516-af3e-4821-9d2b-d267af86d5c9', '2973f4b4-0011-4937-9b62-bd2f2aa496f9', 'State House District 21', 'Representative', 1, '20261103OR38131', '137850', 'Kevin L. Mannix', 'Kevin', 'Mannix', false, true, 'GOP', 10247, 45.34, false, true, 'lost', '2edbb7a5-a798-4088-8939-7b44b51e682c'::uuid, 'holder-exact-first-last', 'Kevin Mannix'),
  ('51d2ec2d-4107-40a2-bce5-5e0390eb4b09', '1e62d382-37a2-4146-98b6-d656853997f7', 'State House District 19', 'Representative', 1, '20261103OR38127', '172241', 'Anna Munson', 'Anna', 'Munson', false, false, 'GOP', 9972, 39.75, false, true, 'lost', NULL, NULL, NULL),
  ('51d2ec2d-4107-40a2-bce5-5e0390eb4b09', '1e62d382-37a2-4146-98b6-d656853997f7', 'State House District 19', 'Representative', 1, '20261103OR38127', '141632', 'Tom Andersen', 'Tom', 'Andersen', false, true, 'Dem', 15090, 60.15, false, true, 'won', '5b81e68c-3ec3-4c81-9f1b-010db86da9c0'::uuid, 'holder-exact-full-name', 'Tom Andersen'),
  ('eb761d4c-3e5f-4007-811c-dff535a51a35', 'e8dcfe03-153c-49ed-b895-76be11427562', 'State House District 60', 'Representative', 1, '20261103OR38209', '141184', 'Beth Spell', 'Beth', 'Spell', false, false, 'Dem', 5978, 21.5, false, true, 'lost', NULL, NULL, NULL),
  ('eb761d4c-3e5f-4007-811c-dff535a51a35', 'e8dcfe03-153c-49ed-b895-76be11427562', 'State House District 60', 'Representative', 1, '20261103OR38209', '141191', 'Mark Owens', 'Mark', 'Owens', false, true, 'GOP', 21760, 78.27, false, true, 'won', 'ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1'::uuid, 'holder-exact-full-name', 'Mark Owens'),
  ('6f70d73e-ede7-4c8a-adf5-4b9b93fbb000', '689d524c-98c5-4737-9a0a-ba03e455802a', 'State House District 59', 'Representative', 1, '20261103OR38207', '141161', 'Vikki Breese-Iverson', 'Vikki', 'Breese-Iverson', false, true, 'GOP', 25838, 70.46, false, true, 'won', '7f460988-c9a6-4452-a872-441e7c4ac071'::uuid, 'holder-exact-full-name', 'Vikki Breese-Iverson'),
  ('6f70d73e-ede7-4c8a-adf5-4b9b93fbb000', '689d524c-98c5-4737-9a0a-ba03e455802a', 'State House District 59', 'Representative', 1, '20261103OR38207', '141868', 'Lawrence Jones', 'Lawrence', 'Jones', false, false, 'Dem', 10781, 29.4, false, true, 'lost', NULL, NULL, NULL),
  ('48059812-3928-45c8-a490-30913a8001f6', '1d149368-69bb-4aad-bdd6-6add9b978d9d', 'State House District 58', 'Representative', 1, '20261103OR38205', '172324', 'Brian Campbell', 'Brian', 'Campbell', false, false, 'Dem', 8834, 28.82, false, true, 'lost', NULL, NULL, NULL),
  ('48059812-3928-45c8-a490-30913a8001f6', '1d149368-69bb-4aad-bdd6-6add9b978d9d', 'State House District 58', 'Representative', 1, '20261103OR38205', '141177', 'Bobby Levy', 'Bobby', 'Levy', false, true, 'GOP', 21784, 71.08, false, true, 'won', '05152597-fd40-49bb-bcd3-9e21945ae8b0'::uuid, 'holder-exact-full-name', 'Bobby Levy'),
  ('823c8aee-447a-45d8-adea-3b20920a677d', 'df566e23-3faa-493e-965d-036c9ea82733', 'State House District 57', 'Representative', 1, '20261103OR38203', '57479', 'Greg Smith', 'Greg', 'Smith', false, true, 'GOP', 14641, 70.99, false, true, 'won', '81cda574-d820-4ac3-b7fe-0ac3d2638c28'::uuid, 'holder-surname-plus-roster', 'Gregory Smith'),
  ('823c8aee-447a-45d8-adea-3b20920a677d', 'df566e23-3faa-493e-965d-036c9ea82733', 'State House District 57', 'Representative', 1, '20261103OR38203', '178246', 'Josiah Dean', 'Josiah', 'Dean', false, false, 'PAG', 5834, 28.29, false, true, 'lost', NULL, NULL, NULL),
  ('7945292a-a94c-4b80-b231-dea0b545e464', '32da4471-9818-47c5-9bd6-f21490a45e7e', 'State House District 56', 'Representative', 1, '20261103OR38201', '141865', 'Emily G. McIntire', 'Emily', 'McIntire', false, true, 'GOP', 0, 0, true, true, 'won', '9f9b60c1-483c-4a8e-8221-145098204ced'::uuid, 'holder-exact-first-last', 'Emily McIntire'),
  ('eaec38fa-30f1-41dc-8106-ce0f4e706281', '222b1575-1b4b-4847-a961-831c0fbef340', 'State House District 55', 'Representative', 1, '20261103OR38199', '172323', 'Colby M. Simmons', 'Colby', 'Simmons', false, false, 'Dem', 10835, 32.27, false, true, 'lost', NULL, NULL, NULL),
  ('eaec38fa-30f1-41dc-8106-ce0f4e706281', '222b1575-1b4b-4847-a961-831c0fbef340', 'State House District 55', 'Representative', 1, '20261103OR38199', '140265', 'E. Werner Reschke', 'E.', 'Reschke', false, true, 'GOP', 22669, 67.51, false, true, 'won', '3c7c9b46-a054-41a7-8752-f0d8706f754d'::uuid, 'holder-exact-full-name', 'E. Werner Reschke'),
  ('7746de2c-9398-4ba4-aed3-8dc84714fa17', 'c8b17d79-a296-4432-9fb5-61ac085ccbb7', 'State House District 52', 'Representative', 1, '20261103OR38193', '172318', 'Hank Sanders', 'Hank', 'Sanders', false, false, 'Dem', 17597, 53.58, false, true, 'won', NULL, NULL, NULL),
  ('7746de2c-9398-4ba4-aed3-8dc84714fa17', 'c8b17d79-a296-4432-9fb5-61ac085ccbb7', 'State House District 52', 'Representative', 1, '20261103OR38193', '172320', 'Scott C. Hege', 'Scott', 'Hege', false, false, 'GOP', 15202, 46.29, false, true, 'lost', NULL, NULL, NULL),
  ('639a9752-b3b6-4ab8-87fd-a0bdda131940', '35bf2cdd-a10f-4037-bc92-3ffd7c45e388', 'State House District 51', 'Representative', 1, '20261103OR38191', '172315', 'Matt Bunch', 'Matt', 'Bunch', false, true, 'GOP', 22333, 59.91, false, true, 'won', 'ce386a55-7cc5-4006-89db-97e06e0e0279'::uuid, 'holder-exact-full-name', 'Matt Bunch'),
  ('639a9752-b3b6-4ab8-87fd-a0bdda131940', '35bf2cdd-a10f-4037-bc92-3ffd7c45e388', 'State House District 51', 'Representative', 1, '20261103OR38191', '172313', 'Darla Mead', 'Darla', 'Mead', false, false, 'Dem', 14914, 40.01, false, true, 'lost', NULL, NULL, NULL),
  ('3f690af0-3732-4af4-a9e5-e34182b4ef0b', '70a55c32-2811-4146-9ab6-b85dc24c3562', 'State House District 50', 'Representative', 1, '20261103OR38189', '172312', 'Brian Gray', 'Brian', 'Gray', false, false, 'GOP', 9117, 38.49, false, true, 'lost', NULL, NULL, NULL),
  ('3f690af0-3732-4af4-a9e5-e34182b4ef0b', '70a55c32-2811-4146-9ab6-b85dc24c3562', 'State House District 50', 'Representative', 1, '20261103OR38189', '141136', 'Ricki Ruiz', 'Ricki', 'Ruiz', false, true, 'Dem', 14531, 61.35, false, true, 'won', '5e5e267a-808e-4a57-9f80-7c3e47fcb5f6'::uuid, 'holder-exact-full-name', 'Ricki Ruiz'),
  ('b58e90ae-dae8-4280-a521-63cf3738002c', '57abe6f3-e637-4929-a5e4-0af04faf606a', 'State Senate District 19', 'Senator', 1, '20261103OR38067', '140527', 'Rob Wagner', 'Rob', 'Wagner', false, true, 'Dem', 49641, 69.16, false, true, 'won', '14faa864-de9f-497f-a78a-db41f42ee5e0'::uuid, 'holder-exact-full-name', 'Rob Wagner'),
  ('b58e90ae-dae8-4280-a521-63cf3738002c', '57abe6f3-e637-4929-a5e4-0af04faf606a', 'State Senate District 19', 'Senator', 1, '20261103OR38067', '172208', 'Mary Dirksen', 'Mary', 'Dirksen', false, false, 'GOP', 22067, 30.74, false, true, 'lost', NULL, NULL, NULL),
  ('cfb0d989-96df-4760-8986-52c5222f6f65', '848bd994-c162-41c6-83dc-0d2c981cab89', 'State Senate District 17', 'Senator', 1, '20261103OR38063', '172207', 'John A. N. Chee', 'John', 'Chee', false, false, 'GOP', 10359, 17.77, false, true, 'lost', NULL, NULL, NULL),
  ('cfb0d989-96df-4760-8986-52c5222f6f65', '848bd994-c162-41c6-83dc-0d2c981cab89', 'State Senate District 17', 'Senator', 1, '20261103OR38063', '141077', 'Lisa Reynolds', 'Lisa', 'Reynolds', false, true, 'Dem', 47859, 82.08, false, true, 'won', 'd910cf6e-7d70-4b0c-b883-2fe2dcb185b6'::uuid, 'holder-exact-full-name', 'Lisa Reynolds'),
  ('a5ad940e-ba78-4a8f-aaff-e1b26898ae70', 'a6f28a55-1d10-4b5b-9e7d-706ec4f97b9f', 'State Senate District 16', 'Senator', 1, '20261103OR38061', '172203', 'Courtney Bangs', 'Courtney', 'Bangs', false, false, 'GOP', 35965, 50.54, false, true, 'won', NULL, NULL, NULL),
  ('a5ad940e-ba78-4a8f-aaff-e1b26898ae70', 'a6f28a55-1d10-4b5b-9e7d-706ec4f97b9f', 'State Senate District 16', 'Senator', 1, '20261103OR38061', '141909', 'Rachel Armitage', 'Rachel', 'Armitage', false, false, 'Dem', 32149, 45.18, false, true, 'lost', NULL, NULL, NULL),
  ('a5ad940e-ba78-4a8f-aaff-e1b26898ae70', 'a6f28a55-1d10-4b5b-9e7d-706ec4f97b9f', 'State Senate District 16', 'Senator', 1, '20261103OR38061', '178244', 'Melisa Finkle', 'Melisa', 'Finkle', false, false, 'Ind', 2987, 4.2, false, true, 'lost', NULL, NULL, NULL),
  ('0885351e-f42e-478d-bcd5-c5db2e339b59', 'a6c31021-d148-4237-b524-e704f7e82e84', 'State Senate District 15', 'Senator', 1, '20261103OR38059', '172200', 'Myrna A. Munoz', 'Myrna', 'Munoz', false, false, 'Dem', 32856, 66.77, false, true, 'won', NULL, NULL, NULL),
  ('0885351e-f42e-478d-bcd5-c5db2e339b59', 'a6c31021-d148-4237-b524-e704f7e82e84', 'State Senate District 15', 'Senator', 1, '20261103OR38059', '172201', 'Harold Hutchison', 'Harold', 'Hutchison', false, false, 'GOP', 16187, 32.89, false, true, 'lost', NULL, NULL, NULL),
  ('16f7642d-23cc-44b4-b918-cd9efca8b619', '82948b1d-b902-4b71-8ca9-d1003df3caa0', 'State Senate District 13', 'Senator', 1, '20261103OR38055', '140799', 'Tim E. Nelson', 'Tim', 'Nelson', false, false, 'Lib', 1080, 1.74, false, true, 'lost', NULL, NULL, NULL),
  ('16f7642d-23cc-44b4-b918-cd9efca8b619', '82948b1d-b902-4b71-8ca9-d1003df3caa0', 'State Senate District 13', 'Senator', 1, '20261103OR38055', '140796', 'Courtney Neron Misslin', 'Courtney', 'Neron Misslin', false, true, 'Dem', 38918, 62.82, false, true, 'won', 'dcdc002c-8fd6-415a-a30a-8fc70c83d9ff'::uuid, 'holder-exact-full-name', 'Courtney Neron Misslin'),
  ('16f7642d-23cc-44b4-b918-cd9efca8b619', '82948b1d-b902-4b71-8ca9-d1003df3caa0', 'State Senate District 13', 'Senator', 1, '20261103OR38055', '141684', 'Glenn Lancaster', 'Glenn', 'Lancaster', false, false, 'GOP', 21903, 35.36, false, true, 'lost', NULL, NULL, NULL),
  ('81ce0dac-6f32-44fb-ba79-895a55fa32ad', 'a8868a1e-4e24-4d08-adb4-7a9ef6d84e91', 'State Senate District 11', 'Senator', 1, '20261103OR38051', '162856', 'Virginia Stapleton', 'Virginia', 'Stapleton', false, false, 'Dem', 21466, 55.36, false, true, 'won', NULL, NULL, NULL),
  ('81ce0dac-6f32-44fb-ba79-895a55fa32ad', 'a8868a1e-4e24-4d08-adb4-7a9ef6d84e91', 'State Senate District 11', 'Senator', 1, '20261103OR38051', '141656', 'Tracy M. Cramer', 'Tracy', 'Cramer', false, false, 'GOP', 17228, 44.43, false, true, 'lost', NULL, NULL, NULL),
  ('16c2ab80-dbff-41ff-b6f3-4c8e2b38d7fd', '0439b0c2-3e89-42ea-a164-dc158b465afa', 'State Senate District 10', 'Senator', 1, '20261103OR38049', '140496', 'Deb Patterson', 'Deb', 'Patterson', false, true, 'Dem', 33100, 58.8, false, true, 'won', '631cc414-8793-42ec-b883-594ed7f0b249'::uuid, 'holder-exact-full-name', 'Deb Patterson'),
  ('16c2ab80-dbff-41ff-b6f3-4c8e2b38d7fd', '0439b0c2-3e89-42ea-a164-dc158b465afa', 'State Senate District 10', 'Senator', 1, '20261103OR38049', '70197', 'Angela Plowhead', 'Angela', 'Plowhead', false, false, 'GOP', 23131, 41.09, false, true, 'lost', NULL, NULL, NULL),
  ('75d10bdf-03fe-4cb4-84b7-fb5119be1e1c', 'f94e4bcc-7349-45ba-b368-70afd273d6c8', 'State Senate District 8', 'Senator', 1, '20261103OR38045', '141481', 'Sara Gelser Blouin', 'Sara', 'Gelser Blouin', false, true, 'Dem', 39876, 63.85, false, true, 'won', '1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, 'holder-exact-full-name', 'Sara Gelser Blouin'),
  ('75d10bdf-03fe-4cb4-84b7-fb5119be1e1c', 'f94e4bcc-7349-45ba-b368-70afd273d6c8', 'State Senate District 8', 'Senator', 1, '20261103OR38045', '141482', 'Valerie Draper Woldeit', 'Valerie', 'Draper Woldeit', false, false, 'GOP', 22445, 35.94, false, true, 'lost', NULL, NULL, NULL),
  ('276a645a-083f-4dbf-9efc-93ceab6fbd9d', 'a8c0006f-28c9-460d-9276-4ea290f0f1dc', 'State Senate District 7', 'Senator', 1, '20261103OR38043', '140029', 'James I. Manning Jr.', 'James', 'Manning', false, true, 'Dem', 45840, 67.73, false, true, 'won', 'bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e'::uuid, 'holder-exact-full-name', 'James I. Manning Jr.'),
  ('276a645a-083f-4dbf-9efc-93ceab6fbd9d', 'a8c0006f-28c9-460d-9276-4ea290f0f1dc', 'State Senate District 7', 'Senator', 1, '20261103OR38043', '172198', 'Jack D. Huff', 'Jack', 'Huff', false, false, 'GOP', 21613, 31.94, false, true, 'lost', NULL, NULL, NULL),
  ('04c076fd-cb8f-495c-9dbe-5c17c7d63488', '1dddd7a3-773a-493d-a446-9e8757f3fe16', 'State Senate District 6', 'Senator', 1, '20261103OR38041', '172196', 'Sierrah Williams', 'Sierrah', 'Williams', false, false, 'Dem', 25633, 36.85, false, true, 'lost', NULL, NULL, NULL),
  ('04c076fd-cb8f-495c-9dbe-5c17c7d63488', '1dddd7a3-773a-493d-a446-9e8757f3fe16', 'State Senate District 6', 'Senator', 1, '20261103OR38041', '172197', 'Jack Tibbetts', 'Jack', 'Tibbetts', false, false, 'GOP', 42453, 61.03, false, true, 'won', NULL, NULL, NULL),
  ('04c076fd-cb8f-495c-9dbe-5c17c7d63488', '1dddd7a3-773a-493d-a446-9e8757f3fe16', 'State Senate District 6', 'Senator', 1, '20261103OR38041', '178741', 'Caleb Ticer', 'Caleb', 'Ticer', false, false, 'Lib', 1418, 2.04, false, true, 'lost', NULL, NULL, NULL),
  ('127a4ab5-ec74-4215-a83f-76f116565d3e', '13bfd3a6-78af-4385-90de-e1782107afbe', 'State Senate District 4', 'Senator', 1, '20261103OR38559', '57485', 'Floyd Prozanski', 'Floyd', 'Prozanski', false, true, 'Dem', 0, 0, true, true, 'won', 'b6f5cd9e-a9d2-44ff-9027-0d931765f378'::uuid, 'holder-exact-full-name', 'Floyd Prozanski'),
  ('c4c887b3-a705-4f39-808f-4595cfba3f4f', '01991c03-e4e2-43c1-85bd-40273f3a96d5', 'State Senate District 3', 'Senator', 1, '20261103OR38035', '172193', 'Denise D. Krause', 'Denise', 'Krause', false, false, 'Dem', 34532, 53.88, false, true, 'won', NULL, NULL, NULL),
  ('c4c887b3-a705-4f39-808f-4595cfba3f4f', '01991c03-e4e2-43c1-85bd-40273f3a96d5', 'State Senate District 3', 'Senator', 1, '20261103OR38035', '172195', 'Brad Hicks', 'Brad', 'Hicks', false, false, 'GOP', 26981, 42.1, false, true, 'lost', NULL, NULL, NULL),
  ('c4c887b3-a705-4f39-808f-4595cfba3f4f', '01991c03-e4e2-43c1-85bd-40273f3a96d5', 'State Senate District 3', 'Senator', 1, '20261103OR38035', '178243', 'Clay Bearnson', 'Clay', 'Bearnson', false, false, 'Ind', 2506, 3.91, false, true, 'lost', NULL, NULL, NULL),
  ('2ffe60e8-21ef-45f2-adb5-c2e4efb3e003', 'a0211124-b7bf-43b5-94bc-71834f6b26ba', 'State Senate District 20', 'Senator', 1, '20261103OR38069', '140193', 'Mark Meek', 'Mark', 'Meek', false, true, 'Dem', 37286, 59.05, false, true, 'won', 'be46ed6d-363e-46f4-89d4-c95d9af67db1'::uuid, 'holder-exact-full-name', 'Mark Meek'),
  ('2ffe60e8-21ef-45f2-adb5-c2e4efb3e003', 'a0211124-b7bf-43b5-94bc-71834f6b26ba', 'State Senate District 20', 'Senator', 1, '20261103OR38069', '172209', 'Michele Stroh', 'Michele', 'Stroh', false, false, 'GOP', 25812, 40.88, false, true, 'lost', NULL, NULL, NULL),
  ('f34f46fd-2f14-4dfc-9290-a1937f096d5f', 'cc0a3565-4376-4633-a610-5943f87b86fd', 'State Senate District 24', 'Senator', 1, '20261103OR38077', '140528', 'Kayse Jama', 'Kayse', 'Jama', false, true, 'Dem', 0, 0, true, true, 'won', 'a703adb5-1086-471b-ba8b-2dbeddd8102b'::uuid, 'holder-exact-full-name', 'Kayse Jama'),
  ('b801a245-523f-4682-8ab7-752056cf5f05', '3103a291-f637-4632-9164-89b042ea1ef0', 'State Senate District 26', 'Senator', 1, '20261103OR38081', '172210', 'Nicole Bassett', 'Nicole', 'Bassett', false, false, 'Dem', 32689, 46.48, false, true, 'lost', NULL, NULL, NULL),
  ('b801a245-523f-4682-8ab7-752056cf5f05', '3103a291-f637-4632-9164-89b042ea1ef0', 'State Senate District 26', 'Senator', 1, '20261103OR38081', '140717', 'Jeff Helfrich', 'Jeff', 'Helfrich', false, false, 'GOP', 37599, 53.46, false, true, 'won', NULL, NULL, NULL);

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> 143 THEN RAISE EXCEPTION 'CC_0416: expected 143 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> 73 THEN RAISE EXCEPTION 'CC_0416: expected 73 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> 73 THEN RAISE EXCEPTION 'CC_0416: expected 73 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> 70 THEN RAISE EXCEPTION 'CC_0416: expected 70 losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: expected 0 rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> 143 THEN RAISE EXCEPTION 'CC_0416: the race join sees % of the 143 rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 Oregon legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> 'or'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % pinned row(s) are not in a 2026-11-03 Oregon legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: winner count does not match races.seats: %', txt; END IF;

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
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> 59 THEN RAISE EXCEPTION 'CC_0416: expected 59 incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_race_id || '-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: external_id already in use: %', txt; END IF;
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
         || '2026-11-03/results/races/OR/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against the Secretary of State''s own machine-readable Legislative Export '
         || '(https://results.oregonvotes.gov/ResultsExport.aspx, read 2026-11-13). Seeded by CC_0416.'
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
  IF n <> 143 THEN RAISE EXCEPTION 'CC_0416: expected 143 rows written, found %', n; END IF;

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
  IF n <> 143 THEN RAISE EXCEPTION 'CC_0416: only % of 143 written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0416: a citation quotes a vote count: %', txt; END IF;

  -- The 73 races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = 'or'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0416: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> 59 THEN RAISE EXCEPTION 'CC_0416: the seat holder changed for % of the 59 linked office(s) — this file seats nobody', 59 - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION 'CC_0416: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'CC_0416: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
