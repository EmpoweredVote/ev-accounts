-- CC_0413 - 2026-11-03 Massachusetts legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the 196 races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. `CC_0381`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for Massachusetts.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The Massachusetts legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    `essentials.office_terms` is untouched, `essentials.offices` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--    256 candidacies across 196 races
--    195 won · 59 lost · 2 with NO result (1 race(s) AP has not called)
--    178 linked to a politician we already hold; the rest carry politician_id NULL
--      0 declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
--    The uncalled race(s) here:
--      2nd Plymouth District (AP race 20261103MA22180, Too Early to Call)
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read 2026-11-13:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/MA/
-- and the Secretary of the Commonwealth's own "2026 State Election Candidates" page,
-- read 2026-11-13 with Playwright:
--   https://www.sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm
--
-- The join, the differences and how each one was settled are in
-- `backend/data/state-leg-2026-seed/` — `ma-soc-crosscheck-2026-11-13.json` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (`CC_0408`-`CC_0411`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. 140 of these 196 races are uncontested and 140 of the 256 rows carry a
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
--   holder-exact-full-name     103
--   holder-exact-first-last     72
--   holder-surname-plus-roster   3
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
-- Slot CC_0413 reserved via steward. Applied to production 2026-11-13 by Chris Cantrell.
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
  ('a4593a1e-2e5c-49fb-bc7b-e9e57c273407', '77975b9a-dffd-48ce-9b2c-921c4d1b5a48', '10th Bristol District', 'Representative, 10th Bristol District', 1, '20261103MA23000', '165959', 'Mark D. Sylvia', 'Mark', 'Sylvia', false, true, 'Dem', 12454, 59.36, false, true, 'won', '8658e02a-1456-45ba-96bb-19ff438d8e1b'::uuid, 'holder-exact-full-name', 'Mark D. Sylvia'),
  ('a4593a1e-2e5c-49fb-bc7b-e9e57c273407', '77975b9a-dffd-48ce-9b2c-921c4d1b5a48', '10th Bristol District', 'Representative, 10th Bristol District', 1, '20261103MA23000', '179358', 'Brendalee A. Smith', 'Brendalee', 'Smith', false, false, 'GOP', 8526, 40.64, false, true, 'lost', NULL, NULL, NULL),
  ('103b8024-9902-4989-92cc-4b6cb762fc2c', 'b65fa824-6ef7-4fc7-a26a-ded637fbbe04', '10th Essex District', 'Representative, 10th Essex District', 1, '20261103MA23012', '123540', 'Daniel Francis Cahill', 'Daniel', 'Cahill', false, true, 'Dem', 0, 0, true, true, 'won', 'ca6d9c06-e613-46a1-b938-0d89d488b583'::uuid, 'holder-exact-first-last', 'Daniel F. Cahill'),
  ('bd88ea4f-4da7-4602-9dc1-f378acbbeec0', 'fa6bf99c-3f4e-474f-845c-0674cb0c1c57', '10th Hampden District', 'Representative, 10th Hampden District', 1, '20261103MA23029', '123205', 'Carlos Gonzalez', 'Carlos', 'Gonzalez', false, true, 'Dem', 0, 0, true, true, 'won', '64e0eeb2-c83a-4da4-b6a2-2047b1e25cab'::uuid, 'holder-exact-full-name', 'Carlos González'),
  ('5dcfaf18-d07f-424d-88ec-a611f31f6ba4', '9bb5c614-069e-43cb-a871-ad44eee8d8c1', '10th Middlesex District', 'Representative, 10th Middlesex District', 1, '20261103MA23043', '122807', 'John J. Lawn', 'John', 'Lawn', false, true, 'Dem', 0, 0, true, true, 'won', 'baddd174-93ea-47b6-9cbd-c48fc3acf2f6'::uuid, 'holder-exact-full-name', 'John J. Lawn'),
  ('cfc564b8-ee54-41b8-983d-4509340026c8', '00e684b8-2469-48d1-a359-93a046064b5f', '10th Norfolk District', 'Representative, 10th Norfolk District', 1, '20261103MA23078', '122831', 'Jeffrey N. Roy', 'Jeffrey', 'Roy', false, true, 'Dem', 0, 0, true, true, 'won', '4024c884-6627-4496-b3ff-5e91862bf894'::uuid, 'holder-exact-full-name', 'Jeffrey N. Roy'),
  ('fb6b9019-6b62-4bda-9b0e-a82bbbbd19ac', '499e0162-4a38-4d80-83ea-95d29161696a', '10th Plymouth District', 'Representative, 10th Plymouth District', 1, '20261103MA23091', '123270', 'Michelle Marie DuBois', 'Michelle', 'DuBois', false, true, 'Dem', 0, 0, true, true, 'won', '75a2d83f-8db8-478b-a36d-5ecb707b8507'::uuid, 'holder-exact-first-last', 'Michelle M. DuBois'),
  ('31fab0bb-a6e8-4ba3-af04-1a7244eb8121', '16fe2730-0f5d-46e5-9962-c0c91f6d885b', '10th Suffolk District', 'Representative, 10th Suffolk District', 1, '20261103MA23103', '166053', 'William F. MacGregor', 'William', 'MacGregor', false, true, 'Dem', 14838, 90.96, false, true, 'won', '194b9b91-6986-423e-89a0-ee9750f275d8'::uuid, 'holder-exact-full-name', 'William F. MacGregor'),
  ('31fab0bb-a6e8-4ba3-af04-1a7244eb8121', '16fe2730-0f5d-46e5-9962-c0c91f6d885b', '10th Suffolk District', 'Representative, 10th Suffolk District', 1, '20261103MA23103', '179363', 'Devin Allen Kreinbring', 'Devin', 'Kreinbring', false, false, 'Oth', 1474, 9.04, false, true, 'lost', NULL, NULL, NULL),
  ('5db12b67-f82b-46dc-b9c7-348f076407a9', '55ac5fbc-e0df-41a3-89b9-9d01d40ba1f4', '10th Worcester District', 'Representative, 10th Worcester District', 1, '20261103MA23121', '123663', 'Brian W. Murray', 'Brian', 'Murray', false, true, 'Dem', 0, 0, true, true, 'won', '4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'holder-exact-full-name', 'Brian W. Murray'),
  ('20b2c211-19b0-4a5d-b4d0-dc78ff266ac4', 'a108c3a4-cb42-475a-8528-d3f13006ec83', '11th Bristol District', 'Representative, 11th Bristol District', 1, '20261103MA23001', '124069', 'Christopher M. Hendricks', 'Christopher', 'Hendricks', false, true, 'Dem', 0, 0, true, true, 'won', '9cb46542-a671-4bdd-bfcb-98fc1bc79415'::uuid, 'holder-exact-first-last', 'Christopher Hendricks'),
  ('a4baeeee-b127-48ce-b10d-a70b89672064', 'a0a43721-0f85-4a79-aca1-a6d7d50a176c', '11th Essex District', 'Representative, 11th Essex District', 1, '20261103MA23013', '165960', 'Sean Daniel Reid', 'Sean', 'Reid', false, true, 'Dem', 0, 0, true, true, 'won', '444ac209-7bfa-4f3a-a733-5666fd74fd66'::uuid, 'holder-exact-first-last', 'Sean Reid'),
  ('bad0e99a-fae1-4bb5-b16f-4fcb72d48e4a', 'c8a3653c-21d9-40ef-a9b6-5d76c43823f0', '11th Hampden District', 'Representative, 11th Hampden District', 1, '20261103MA23030', '123554', 'Bud L. Williams', 'Bud', 'Williams', false, true, 'Dem', 0, 0, true, true, 'won', 'aee5ccea-d3ca-426c-9849-fbfc5e297e2a'::uuid, 'holder-exact-full-name', 'Bud L. Williams'),
  ('30d5e49b-84cc-45f9-a09b-9a8b315f57a1', 'c6ec5759-fded-4490-a7da-c45dbb61442a', '11th Middlesex District', 'Representative, 11th Middlesex District', 1, '20261103MA23044', '165976', 'Amy Mah Sangiolo', 'Amy', 'Sangiolo', false, true, 'Dem', 0, 0, true, true, 'won', '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'::uuid, 'holder-exact-first-last', 'Amy M. Sangiolo'),
  ('f52399cc-e225-46fb-bb8f-2b9fe803c619', 'd48f94f7-ef54-40a9-8d7e-bc937775063e', '11th Norfolk District', 'Representative, 11th Norfolk District', 1, '20261103MA23079', '122482', 'Paul McMurtry', 'Paul', 'McMurtry', false, true, 'Dem', 0, 0, true, true, 'won', '5020a35d-1f0c-44f7-b533-4e5e457238b5'::uuid, 'holder-exact-full-name', 'Paul McMurtry'),
  ('d5f464b4-a613-407f-92e9-d4adb28c26af', 'fcd06a7a-7f45-4798-baf5-b320702b0636', '11th Plymouth District', 'Representative, 11th Plymouth District', 1, '20261103MA23092', '125151', 'Rita A. Mendes', 'Rita', 'Mendes', false, true, 'Dem', 0, 0, true, true, 'won', '042c79d6-2f15-4e90-b672-ce779a53cae0'::uuid, 'holder-exact-full-name', 'Rita A. Mendes'),
  ('ddb0e4a0-c4ea-41bf-9e9a-7be06549c67d', '70eb9faa-eca6-444e-baf3-90223b35114f', '11th Suffolk District', 'Representative, 11th Suffolk District', 1, '20261103MA23104', '125164', 'Judith Garcia', 'Judith', 'Garcia', false, true, 'Dem', 0, 0, true, true, 'won', 'c4c3ed02-2592-4505-a26c-0195d0b5314e'::uuid, 'holder-exact-first-last', 'Judith A. Garcia'),
  ('0b83779b-cec0-4845-8b8f-a304a6934cfb', 'ab2a442d-f42a-4c42-a53c-3f3ab7d58cf4', '11th Worcester District', 'Representative, 11th Worcester District', 1, '20261103MA22692', '123671', 'Hannah Elizabeth Kane', 'Hannah', 'Kane', false, true, 'GOP', 0, 0, true, true, 'won', 'd54b9791-0668-4397-b488-160d06f7c420'::uuid, 'holder-exact-first-last', 'Hannah E. Kane'),
  ('26239b91-2e06-445a-808b-ebc9aee2f71d', 'dd1694ea-594e-4c46-a86a-d4d8453262c2', '12th Bristol District', 'Representative, 12th Bristol District', 1, '20261103MA23002', '124255', 'Norman J. Orrall', 'Norman', 'Orrall', false, true, 'GOP', 0, 0, true, true, 'won', 'c77f1324-a106-4d45-a044-0174bddfe8e0'::uuid, 'holder-exact-full-name', 'Norman J. Orrall'),
  ('1134551e-c266-4415-8b3a-e36f29c3edd5', '8782d6d8-109f-419b-aa90-59f92900a51d', '12th Essex District', 'Representative, 12th Essex District', 1, '20261103MA24800', '123459', 'Thomas P. Walsh', 'Thomas', 'Walsh', false, true, 'Dem', 0, 0, true, true, 'won', 'ff2939e8-befb-4c16-ace7-9f677847088c'::uuid, 'holder-exact-full-name', 'Thomas P. Walsh'),
  ('3b4471e6-3ab0-4cda-8f79-1704efe5c749', '8395acd9-5438-4ece-9454-05d86c7a6226', '12th Hampden District', 'Representative, 12th Hampden District', 1, '20261103MA23031', '122449', 'Angelo J. Puppolo Jr.', 'Angelo', 'Puppolo', false, true, 'Dem', 0, 0, true, true, 'won', '9b3772d3-3602-457a-82e7-479b5e557b13'::uuid, 'holder-exact-first-last', 'Angelo J. Puppolo'),
  ('87460d07-9ff5-4307-b327-47e21c1711d9', 'a7633c44-be64-4773-869d-bd736060b101', '12th Middlesex District', 'Representative, 12th Middlesex District', 1, '20261103MA23045', '165979', 'Greg Schwartz', 'Greg', 'Schwartz', false, true, 'Dem', 0, 0, true, true, 'won', '8167ef8d-b8c8-44aa-86a2-9128c9078547'::uuid, 'holder-exact-full-name', 'Greg Schwartz'),
  ('3a7b0d33-1469-4c43-b6b3-8a5342410489', 'ecee71c0-7c37-424d-83e4-cd5a3d6111d5', '12th Norfolk District', 'Representative, 12th Norfolk District', 1, '20261103MA23080', '54538', 'John Healy Rogers', 'John', 'Rogers', false, true, 'Dem', 0, 0, true, true, 'won', '730f6bce-4d8c-4ad0-897b-f687971a4d87'::uuid, 'holder-exact-first-last', 'John H. Rogers'),
  ('d89083da-c42f-4090-b086-0790032fd0be', '0c34250e-010d-442b-8323-d16e91a6c3fa', '12th Plymouth District', 'Representative, 12th Plymouth District', 1, '20261103MA23093', '124205', 'Kathleen LaNatra', 'Kathleen', 'LaNatra', false, true, 'Dem', 11668, 56.39, false, true, 'won', 'bb235d49-c91a-45da-8d91-bf3d5b766196'::uuid, 'holder-exact-first-last', 'Kathleen P. LaNatra'),
  ('d89083da-c42f-4090-b086-0790032fd0be', '0c34250e-010d-442b-8323-d16e91a6c3fa', '12th Plymouth District', 'Representative, 12th Plymouth District', 1, '20261103MA23093', '125255', 'Eric J. Meschino', 'Eric', 'Meschino', false, false, 'GOP', 9025, 43.61, false, true, 'lost', NULL, NULL, NULL),
  ('5303a912-8e49-4e54-8cf0-c0085efc1b6a', 'e1b633e3-1e77-4e34-98d7-c7a32742e74c', '12th Suffolk District', 'Representative, 12th Suffolk District', 1, '20261103MA23105', '124648', 'Brandy Fluker Reid', 'Brandy', 'Fluker Reid', false, true, 'Dem', 0, 0, true, true, 'won', '5c497509-7a9d-492b-ac35-ff37f8fcfb82'::uuid, 'holder-exact-full-name', 'Brandy Fluker-Reid'),
  ('5aa7edf0-77c3-44c6-9e6c-703bd66771a9', 'e4d65270-c332-45d7-9ab4-a454fbac2d2a', '12th Worcester District', 'Representative, 12th Worcester District', 1, '20261103MA23122', '124671', 'Meghan Kilcoyne', 'Meghan', 'Kilcoyne', false, true, 'Dem', 12481, 62.78, false, true, 'won', '074555d9-2806-4f78-bce9-1958d61742c6'::uuid, 'holder-exact-full-name', 'Meghan Kilcoyne'),
  ('5aa7edf0-77c3-44c6-9e6c-703bd66771a9', 'e4d65270-c332-45d7-9ab4-a454fbac2d2a', '12th Worcester District', 'Representative, 12th Worcester District', 1, '20261103MA23122', '125380', 'Lisa K. Mair', 'Lisa', 'Mair', false, false, 'GOP', 7399, 37.22, false, true, 'lost', NULL, NULL, NULL),
  ('8314063b-363b-4ea2-b953-4bf5fc744769', 'dbcdf023-5e79-40a6-a5d4-7a6251a51f72', '13th Bristol District', 'Representative, 13th Bristol District', 1, '20261103MA23003', '54454', 'Antonio F. D. Cabral', 'Antonio', 'Cabral', false, true, 'Dem', 0, 0, true, true, 'won', '5e27127a-4df3-4d16-a1a4-2bf081c92842'::uuid, 'holder-exact-first-last', 'Antonio F. Cabral'),
  ('7a75884a-40cb-4b99-8d9e-61aab530208f', 'a93b623b-242c-4934-a9da-aa422fee41e0', '13th Essex District', 'Representative, 13th Essex District', 1, '20261103MA23015', '124559', 'Sally Patrice Kerans', 'Sally', 'Kerans', false, true, 'Dem', 0, 0, true, true, 'won', 'de40220c-2935-42a2-ac90-d662bb47d49b'::uuid, 'holder-exact-first-last', 'Sally P. Kerans'),
  ('a64abe7f-bd5c-4f09-8f14-003687144dac', 'c60006bd-df90-4638-8bce-9a9e605a5bcb', '13th Middlesex District', 'Representative, 13th Middlesex District', 1, '20261103MA22138', '177147', 'Ravi Simon', 'Ravi', 'Simon', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('33a3f264-ccef-434e-a17d-8a6c7df6f11b', '4f796dbe-8765-49bb-b792-afb0137a84bf', '13th Norfolk District', 'Representative, 13th Norfolk District', 1, '20261103MA23081', '166043', 'Joshua Brian Tarsky', 'Joshua', 'Tarsky', false, true, 'Dem', 0, 0, true, true, 'won', 'de311b87-1026-4f61-8e42-110b90491160'::uuid, 'holder-exact-first-last', 'Joshua Tarsky'),
  ('af36de10-3ce7-4ffb-b151-50f61575868d', '4f515c03-15a5-4b77-9138-fd0215162818', '13th Suffolk District', 'Representative, 13th Suffolk District', 1, '20261103MA23106', '123297', 'Daniel J. Hunt', 'Daniel', 'Hunt', false, true, 'Dem', 0, 0, true, true, 'won', '5c36a94c-9006-4550-a37e-978a65d2725c'::uuid, 'holder-exact-full-name', 'Daniel J. Hunt'),
  ('ae69da8b-1dc2-43fa-b400-06d32c80ef78', '79db0c1c-ce46-4f3f-8606-bc446502799c', '13th Worcester District', 'Representative, 13th Worcester District', 1, '20261103MA23123', '123805', 'John J. Mahoney', 'John', 'Mahoney', false, true, 'Dem', 0, 0, true, true, 'won', '50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'holder-exact-full-name', 'John J. Mahoney'),
  ('835e0b90-4bc9-4897-96aa-074a3692f5a9', 'e6795b97-42ec-4798-8cd8-707bf75dc5a6', '14th Bristol District', 'Representative, 14th Bristol District', 1, '20261103MA23004', '124548', 'Adam J. Scanlon', 'Adam', 'Scanlon', false, true, 'Dem', 0, 0, true, true, 'won', 'c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2'::uuid, 'holder-exact-full-name', 'Adam J. Scanlon'),
  ('cee2f64c-2571-4285-8c3f-20a9d506ebb5', '1da263b1-3b0f-4cf2-bcaf-692a50fdf591', '14th Essex District', 'Representative, 14th Essex District', 1, '20261103MA23016', '125054', 'Adrianne Pusateri Ramos', 'Adrianne', 'Ramos', false, true, 'Dem', 0, 0, true, true, 'won', 'ee861f58-dabf-429f-97ee-32591bdd3650'::uuid, 'holder-exact-first-last', 'Adrianne P. Ramos'),
  ('0db0d119-24b3-452c-be8f-456596595c94', 'c061f51e-2529-43ba-ab7e-87570f7d16c8', '14th Middlesex District', 'Representative, 14th Middlesex District', 1, '20261103MA23046', '125104', 'Simon J. Cataldo', 'Simon', 'Cataldo', false, true, 'Dem', 0, 0, true, true, 'won', '918296a2-5def-4ddf-8986-860d542900e7'::uuid, 'holder-exact-first-last', 'Simon Cataldo'),
  ('4f2f34a6-6f07-4fd7-a09c-a5958c165323', 'da18d149-6fdd-405e-9b6c-fef6f80fdd52', '14th Norfolk District', 'Representative, 14th Norfolk District', 1, '20261103MA23082', '122485', 'Alice Hanlon Peisch', 'Alice', 'Peisch', false, true, 'Dem', 0, 0, true, true, 'won', 'ac853e6e-d419-4d05-b89c-77d11bb68fb2'::uuid, 'holder-exact-first-last', 'Alice H. Peisch'),
  ('a937040f-8d0f-4316-bac6-48897a76006e', '36e3f66f-8b76-4c1e-a167-667fbb33943e', '14th Suffolk District', 'Representative, 14th Suffolk District', 1, '20261103MA23107', '123089', 'Rob Consalvo', 'Rob', 'Consalvo', false, true, 'Dem', 0, 0, true, true, 'won', '3f5dd4b3-c0b6-470b-861d-41a71637797c'::uuid, 'holder-exact-full-name', 'Rob Consalvo'),
  ('9e3937ab-883e-4a64-ab14-984f4208b838', 'ec5de6fb-6946-4081-84fc-7582d9d1b7c7', '14th Worcester District', 'Representative, 14th Worcester District', 1, '20261103MA23124', '122526', 'James J. O''Day', 'James', 'O''Day', false, true, 'Dem', 0, 0, true, true, 'won', '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'holder-exact-full-name', 'James J. O''Day'),
  ('99a57eec-d48e-422d-9c49-06361da77b54', '7f54557d-ce53-49ae-b9e1-f8bf0170134e', '15th Essex District', 'Representative, 15th Essex District', 1, '20261103MA23017', '125059', 'Ryan M. Hamilton', 'Ryan', 'Hamilton', false, true, 'Dem', 10756, 61.88, false, true, 'won', 'bdc19d3c-1169-4923-9ed9-f914b73f63e9'::uuid, 'holder-exact-full-name', 'Ryan M. Hamilton'),
  ('99a57eec-d48e-422d-9c49-06361da77b54', '7f54557d-ce53-49ae-b9e1-f8bf0170134e', '15th Essex District', 'Representative, 15th Essex District', 1, '20261103MA23017', '177339', 'Ronald L. Heiseler III', 'Ronald', 'Heiseler', false, false, 'GOP', 6625, 38.12, false, true, 'lost', NULL, NULL, NULL),
  ('56545025-7bbe-4932-a2bc-2237089d7204', '28a1b8b2-c873-4e16-aaa6-c089cdd7d404', '15th Middlesex District', 'Representative, 15th Middlesex District', 1, '20261103MA23047', '124143', 'Michelle Ciccolo', 'Michelle', 'Ciccolo', false, true, 'Dem', 0, 0, true, true, 'won', '0748d787-7e5d-4852-b461-3459312fae45'::uuid, 'holder-exact-full-name', 'Michelle Ciccolo'),
  ('c93a1323-853b-466a-960e-36f30b8632fd', '139e2827-0021-4119-8cba-3bfa13970db8', '15th Norfolk District', 'Representative, 15th Norfolk District', 1, '20261103MA23083', '124192', 'Tommy Vitolo', 'Tommy', 'Vitolo', false, true, 'Dem', 0, 0, true, true, 'won', '001147b2-5c07-499e-85b9-bae224fdc73a'::uuid, 'holder-exact-full-name', 'Tommy Vitolo'),
  ('f3eb2042-ecf7-4748-9474-54d0901bfcc5', '64a2eb52-f9cd-43ab-a3c6-0ca839461ff1', '15th Suffolk District', 'Representative, 15th Suffolk District', 1, '20261103MA23108', '125180', 'Samantha Montaño', 'Samantha', 'Montaño', false, true, 'Dem', 0, 0, true, true, 'won', '28a703f8-8316-4d3c-bfc0-3dcd77eab96c'::uuid, 'holder-exact-full-name', 'Samantha Montaño'),
  ('7f606c6e-1d72-45d7-9277-d7aea91a6db0', 'ae0f47df-6c68-471c-ae26-f9ef7b24852a', '15th Worcester District', 'Representative, 15th Worcester District', 1, '20261103MA23125', '122861', 'Mary S. Keefe', 'Mary', 'Keefe', false, true, 'Dem', 0, 0, true, true, 'won', 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'holder-exact-full-name', 'Mary S. Keefe'),
  ('361072ec-18dc-4e4a-b81f-64b4a0d626ba', 'e6c936c2-1f0e-4e1f-befe-5507d8ff430d', '16th Essex District', 'Representative, 16th Essex District', 1, '20261103MA23018', '177136', 'Celina A. Reyes', 'Celina', 'Reyes', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('e87cc665-0d62-4b87-b940-cfd44b42035a', 'd58c7412-efc9-45f1-bc9f-ffb2b1f463e4', '16th Middlesex District', 'Representative, 16th Middlesex District', 1, '20261103MA22141', '177148', 'Lorena G. Betts', 'Lorena', 'Betts', false, false, 'Dem', 7933, 68.23, false, true, 'won', NULL, NULL, NULL),
  ('e87cc665-0d62-4b87-b940-cfd44b42035a', 'd58c7412-efc9-45f1-bc9f-ffb2b1f463e4', '16th Middlesex District', 'Representative, 16th Middlesex District', 1, '20261103MA22141', '125231', 'Karla J. Miller', 'Karla', 'Miller', false, false, 'GOP', 3693, 31.77, false, true, 'lost', NULL, NULL, NULL),
  ('3f958bca-4d4a-4b25-86b7-8cc660f1119e', 'bf0080eb-d9e9-466a-9b4e-749674b9322d', '16th Suffolk District', 'Representative, 16th Suffolk District', 1, '20261103MA23109', '124654', 'Jessica Ann Giannino', 'Jessica', 'Giannino', false, true, 'Dem', 0, 0, true, true, 'won', '1f4c93e7-37a6-4577-a2bc-d77218ad1feb'::uuid, 'holder-exact-first-last', 'Jessica A. Giannino'),
  ('f4bc8e4f-0aee-4e88-b806-1d5830cd2f8a', '465ac95d-bd82-4dcb-a38c-cf28dceec4ab', '16th Worcester District', 'Representative, 16th Worcester District', 1, '20261103MA23126', '123311', 'Daniel M. Donahue', 'Daniel', 'Donahue', false, true, 'Dem', 0, 0, true, true, 'won', '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'holder-exact-full-name', 'Daniel M. Donahue'),
  ('2f090d3f-e520-4a70-b11a-0614afed9bd4', '35b5d869-7803-45b2-894e-f98cc67bf025', '17th Essex District', 'Representative, 17th Essex District', 1, '20261103MA22107', '122795', 'Frank A. Moran', 'Frank', 'Moran', false, true, 'Dem', 0, 0, true, true, 'won', '5729a0a4-40a9-41bd-82a4-9a0bea757567'::uuid, 'holder-exact-full-name', 'Frank A. Moran'),
  ('d94bf7f0-a832-4651-b05c-9da9141aec75', 'b45625f8-4c85-4924-b850-f2ba0fdf0c24', '17th Middlesex District', 'Representative, 17th Middlesex District', 1, '20261103MA23048', '124002', 'John M. Drinkwater', 'John', 'Drinkwater', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('5465ecbb-ccb0-4283-8df0-785b154013de', 'cc8c133e-09e1-4675-8c68-32a5a464dc5f', '17th Suffolk District', 'Representative, 17th Suffolk District', 1, '20261103MA23110', '54570', 'Kevin G. Honan', 'Kevin', 'Honan', false, true, 'Dem', 0, 0, true, true, 'won', 'c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid, 'holder-exact-full-name', 'Kevin G. Honan'),
  ('4550977e-0f28-4b3f-b873-e2e3ad28ec3c', 'e9f8474f-3be8-4647-bdd6-6361787c9e45', '17th Worcester District', 'Representative, 17th Worcester District', 1, '20261103MA23127', '124250', 'David Henry Argosky LeBoeuf', 'David', 'LeBoeuf', false, true, 'Dem', 0, 0, true, true, 'won', '3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'holder-exact-first-last', 'David A. LeBoeuf'),
  ('e6e13581-c1b3-4f47-9d76-c20224903f7e', '2204deff-887e-4b97-b5ea-b9fdf12a0698', '18th Essex District', 'Representative, 18th Essex District', 1, '20261103MA23877', '177137', 'Connor A. Murray', 'Connor', 'Murray', false, false, 'Dem', 11758, 61.71, false, true, 'won', NULL, NULL, NULL),
  ('e6e13581-c1b3-4f47-9d76-c20224903f7e', '2204deff-887e-4b97-b5ea-b9fdf12a0698', '18th Essex District', 'Representative, 18th Essex District', 1, '20261103MA23877', '179222', 'Christopher C. Shepley', 'Christopher', 'Shepley', false, false, 'GOP', 7295, 38.29, false, true, 'lost', NULL, NULL, NULL),
  ('2a130497-d6f1-4a00-8b6b-fee33ee2bffe', '1a2ec269-121d-4f68-a64e-905952904c98', '18th Middlesex District', 'Representative, 18th Middlesex District', 1, '20261103MA23049', '125113', 'Tara Hong', 'Tara', 'Hong', false, true, 'Dem', 0, 0, true, true, 'won', '18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'::uuid, 'holder-exact-first-last', 'Tara T. Hong'),
  ('ba181562-0913-4d0a-937f-af9fd0152d83', '11c21c28-8d8b-4224-afc8-ea7516196c81', '18th Suffolk District', 'Representative, 18th Suffolk District', 1, '20261103MA23111', '122514', 'Michael J. Moran', 'Michael', 'Moran', false, true, 'Dem', 0, 0, true, true, 'won', '9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'holder-exact-full-name', 'Michael J. Moran'),
  ('9959a128-2d0a-4eb2-ac59-894a433adcff', '5684e252-de5d-40b1-bd2f-2f653f68d0f0', '18th Worcester District', 'Representative, 18th Worcester District', 1, '20261103MA23878', '123340', 'Joseph D. McKenna', 'Joseph', 'McKenna', false, true, 'GOP', 11061, 57.36, false, true, 'won', '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'holder-exact-full-name', 'Joseph D. McKenna'),
  ('9959a128-2d0a-4eb2-ac59-894a433adcff', '5684e252-de5d-40b1-bd2f-2f653f68d0f0', '18th Worcester District', 'Representative, 18th Worcester District', 1, '20261103MA23878', '177333', 'Jenifer Heck', 'Jenifer', 'Heck', false, false, 'Dem', 8222, 42.64, false, true, 'lost', NULL, NULL, NULL),
  ('945c184c-a256-46d9-b2f1-ea20a9e06614', '20466a5d-1fa0-4d7b-96db-5003ccef3880', '19th Middlesex District', 'Representative, 19th Middlesex District', 1, '20261103MA23050', '124168', 'David Allen Robertson', 'David', 'Robertson', false, true, 'Dem', 0, 0, true, true, 'won', 'f8ae17d7-bc53-4b74-a92e-efa122cd5f04'::uuid, 'holder-exact-first-last', 'David Robertson'),
  ('be56563a-9b07-4040-bf10-e1827b570def', '0827e6e5-1cbb-491a-943e-6db039a47859', '19th Suffolk District', 'Representative, 19th Suffolk District', 1, '20261103MA23112', '125187', 'Jeffrey Rosario Turco', 'Jeffrey', 'Turco', false, true, 'Dem', 0, 0, true, true, 'won', 'c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid, 'holder-exact-first-last', 'Jeffrey R. Turco'),
  ('23e7a30c-000f-424c-a620-02b30a7c11e0', '17556c39-aa6a-4cd1-a0b4-7c032532fb68', '19th Worcester District', 'Representative, 19th Worcester District', 1, '20261103MA22991', '125193', 'Kate Donaghue', 'Kate', 'Donaghue', false, true, 'Dem', 0, 0, true, true, 'won', '6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'::uuid, 'holder-exact-full-name', 'Kate Donaghue'),
  ('6f3da047-bebe-443e-917d-0ce6eab9e393', '64c60932-fc4e-4a6f-8bf2-113235a9af89', '1st Barnstable District', 'Representative, 1st Barnstable District', 1, '20261103MA22984', '177062', 'Christopher Lambton', 'Christopher', 'Lambton', false, false, 'Dem', 15028, 68.85, false, true, 'won', NULL, NULL, NULL),
  ('6f3da047-bebe-443e-917d-0ce6eab9e393', '64c60932-fc4e-4a6f-8bf2-113235a9af89', '1st Barnstable District', 'Representative, 1st Barnstable District', 1, '20261103MA22984', '179356', 'Joe B. Glynn', 'Joe', 'Glynn', false, false, 'Oth', 6798, 31.15, false, true, 'lost', NULL, NULL, NULL),
  ('254752fa-ce5e-42e1-9fb5-40bfda96f466', '3cae016a-cfe6-413a-b9fe-7d58fab21c77', '1st Berkshire District', 'Representative, 1st Berkshire District', 1, '20261103MA22989', '177064', 'John Barrett III', 'John', 'Barrett', false, true, 'Dem', 0, 0, true, true, 'won', 'ecddb344-846b-4b7d-b712-3a7db8b47ef6'::uuid, 'holder-exact-first-last', 'John Barrett'),
  ('cf96bc20-3b53-48fa-ada5-7f83124bca7f', '66a6681e-6ea0-47c5-8a79-debfbbe8db3a', '1st Bristol District', 'Representative, 1st Bristol District', 1, '20261103MA23880', '125365', 'Michael Chaisson', 'Michael', 'Chaisson', false, true, 'GOP', 0, 0, true, true, 'won', '69a4aaa2-5265-45e0-87c7-8cea22b2dc18'::uuid, 'holder-exact-first-last', 'Michael S. Chaisson'),
  ('4603475c-cf9b-436d-a9ac-52ff067467d1', '11aee3b2-92c4-4cdf-8c62-99d79a0e634b', '1st Essex District', 'Representative, 1st Essex District', 1, '20261103MA22091', '125392', 'Dawne Frances Shand', 'Dawne', 'Shand', false, true, 'Dem', 0, 0, true, true, 'won', '8ee72aa5-b7a0-422f-817d-a330f29dd2b1'::uuid, 'holder-exact-first-last', 'Dawne Shand'),
  ('d108d257-85da-4b9f-adae-a31c0a5a0de2', '4965c918-2024-4b4c-aaf1-a8b4ca45bfea', '1st Franklin District', 'Representative, 1st Franklin District', 1, '20261103MA23019', '177139', 'Lora L. Wondolowski', 'Lora', 'Wondolowski', false, false, 'Dem', 14211, 74, false, true, 'won', NULL, NULL, NULL),
  ('d108d257-85da-4b9f-adae-a31c0a5a0de2', '4965c918-2024-4b4c-aaf1-a8b4ca45bfea', '1st Franklin District', 'Representative, 1st Franklin District', 1, '20261103MA23019', '179359', 'Amy E. Lavallee', 'Amy', 'Lavallee', false, false, 'Unr', 4992, 26, false, true, 'lost', NULL, NULL, NULL),
  ('97fc1091-c13a-40b2-a913-efc045c9a44e', '5c7da011-8046-4502-b4f8-255f83f4a4aa', '1st Hampden District', 'Representative, 1st Hampden District', 1, '20261103MA23021', '122551', 'Todd M. Smola', 'Todd', 'Smola', false, true, 'GOP', 0, 0, true, true, 'won', 'aca1e324-cc09-4492-a2f7-d795beb752ff'::uuid, 'holder-exact-full-name', 'Todd M. Smola'),
  ('c33c1190-0c21-4b7c-a219-ff55cc239f91', '81f49d07-98f5-44cb-ad68-e9a69de9e8ea', '1st Hampshire District', 'Representative, 1st Hampshire District', 1, '20261103MA23033', '124122', 'Lindsay N. Sabadosa', 'Lindsay', 'Sabadosa', false, true, 'Dem', 0, 0, true, true, 'won', '853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'::uuid, 'holder-exact-first-last', 'Lindsay Sabadosa'),
  ('68be3cf5-2b16-4c5d-9395-1fe1bc8d121a', '571a739e-5509-4d10-b356-e056eae33868', '1st Middlesex District', 'Representative, 1st Middlesex District', 1, '20261103MA23036', '125078', 'Margaret R. Scarsdale', 'Margaret', 'Scarsdale', false, true, 'Dem', 12574, 59.77, false, true, 'won', 'a0dc1cc3-efcf-4109-9f9b-4d8b36452361'::uuid, 'holder-exact-full-name', 'Margaret R. Scarsdale'),
  ('68be3cf5-2b16-4c5d-9395-1fe1bc8d121a', '571a739e-5509-4d10-b356-e056eae33868', '1st Middlesex District', 'Representative, 1st Middlesex District', 1, '20261103MA23036', '177341', 'Christopher M. Lyons', 'Christopher', 'Lyons', false, false, 'GOP', 8464, 40.23, false, true, 'lost', NULL, NULL, NULL),
  ('26ae368d-5905-4daa-a144-e13ddd138d4d', '9011ee8b-0738-4a17-bb3f-2f09e8a9982c', '1st Norfolk District', 'Representative, 1st Norfolk District', 1, '20261103MA23069', '122581', 'Bruce J. Ayers', 'Bruce', 'Ayers', false, true, 'Dem', 0, 0, true, true, 'won', '3582a053-ee20-4391-904f-3905a2d13a52'::uuid, 'holder-exact-full-name', 'Bruce J. Ayers'),
  ('d9c31493-2b85-4ba7-beef-741b1461063a', '705a178e-5fa6-4480-a298-48d8f9822d09', '1st Plymouth District', 'Representative, 1st Plymouth District', 1, '20261103MA23084', '166044', 'Michelle L. Badger', 'Michelle', 'Badger', false, true, 'Dem', 14221, 59.57, false, true, 'won', '29af459c-8142-487d-bb51-2224983faca3'::uuid, 'holder-exact-full-name', 'Michelle L. Badger'),
  ('d9c31493-2b85-4ba7-beef-741b1461063a', '705a178e-5fa6-4480-a298-48d8f9822d09', '1st Plymouth District', 'Representative, 1st Plymouth District', 1, '20261103MA23084', '177346', 'David Michael Golden Jr.', 'David', 'Golden', false, false, 'GOP', 9652, 40.43, false, true, 'lost', NULL, NULL, NULL),
  ('80110fdb-c922-4e88-9289-a2bbf1f8c5a3', 'f3e4ecdd-4951-4523-bf33-c23423fdd4c5', '1st Suffolk District', 'Representative, 1st Suffolk District', 1, '20261103MA23094', '123635', 'Adrian C. Madaro', 'Adrian', 'Madaro', false, true, 'Dem', 0, 0, true, true, 'won', '290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid, 'holder-exact-full-name', 'Adrian C. Madaro'),
  ('34fa464e-556d-4b95-aa4b-1f4e3653c0ed', '2d5fc308-1e42-4e8f-afd6-786994849783', '1st Worcester District', 'Representative, 1st Worcester District', 1, '20261103MA23113', '177327', 'Krista Suzanne Ferrante', 'Krista', 'Ferrante', false, false, 'Dem', 11630, 53.3, false, true, 'won', NULL, NULL, NULL),
  ('34fa464e-556d-4b95-aa4b-1f4e3653c0ed', '2d5fc308-1e42-4e8f-afd6-786994849783', '1st Worcester District', 'Representative, 1st Worcester District', 1, '20261103MA23113', '177349', 'Stephanie R. Mulroy', 'Stephanie', 'Mulroy', false, false, 'GOP', 10188, 46.7, false, true, 'lost', NULL, NULL, NULL),
  ('43a09386-34a7-4b62-87b2-584502472947', '3194a56e-8354-4732-a81b-7ad3edf14104', '20th Middlesex District', 'Representative, 20th Middlesex District', 1, '20261103MA23051', '177344', 'Trevor David Currier', 'Trevor', 'Currier', false, false, 'GOP', 9573, 44.52, false, true, 'lost', NULL, NULL, NULL),
  ('43a09386-34a7-4b62-87b2-584502472947', '3194a56e-8354-4732-a81b-7ad3edf14104', '20th Middlesex District', 'Representative, 20th Middlesex District', 1, '20261103MA23051', '177153', 'Joseph Markey', 'Joseph', 'Markey', false, false, 'Dem', 11932, 55.48, false, true, 'won', NULL, NULL, NULL),
  ('08fa0826-cbb3-4e6c-842a-28bb7aa14ee3', 'be79a457-90d4-4988-a6ff-b2ac3a0c26ad', '21st Middlesex District', 'Representative, 21st Middlesex District', 1, '20261103MA23052', '123054', 'Kenneth Ira Gordon', 'Kenneth', 'Gordon', false, true, 'Dem', 0, 0, true, true, 'won', 'afb64fe5-b2a7-4c47-b113-5200ed26182a'::uuid, 'holder-exact-first-last', 'Kenneth I. Gordon'),
  ('3f78cdc9-c79e-4e72-b101-8e7266039187', 'c3fabd25-2cec-41ef-a0fd-d435b4adcb19', '22nd Middlesex District', 'Representative, 22nd Middlesex District', 1, '20261103MA23053', '122373', 'Marc T. Lombardo', 'Marc', 'Lombardo', false, true, 'GOP', 8530, 48.75, false, true, 'lost', 'e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48'::uuid, 'holder-exact-full-name', 'Marc T. Lombardo'),
  ('3f78cdc9-c79e-4e72-b101-8e7266039187', 'c3fabd25-2cec-41ef-a0fd-d435b4adcb19', '22nd Middlesex District', 'Representative, 22nd Middlesex District', 1, '20261103MA23053', '177154', 'Daniel Ronald Darris-O''Connor', 'Daniel', 'Darris-O''Connor', false, false, 'Dem', 8968, 51.25, false, true, 'won', NULL, NULL, NULL),
  ('76bbeca2-d43c-4818-8f26-066782be89c8', '4bc47f0c-e864-469f-b090-4542cc3bf4ab', '23rd Middlesex District', 'Representative, 23rd Middlesex District', 1, '20261103MA23054', '122460', 'Sean Garballey', 'Sean', 'Garballey', false, true, 'Dem', 0, 0, true, true, 'won', '7072bd94-b465-414e-bcf5-6e3feb7ec8dd'::uuid, 'holder-exact-full-name', 'Sean Garballey'),
  ('7a3b2d37-f415-413a-9d42-cc8005a9224f', '30aaa2be-1f7c-4570-8af1-4fd2fe873467', '24th Middlesex District', 'Representative, 24th Middlesex District', 1, '20261103MA23055', '122815', 'David M. Rogers', 'David', 'Rogers', false, true, 'Dem', 0, 0, true, true, 'won', 'ffb8e526-7ad7-4911-92c5-d69528a0f280'::uuid, 'holder-exact-full-name', 'David M. Rogers'),
  ('686788ba-23dd-4716-aa0d-c49cbfa2d6ee', '93781fcf-0085-4c78-80a0-3362b58aff10', '27th Middlesex District', 'Representative, 27th Middlesex District', 1, '20261103MA23058', '177157', 'Ben Ewen-Campen', 'Ben', 'Ewen-Campen', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('b0e268ca-75f6-416f-91e9-187feedf3b8f', '403dd523-2228-4736-aaab-e005cc7bfeb1', '28th Middlesex District', 'Representative, 28th Middlesex District', 1, '20261103MA23059', '123229', 'Joseph W. McGonagle', 'Joseph', 'McGonagle', false, true, 'Dem', 0, 0, true, true, 'won', '4a818693-d820-4f4a-94b7-3d43a2381e1c'::uuid, 'holder-exact-full-name', 'Joseph W. McGonagle'),
  ('fe9e9c9c-a8cd-4142-9dde-75bd3a6efb24', 'c3e9c9a1-e1f1-436c-95ac-8bdcc2b6306b', '29th Middlesex District', 'Representative, 29th Middlesex District', 1, '20261103MA23060', '124616', 'Steven Charles Owens', 'Steven', 'Owens', false, true, 'Dem', 0, 0, true, true, 'won', '1d78debb-efd5-45e8-9204-06aab3076b2a'::uuid, 'holder-exact-first-last', 'Steven C. Owens'),
  ('33d4b3db-dfac-4dc5-97f7-78ee75688f52', '96f96273-e9b5-47aa-9b75-402556d9966a', '2nd Barnstable District', 'Representative, 2nd Barnstable District', 1, '20261103MA22985', '124804', 'Kip A. Diggs', 'Kip', 'Diggs', false, true, 'Dem', 0, 0, true, true, 'won', '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'::uuid, 'holder-exact-full-name', 'Kip A. Diggs'),
  ('fa9ec805-becb-4f51-b301-c15ba1b588cc', 'cf506834-9f4c-449a-af39-29a2e6d9c6d7', '2nd Berkshire District', 'Representative, 2nd Berkshire District', 1, '20261103MA23345', '63073', 'Tricia Farley-Bouvier', 'Tricia', 'Farley-Bouvier', false, true, 'Dem', 0, 0, true, true, 'won', '15c27efb-0402-4a3a-bfad-9df152874046'::uuid, 'holder-exact-full-name', 'Tricia Farley-Bouvier'),
  ('2cc5ca12-f337-4cb9-b02a-877c9e95965c', 'd04f0a31-0522-4b18-a17f-bc1d49594bbd', '2nd Bristol District', 'Representative, 2nd Bristol District', 1, '20261103MA23881', '124063', 'James Kimball Hawkins', 'James', 'Hawkins', false, true, 'Dem', 9986, 74.76, false, true, 'won', '95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, 'holder-exact-first-last', 'James K. Hawkins'),
  ('2cc5ca12-f337-4cb9-b02a-877c9e95965c', 'd04f0a31-0522-4b18-a17f-bc1d49594bbd', '2nd Bristol District', 'Representative, 2nd Bristol District', 1, '20261103MA23881', '179357', 'Andrew Nelson', 'Andrew', 'Nelson', false, false, 'Oth', 3372, 25.24, false, true, 'lost', NULL, NULL, NULL),
  ('ec86537e-2c62-4766-8bf0-8581929bb981', '128413a7-5b11-45b6-aebc-4e05e4867438', '2nd Essex District', 'Representative, 2nd Essex District', 1, '20261103MA23005', '125018', 'Kristin Elena Kassner', 'Kristin', 'Kassner', false, true, 'Dem', 14444, 59.18, false, true, 'won', '36343ab4-817f-44eb-9221-15eb338af57a'::uuid, 'holder-exact-first-last', 'Kristin Kassner'),
  ('ec86537e-2c62-4766-8bf0-8581929bb981', '128413a7-5b11-45b6-aebc-4e05e4867438', '2nd Essex District', 'Representative, 2nd Essex District', 1, '20261103MA23005', '165831', 'Daniel James Kelly', 'Daniel', 'Kelly', false, false, 'GOP', 9961, 40.82, false, true, 'lost', NULL, NULL, NULL),
  ('a1d3afe7-3abc-4933-8447-239a29fdfd43', '71f2e12c-7963-4c6a-bfc9-967769761f03', '2nd Franklin District', 'Representative, 2nd Franklin District', 1, '20261103MA23020', '122900', 'Susannah M. Whipps', 'Susannah', 'Whipps', false, true, 'Ind', 0, 0, true, true, 'won', '9081c52c-92ea-4a75-84b1-96305fafd333'::uuid, 'holder-exact-first-last', 'Susannah L. Whipps'),
  ('8e6fa376-c203-46ad-b22a-6b09f2911ddc', '1eaf1324-8e05-41e0-972d-aa26aefc5305', '2nd Hampden District', 'Representative, 2nd Hampden District', 1, '20261103MA23022', '122446', 'Brian Michael Ashe', 'Brian', 'Ashe', false, true, 'Dem', 12203, 64.22, false, true, 'won', '1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'holder-exact-first-last', 'Brian M. Ashe'),
  ('8e6fa376-c203-46ad-b22a-6b09f2911ddc', '1eaf1324-8e05-41e0-972d-aa26aefc5305', '2nd Hampden District', 'Representative, 2nd Hampden District', 1, '20261103MA23022', '177340', 'Peter Warren', 'Peter', 'Warren', false, false, 'GOP', 6798, 35.78, false, true, 'lost', NULL, NULL, NULL),
  ('73b8a1d7-72a1-4d3b-b191-f326397e94e1', '62eb4f42-c91c-4843-b927-11e13cd97227', '2nd Hampshire District', 'Representative, 2nd Hampshire District', 1, '20261103MA23034', '165969', 'Homar Gomez', 'Homar', 'Gomez', false, true, 'Dem', 0, 0, true, true, 'won', '3ea88aee-8bc7-4ddf-b897-5aa8111fadc8'::uuid, 'holder-exact-full-name', 'Homar Gómez'),
  ('e3dd9622-b8ac-44aa-97e3-890f2e46fe49', 'dff0c0cd-27af-4fd5-b1da-ea3ed297ac75', '2nd Middlesex District', 'Representative, 2nd Middlesex District', 1, '20261103MA23037', '122451', 'James Arciero', 'James', 'Arciero', false, true, 'Dem', 0, 0, true, true, 'won', 'f392e7c6-0ab2-4834-9a57-df86541f55d3'::uuid, 'holder-exact-full-name', 'James Arciero'),
  ('6d1a15f1-b81e-41ff-92fe-08f67d3f6c07', 'e4445466-0eb2-42bc-9c6b-67374f1e84da', '2nd Norfolk District', 'Representative, 2nd Norfolk District', 1, '20261103MA23070', '122188', 'Tackey Chan', 'Tackey', 'Chan', false, true, 'Dem', 10369, 72.33, false, true, 'won', '90602902-b178-4709-a74b-68b30fe45394'::uuid, 'holder-exact-full-name', 'Tackey Chan'),
  ('6d1a15f1-b81e-41ff-92fe-08f67d3f6c07', 'e4445466-0eb2-42bc-9c6b-67374f1e84da', '2nd Norfolk District', 'Representative, 2nd Norfolk District', 1, '20261103MA23070', '125239', 'Sharon Marie Cintolo', 'Sharon', 'Cintolo', false, false, 'GOP', 3966, 27.67, false, true, 'lost', NULL, NULL, NULL),
  ('4b1351ec-87d1-46b9-b657-e7fd27deb97e', '6cce3ea2-edc2-4210-ab09-d864c3a281de', '2nd Plymouth District', 'Representative, 2nd Plymouth District', 1, '20261103MA22180', '166153', 'John Robert Gaskey', 'John', 'Gaskey', false, true, 'GOP', 9175, 49.76, false, false, NULL, '08a2dfdf-43fb-408a-b758-aa94497fd871'::uuid, 'holder-exact-first-last', 'John R. Gaskey'),
  ('4b1351ec-87d1-46b9-b657-e7fd27deb97e', '6cce3ea2-edc2-4210-ab09-d864c3a281de', '2nd Plymouth District', 'Representative, 2nd Plymouth District', 1, '20261103MA22180', '123614', 'Sarah G. Hewins', 'Sarah', 'Hewins', false, false, 'Dem', 9264, 50.24, false, false, NULL, NULL, NULL, NULL),
  ('0c513f65-471b-4744-9258-55c1352db9bf', '8ad55525-2d37-423c-bd01-f170b26421ab', '2nd Suffolk District', 'Representative, 2nd Suffolk District', 1, '20261103MA23095', '123283', 'Daniel J. Ryan', 'Daniel', 'Ryan', false, true, 'Dem', 0, 0, true, true, 'won', '6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid, 'holder-exact-full-name', 'Daniel J. Ryan'),
  ('9c4391ad-0c02-499e-b4d5-81d42a26df3e', '97832067-3c80-4588-afff-c648a0996c52', '2nd Worcester District', 'Representative, 2nd Worcester District', 1, '20261103MA23114', '177328', 'Michael Joseph Nicholson', 'Michael', 'Nicholson', false, false, 'Dem', 8453, 55.68, false, true, 'won', NULL, NULL, NULL),
  ('9c4391ad-0c02-499e-b4d5-81d42a26df3e', '97832067-3c80-4588-afff-c648a0996c52', '2nd Worcester District', 'Representative, 2nd Worcester District', 1, '20261103MA23114', '179365', 'John D. Reilly Jr.', 'John', 'Reilly', false, false, 'Unr', 6729, 44.32, false, true, 'lost', NULL, NULL, NULL),
  ('4fe4b294-6d7f-44a3-a7f2-10854879029f', 'd04d8c63-358f-4134-8ad5-0be5c32f9937', '30th Middlesex District', 'Representative, 30th Middlesex District', 1, '20261103MA23061', '124176', 'Richard M. Haggerty', 'Richard', 'Haggerty', false, true, 'Dem', 0, 0, true, true, 'won', '2d3def44-9916-469d-8f8f-b098ad896768'::uuid, 'holder-exact-full-name', 'Richard M. Haggerty'),
  ('fba65f8a-de2a-4723-af52-5960caed3759', 'd538ca2b-cdd6-4fae-90bb-5139a5c5457f', '31st Middlesex District', 'Representative, 31st Middlesex District', 1, '20261103MA23062', '123234', 'Michael Seamus Day', 'Michael', 'Day', false, true, 'Dem', 12991, 68.2, false, true, 'won', 'ff5cc07a-b904-4365-bcac-027bb50e8a8e'::uuid, 'holder-exact-first-last', 'Michael S. Day'),
  ('fba65f8a-de2a-4723-af52-5960caed3759', 'd538ca2b-cdd6-4fae-90bb-5139a5c5457f', '31st Middlesex District', 'Representative, 31st Middlesex District', 1, '20261103MA23062', '177345', 'Stephen G. Ternullo', 'Stephen', 'Ternullo', false, false, 'GOP', 6058, 31.8, false, true, 'lost', NULL, NULL, NULL),
  ('69fc590f-33e5-47ef-8c6d-0bbc5c612d61', 'b385eb71-cc88-4bb8-ac40-b6189cb29c1a', '32nd Middlesex District', 'Representative, 32nd Middlesex District', 1, '20261103MA23063', '177161', 'Leila Bhatti Migliorelli', 'Leila', 'Migliorelli', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('06eb5504-2679-4373-a2ca-f0d838ee4c50', '3e7857b5-1615-4fd3-a4b7-56a74948ff62', '33rd Middlesex District', 'Representative, 33rd Middlesex District', 1, '20261103MA23064', '123237', 'Steven Ultrino', 'Steven', 'Ultrino', false, true, 'Dem', 0, 0, true, true, 'won', '0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7'::uuid, 'holder-exact-full-name', 'Steven Ultrino'),
  ('99aa4f09-2a6b-4ce7-aff6-9ed55f041db0', '2842d56f-2608-4fcc-962d-51d14469f054', '34th Middlesex District', 'Representative, 34th Middlesex District', 1, '20261103MA23065', '177162', 'Will Mbah', 'Will', 'Mbah', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('ab751007-01f6-48ed-bc3f-acb9eacd17ad', '7078ae48-baa7-4422-9c56-26eb13341222', '35th Middlesex District', 'Representative, 35th Middlesex District', 1, '20261103MA22160', '122473', 'Paul J. Donato', 'Paul', 'Donato', false, true, 'Dem', 10256, 81.78, false, true, 'won', 'a73b7873-74df-484f-bfab-3b0d905972d9'::uuid, 'holder-exact-full-name', 'Paul J. Donato'),
  ('ab751007-01f6-48ed-bc3f-acb9eacd17ad', '7078ae48-baa7-4422-9c56-26eb13341222', '35th Middlesex District', 'Representative, 35th Middlesex District', 1, '20261103MA22160', '177954', 'James C. Seibel', 'James', 'Seibel', false, false, 'GOP', 2285, 18.22, false, true, 'lost', NULL, NULL, NULL),
  ('0d0a9e91-70f3-4455-8cfa-d5143c2bdac1', '9bc50181-2535-42ad-adc9-a40873d04f6c', '36th Middlesex District', 'Representative, 36th Middlesex District', 1, '20261103MA23066', '122577', 'Colleen M. Garry', 'Colleen', 'Garry', false, true, 'Dem', 0, 0, true, true, 'won', 'c8f917f9-f6c4-49f8-b5a4-c330b07f90d2'::uuid, 'holder-exact-full-name', 'Colleen M. Garry'),
  ('a4184720-3140-4507-a19f-0f14c12dea2a', '95af1f10-1cf3-4ee9-944a-c8c17824708c', '37th Middlesex District', 'Representative, 37th Middlesex District', 1, '20261103MA23067', '124622', 'Danillo A. Sena', 'Danillo', 'Sena', false, true, 'Dem', 0, 0, true, true, 'won', 'f8986c05-2e32-4184-bfb2-9d4c244ffd3a'::uuid, 'holder-exact-first-last', 'Danillo Sena'),
  ('a6a888a4-076b-47be-b391-500a33f9b184', 'd341c6c6-3e35-4493-8986-c98a7c9753c0', '3rd Barnstable District', 'Representative, 3rd Barnstable District', 1, '20261103MA22986', '122326', 'David T. Vieira', 'David', 'Vieira', false, true, 'GOP', 11483, 48.27, false, true, 'lost', '35f10acb-fe09-40eb-a847-195fffee6f25'::uuid, 'holder-exact-full-name', 'David T. Vieira'),
  ('a6a888a4-076b-47be-b391-500a33f9b184', 'd341c6c6-3e35-4493-8986-c98a7c9753c0', '3rd Barnstable District', 'Representative, 3rd Barnstable District', 1, '20261103MA22986', '177063', 'Jack Peter Richardson', 'Jack', 'Richardson', false, false, 'Dem', 12308, 51.73, false, true, 'won', NULL, NULL, NULL),
  ('0f1fc645-d423-4b29-9bd4-416486e23927', '3c3e4f90-039a-4063-b257-1952ad6a0e61', '3rd Berkshire District', 'Representative, 3rd Berkshire District', 1, '20261103MA22990', '165953', 'Leigh Susan Davis', 'Leigh', 'Davis', false, true, 'Dem', 0, 0, true, true, 'won', 'ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'::uuid, 'holder-exact-first-last', 'Leigh S. Davis'),
  ('ef79d34f-1f09-4799-9069-9dc2de791ae3', '756d67d2-ffdc-4cd6-9b0a-3ba2a0ebb03f', '3rd Bristol District', 'Representative, 3rd Bristol District', 1, '20261103MA22993', '177126', 'Lisa M. Field', 'Lisa', 'Field', false, true, 'Dem', 9068, 58.29, false, true, 'won', 'acf7819a-3e36-4d17-8828-3238adb894b0'::uuid, 'holder-exact-full-name', 'Lisa M. Field'),
  ('ef79d34f-1f09-4799-9069-9dc2de791ae3', '756d67d2-ffdc-4cd6-9b0a-3ba2a0ebb03f', '3rd Bristol District', 'Representative, 3rd Bristol District', 1, '20261103MA22993', '177334', 'Lawrence Joseph Quintal', 'Lawrence', 'Quintal', false, false, 'GOP', 6490, 41.71, false, true, 'lost', NULL, NULL, NULL),
  ('c5d8fc0d-5947-4fd2-a753-1188949985f2', '7db3d98e-2efb-4cfb-971d-2a50868da769', '3rd Essex District', 'Representative, 3rd Essex District', 1, '20261103MA23006', '124327', 'Andres Xavier Vargas', 'Andres', 'Vargas', false, true, 'Dem', 0, 0, true, true, 'won', '19b7c45b-57a7-468c-9762-82b926080646'::uuid, 'holder-exact-first-last', 'Andres X. Vargas'),
  ('639adbcf-ddde-4127-8871-ac01d8ef577f', '342018f4-9e48-4404-a7dd-1157de348b00', '3rd Hampden District', 'Representative, 3rd Hampden District', 1, '20261103MA23023', '122360', 'Nicholas A. Boldyga', 'Nicholas', 'Boldyga', false, true, 'GOP', 10325, 53.92, false, true, 'won', '541efc37-b332-4c80-8264-7b655efed5ac'::uuid, 'holder-exact-full-name', 'Nicholas A. Boldyga'),
  ('639adbcf-ddde-4127-8871-ac01d8ef577f', '342018f4-9e48-4404-a7dd-1157de348b00', '3rd Hampden District', 'Representative, 3rd Hampden District', 1, '20261103MA23023', '177141', 'Thomas D. Hendrickson', 'Thomas', 'Hendrickson', false, false, 'Dem', 7008, 36.6, false, true, 'lost', NULL, NULL, NULL),
  ('639adbcf-ddde-4127-8871-ac01d8ef577f', '342018f4-9e48-4404-a7dd-1157de348b00', '3rd Hampden District', 'Representative, 3rd Hampden District', 1, '20261103MA23023', '179360', 'Jason M. Perron', 'Jason', 'Perron', false, false, 'Ind', 1814, 9.47, false, true, 'lost', NULL, NULL, NULL),
  ('8e7f7f5a-5d7a-4914-a56b-d04aad46671f', '66b8fa7d-ef7a-4d7a-84c4-3282c6aeb7c5', '3rd Hampshire District', 'Representative, 3rd Hampshire District', 1, '20261103MA23035', '124134', 'Mindy Domb', 'Mindy', 'Domb', false, true, 'Dem', 0, 0, true, true, 'won', 'ecafa801-15b3-4777-9c38-95f5ded5cbe6'::uuid, 'holder-exact-full-name', 'Mindy Domb'),
  ('396b228c-bd45-470b-be9c-b2af30e14150', '2b65a1e9-bbf9-4387-9697-a9742ed3e231', '3rd Middlesex District', 'Representative, 3rd Middlesex District', 1, '20261103MA23038', '122452', 'Kate Hogan', 'Kate', 'Hogan', false, true, 'Dem', 0, 0, true, true, 'won', 'e96eddbe-4a4a-4499-8102-636f0cfac10e'::uuid, 'holder-exact-full-name', 'Kate Hogan'),
  ('69b6fdea-ef83-49f2-909e-51978ff6eaf9', '539f0bf9-c772-4e27-a22b-898e93eb1e06', '3rd Norfolk District', 'Representative, 3rd Norfolk District', 1, '20261103MA23071', '54530', 'Ronald Mariano', 'Ronald', 'Mariano', false, true, 'Dem', 0, 0, true, true, 'won', '5fdefd59-b543-4221-b6ed-b33532f9bd5f'::uuid, 'holder-exact-full-name', 'Ronald Mariano'),
  ('072366cf-2f69-4e7c-a960-9a845a80efbf', 'c616bbf9-1e39-4174-8caa-533abe1e7f2a', '3rd Plymouth District', 'Representative, 3rd Plymouth District', 1, '20261103MA22181', '123811', 'Joan Meschino', 'Joan', 'Meschino', false, true, 'Dem', 0, 0, true, true, 'won', '502890e3-ad59-4d40-88a4-3cdee03f025e'::uuid, 'holder-exact-full-name', 'Joan Meschino'),
  ('e95a282b-dfdf-4cbe-8903-a090f805116f', '584ae8cb-84ee-40b2-af4d-cafbb51b6931', '3rd Suffolk District', 'Representative, 3rd Suffolk District', 1, '20261103MA23096', '122500', 'Aaron Michlewitz', 'Aaron', 'Michlewitz', false, true, 'Dem', 0, 0, true, true, 'won', '9cf147de-64e0-4116-b461-95933e18c423'::uuid, 'holder-exact-full-name', 'Aaron Michlewitz'),
  ('6d18fff9-3f9a-454f-8ffb-1da38e1ece86', 'af085d61-eedf-497b-8b8e-80e964e3fe4c', '3rd Worcester District', 'Representative, 3rd Worcester District', 1, '20261103MA24801', '124661', 'Michael P. Kushmerek', 'Michael', 'Kushmerek', false, true, 'Dem', 0, 0, true, true, 'won', 'd9b59bbc-90e5-435e-8c46-d8b555f1b932'::uuid, 'holder-exact-full-name', 'Michael P. Kushmerek'),
  ('22244d33-9772-4dd9-9523-b054a5fbdfa0', 'de8be071-053f-401c-beb6-ea4895de5157', '4th Barnstable District', 'Representative, 4th Barnstable District', 1, '20261103MA22987', '165951', 'Hadley Luddy', 'Hadley', 'Luddy', false, true, 'Dem', 0, 0, true, true, 'won', '03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'holder-exact-full-name', 'Hadley Luddy'),
  ('4f212053-ea24-4299-bb9d-c2da78af4700', '9336432d-df5a-4564-87a4-d56c7468c61f', '4th Bristol District', 'Representative, 4th Bristol District', 1, '20261103MA22994', '122333', 'Steven S. Howitt', 'Steven', 'Howitt', false, true, 'GOP', 0, 0, true, true, 'won', '3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1'::uuid, 'holder-exact-full-name', 'Steven S. Howitt'),
  ('f1cd645c-2b8b-4fde-8fe3-622266695bc1', '56dcfca0-a9ab-43cb-b64a-96724deb5ac7', '4th Essex District', 'Representative, 4th Essex District', 1, '20261103MA22094', '125025', 'Estela Reyes', 'Estela', 'Reyes', false, true, 'Dem', 0, 0, true, true, 'won', '8e125ae2-3101-49b1-b228-f172ad9c70d9'::uuid, 'holder-exact-first-last', 'Estela A. Reyes'),
  ('70a7f9f1-6a5a-4a48-94a9-b0b92b4cd689', '9968fadd-9817-4285-b94f-91556bddaf03', '4th Hampden District', 'Representative, 4th Hampden District', 1, '20261103MA23024', '124692', 'Kelly W. Pease', 'Kelly', 'Pease', false, true, 'GOP', 10060, 60.67, false, true, 'won', '296406bb-cc2a-4214-978f-d30333d62939'::uuid, 'holder-exact-full-name', 'Kelly W. Pease'),
  ('70a7f9f1-6a5a-4a48-94a9-b0b92b4cd689', '9968fadd-9817-4285-b94f-91556bddaf03', '4th Hampden District', 'Representative, 4th Hampden District', 1, '20261103MA23024', '177142', 'Colby Walshe Hoffman', 'Colby', 'Hoffman', false, false, 'Dem', 6522, 39.33, false, true, 'lost', NULL, NULL, NULL),
  ('84f5407d-78e7-4f01-a317-ddacdc529985', 'c691ae8a-2393-4621-b1b4-bf30298a2b8f', '4th Middlesex District', 'Representative, 4th Middlesex District', 1, '20261103MA23039', '122454', 'Danielle W. Gregoire', 'Danielle', 'Gregoire', false, true, 'Dem', 0, 0, true, true, 'won', '3d9354a8-e7ee-4381-b91a-a40d0a2e8d3a'::uuid, 'holder-exact-full-name', 'Danielle W. Gregoire'),
  ('a174ef37-8e18-4355-b8d0-f1d567e59a8d', 'da9ed94b-e382-4ee3-a07c-c6451659e763', '4th Norfolk District', 'Representative, 4th Norfolk District', 1, '20261103MA23072', '122477', 'James Michael Murphy', 'James', 'Murphy', false, true, 'Dem', 0, 0, true, true, 'won', '755d18f8-8c99-4d41-93eb-4f154d9bb7a9'::uuid, 'holder-exact-first-last', 'James M. Murphy'),
  ('42d432be-ff5e-46b1-bc0f-185c38ab1360', '3d30ad53-bca7-44c1-a05a-ac02de5094fa', '4th Plymouth District', 'Representative, 4th Plymouth District', 1, '20261103MA23085', '124197', 'Patrick Joseph Kearney', 'Patrick', 'Kearney', false, true, 'Dem', 0, 0, true, true, 'won', '8c2553dd-437e-4614-89ab-f54031bc418e'::uuid, 'holder-exact-first-last', 'Patrick J. Kearney'),
  ('3542d3db-c5b2-4ce6-ad9c-0faaff475d9d', 'cf55423d-1fb3-46d5-866e-8442b82757b4', '4th Suffolk District', 'Representative, 4th Suffolk District', 1, '20261103MA23097', '124206', 'David M. Biele', 'David', 'Biele', false, true, 'Dem', 9802, 78.33, false, true, 'won', 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f'::uuid, 'holder-exact-first-last', 'David Biele'),
  ('3542d3db-c5b2-4ce6-ad9c-0faaff475d9d', 'cf55423d-1fb3-46d5-866e-8442b82757b4', '4th Suffolk District', 'Representative, 4th Suffolk District', 1, '20261103MA23097', '168952', 'Charles J. Delaney', 'Charles', 'Delaney', false, false, 'Ind', 2711, 21.67, false, true, 'lost', NULL, NULL, NULL),
  ('702f0ed1-29fb-491c-8c6b-5a4ee870c2dc', '53614bb6-9765-4440-ae88-ebe8aae6738c', '4th Worcester District', 'Representative, 4th Worcester District', 1, '20261103MA23116', '123653', 'Natalie Marie Higgins', 'Natalie', 'Higgins', false, true, 'Dem', 8075, 61.4, false, true, 'won', 'c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'holder-exact-first-last', 'Natalie Higgins'),
  ('702f0ed1-29fb-491c-8c6b-5a4ee870c2dc', '53614bb6-9765-4440-ae88-ebe8aae6738c', '4th Worcester District', 'Representative, 4th Worcester District', 1, '20261103MA23116', '177350', 'Josh William Bowdridge', 'Josh', 'Bowdridge', false, false, 'GOP', 5077, 38.6, false, true, 'lost', NULL, NULL, NULL),
  ('38112931-22f3-4b33-a018-f7fb463e9de3', '637922fd-f25e-4dd0-abe0-19c224ec095a', '5th Barnstable District', 'Representative, 5th Barnstable District', 1, '20261103MA23874', '124672', 'Steven G. Xiarhos', 'Steven', 'Xiarhos', false, true, 'GOP', 0, 0, true, true, 'won', '892670a6-f15f-4014-86a8-434090c2a514'::uuid, 'holder-exact-full-name', 'Steven G. Xiarhos'),
  ('b8d1a093-137e-49b9-9399-f03b3076ab3e', '1cd38a70-4ec0-4619-9d4c-20358a5f8111', '5th Bristol District', 'Representative, 5th Bristol District', 1, '20261103MA22995', '125389', 'Justin E. Thurber', 'Justin', 'Thurber', false, true, 'GOP', 10048, 54.73, false, true, 'won', 'a485b386-65a5-4c6c-aaa1-a441facd45fc'::uuid, 'holder-exact-first-last', 'Justin Thurber'),
  ('b8d1a093-137e-49b9-9399-f03b3076ab3e', '1cd38a70-4ec0-4619-9d4c-20358a5f8111', '5th Bristol District', 'Representative, 5th Bristol District', 1, '20261103MA22995', '177128', 'Jamison D. Souza', 'Jamison', 'Souza', false, false, 'Dem', 8312, 45.27, false, true, 'lost', NULL, NULL, NULL),
  ('7ce2f5e9-61c0-4064-b4f7-50dc5e4c3b3a', 'd24bc7df-1159-4c3f-bfc2-8e6c5b455fd9', '5th Essex District', 'Representative, 5th Essex District', 1, '20261103MA23007', '170420', 'Andrew Francis Robert Tarr', 'Andrew', 'Tarr', false, true, 'Dem', 14347, 64.24, false, true, 'won', '31aca73c-2006-49d2-901c-89ee2a13acb5'::uuid, 'holder-exact-first-last', 'Andrew F. Tarr'),
  ('7ce2f5e9-61c0-4064-b4f7-50dc5e4c3b3a', 'd24bc7df-1159-4c3f-bfc2-8e6c5b455fd9', '5th Essex District', 'Representative, 5th Essex District', 1, '20261103MA23007', '170421', 'Christina Delisio', 'Christina', 'Delisio', false, false, 'GOP', 7071, 31.66, false, true, 'lost', NULL, NULL, NULL),
  ('7ce2f5e9-61c0-4064-b4f7-50dc5e4c3b3a', 'd24bc7df-1159-4c3f-bfc2-8e6c5b455fd9', '5th Essex District', 'Representative, 5th Essex District', 1, '20261103MA23007', '171353', 'Gil Frieden', 'Gil', 'Frieden', false, false, 'Oth', 917, 4.11, false, true, 'lost', NULL, NULL, NULL),
  ('a09771fc-328a-4683-840e-c2b300646881', '5854a77d-2b29-42fc-b184-6724de38c49f', '5th Hampden District', 'Representative, 5th Hampden District', 1, '20261103MA23025', '124574', 'Patricia A. Duffy', 'Patricia', 'Duffy', false, true, 'Dem', 8360, 78.79, false, true, 'won', '4a0609a0-7073-4de1-9bf8-b3ecaebc9638'::uuid, 'holder-exact-full-name', 'Patricia A. Duffy'),
  ('a09771fc-328a-4683-840e-c2b300646881', '5854a77d-2b29-42fc-b184-6724de38c49f', '5th Hampden District', 'Representative, 5th Hampden District', 1, '20261103MA23025', '179361', 'Jose Ramon Candelario Gonzalez', 'Jose', 'Candelario Gonzalez', false, false, 'Ind', 2250, 21.21, false, true, 'lost', NULL, NULL, NULL),
  ('6edf79c8-19f4-4ae5-b217-228750cdbfdd', '454d986f-dc3f-4077-9a87-05cc6a208ed1', '5th Middlesex District', 'Representative, 5th Middlesex District', 1, '20261103MA22130', '122455', 'David Paul Linsky', 'David', 'Linsky', false, true, 'Dem', 14817, 77.98, false, true, 'won', 'fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid, 'holder-exact-first-last', 'David P. Linsky'),
  ('6edf79c8-19f4-4ae5-b217-228750cdbfdd', '454d986f-dc3f-4077-9a87-05cc6a208ed1', '5th Middlesex District', 'Representative, 5th Middlesex District', 1, '20261103MA22130', '177343', 'Luisa A. Cestari', 'Luisa', 'Cestari', false, false, 'GOP', 4184, 22.02, false, true, 'lost', NULL, NULL, NULL),
  ('8773413f-6c0e-46ee-9d3e-4e2f96e3b10c', 'e53dd816-f960-417c-b68f-24012901d723', '5th Norfolk District', 'Representative, 5th Norfolk District', 1, '20261103MA23073', '122192', 'Mark J. Cusack', 'Mark', 'Cusack', false, true, 'Dem', 10676, 69.42, false, true, 'won', '99206e70-8173-4d6c-803c-1ae2d1109e30'::uuid, 'holder-exact-full-name', 'Mark J. Cusack'),
  ('8773413f-6c0e-46ee-9d3e-4e2f96e3b10c', 'e53dd816-f960-417c-b68f-24012901d723', '5th Norfolk District', 'Representative, 5th Norfolk District', 1, '20261103MA23073', '179362', 'Stephen M. Foley', 'Stephen', 'Foley', false, false, 'Unr', 4702, 30.58, false, true, 'lost', NULL, NULL, NULL),
  ('d83bf652-9a7b-4a2a-9c46-f663292b3844', '5ab074a8-d9da-4026-b0e8-bf3b079ae44d', '5th Plymouth District', 'Representative, 5th Plymouth District', 1, '20261103MA23086', '123275', 'David F. DeCoste', 'David', 'DeCoste', false, true, 'GOP', 11932, 55.11, false, true, 'won', 'a743a9a0-711c-40cf-b6e2-0ce2b587949a'::uuid, 'holder-exact-full-name', 'David F. DeCoste'),
  ('d83bf652-9a7b-4a2a-9c46-f663292b3844', '5ab074a8-d9da-4026-b0e8-bf3b079ae44d', '5th Plymouth District', 'Representative, 5th Plymouth District', 1, '20261103MA23086', '177267', 'Lori Childs', 'Lori', 'Childs', false, false, 'Dem', 9720, 44.89, false, true, 'lost', NULL, NULL, NULL),
  ('25a5f274-0248-475a-b7c9-6d1120bd4bab', 'f589fbfe-f214-4dab-adaa-16df96382ec0', '5th Suffolk District', 'Representative, 5th Suffolk District', 1, '20261103MA23098', '125156', 'Christopher J. Worrell', 'Christopher', 'Worrell', false, true, 'Dem', 0, 0, true, true, 'won', 'bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'holder-exact-full-name', 'Christopher J. Worrell'),
  ('12394986-9430-4cdb-ac18-2fceb418bcba', '766491d7-9104-433d-9303-3393aed16a7b', '5th Worcester District', 'Representative, 5th Worcester District', 1, '20261103MA23117', '123323', 'Donald Roger Berthiaume Jr.', 'Donald', 'Berthiaume', false, true, 'GOP', 0, 0, true, true, 'won', '329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'holder-exact-first-last', 'Donald R. Berthiaume'),
  ('d224bf98-7f52-4ca8-a88f-1cdacc467cf0', '668b5b21-e097-4775-bc1d-756dfcbd0def', '6th Bristol District', 'Representative, 6th Bristol District', 1, '20261103MA22996', '123153', 'Carole A. Fiola', 'Carole', 'Fiola', false, true, 'Dem', 6833, 59.83, false, true, 'won', '913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'holder-exact-full-name', 'Carole A. Fiola'),
  ('d224bf98-7f52-4ca8-a88f-1cdacc467cf0', '668b5b21-e097-4775-bc1d-756dfcbd0def', '6th Bristol District', 'Representative, 6th Bristol District', 1, '20261103MA22996', '177335', 'Robert G. Anctil', 'Robert', 'Anctil', false, false, 'GOP', 4588, 40.17, false, true, 'lost', NULL, NULL, NULL),
  ('6d0de6a6-ff35-4f83-88e8-7253181ab457', '302816c1-274f-4928-84ac-6f0cb30e3549', '6th Essex District', 'Representative, 6th Essex District', 1, '20261103MA23008', '177133', 'Hannah Louise Bowen', 'Hannah', 'Bowen', false, true, 'Dem', 0, 0, true, true, 'won', 'b651cf67-37b4-4cbf-afcd-088010247788'::uuid, 'holder-exact-first-last', 'Hannah L. Bowen'),
  ('cab14bec-ad44-4916-b998-4fe0cafba400', '80293edf-bb47-4a0b-9c91-db7cafacd0f7', '6th Hampden District', 'Representative, 6th Hampden District', 1, '20261103MA22115', '122175', 'Michael James Finn', 'Michael', 'Finn', false, true, 'Dem', 0, 0, true, true, 'won', '949b1930-0574-44f5-9389-efc75c654139'::uuid, 'holder-exact-first-last', 'Michael J. Finn'),
  ('2789814a-6e72-492e-9017-8b4a900638c6', '36165032-31d8-43d4-abcc-13592f5a7e9c', '6th Middlesex District', 'Representative, 6th Middlesex District', 1, '20261103MA23040', '125087', 'Priscila S. Sousa', 'Priscila', 'Sousa', false, true, 'Dem', 0, 0, true, true, 'won', '2ada2d01-a77a-44f6-a569-916d9639fbdc'::uuid, 'holder-exact-full-name', 'Priscila S. Sousa'),
  ('c538fcd0-c3f1-431c-b972-b0368c997933', 'b631df47-e792-4ee1-92c3-6b4b6b336e9b', '6th Norfolk District', 'Representative, 6th Norfolk District', 1, '20261103MA23074', '177213', 'Lisa R. Lopez', 'Lisa', 'Lopez', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('43043ecf-8b5b-4f16-b70b-d7a3ee2c3e33', 'd4a3db82-2148-4c74-aceb-49004e55a8df', '6th Plymouth District', 'Representative, 6th Plymouth District', 1, '20261103MA23087', '125249', 'Kenneth Peter Sweezey', 'Kenneth', 'Sweezey', false, true, 'GOP', 11094, 54.71, false, true, 'won', '8512ef88-a285-4c6f-89d3-41fb4f8cfd48'::uuid, 'holder-exact-first-last', 'Kenneth P. Sweezey'),
  ('43043ecf-8b5b-4f16-b70b-d7a3ee2c3e33', 'd4a3db82-2148-4c74-aceb-49004e55a8df', '6th Plymouth District', 'Representative, 6th Plymouth District', 1, '20261103MA23087', '177269', 'Jessica Marie Rushing', 'Jessica', 'Rushing', false, false, 'Dem', 9182, 45.29, false, true, 'lost', NULL, NULL, NULL),
  ('4acbbd70-6b3f-4c9a-965b-b8675da6d55a', '0abba66e-061c-4076-accc-a2a31bfcf465', '6th Suffolk District', 'Representative, 6th Suffolk District', 1, '20261103MA23099', '122218', 'Russell Earl Holmes', 'Russell', 'Holmes', false, true, 'Dem', 0, 0, true, true, 'won', 'e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid, 'holder-exact-first-last', 'Russell E. Holmes'),
  ('2b457544-3c86-42b3-9f12-9821205c54f9', '6c780000-a678-4942-92a1-e4a630d0a52a', '6th Worcester District', 'Representative, 6th Worcester District', 1, '20261103MA22216', '166156', 'John J. Marsi Jr.', 'John', 'Marsi', false, true, 'GOP', 8536, 58.32, false, true, 'won', '9dd7276b-1c24-466c-a530-d2297607a784'::uuid, 'holder-exact-first-last', 'John J. Marsi'),
  ('2b457544-3c86-42b3-9f12-9821205c54f9', '6c780000-a678-4942-92a1-e4a630d0a52a', '6th Worcester District', 'Representative, 6th Worcester District', 1, '20261103MA22216', '177329', 'Jeanne Renaud Costello', 'Jeanne', 'Costello', false, false, 'Dem', 6101, 41.68, false, true, 'lost', NULL, NULL, NULL),
  ('7f08cb76-4a25-4453-a983-2107b0a02119', 'c40c9f80-11f7-4407-9aa8-744cc61b4299', '7th Bristol District', 'Representative, 7th Bristol District', 1, '20261103MA22997', '63079', 'Alan Silvia', 'Alan', 'Silvia', false, true, 'Dem', 4623, 62.86, false, true, 'won', 'a646d95b-7341-4181-a25b-87b5abcf0a6c'::uuid, 'holder-exact-full-name', 'Alan Silvia'),
  ('7f08cb76-4a25-4453-a983-2107b0a02119', 'c40c9f80-11f7-4407-9aa8-744cc61b4299', '7th Bristol District', 'Representative, 7th Bristol District', 1, '20261103MA22997', '177336', 'Talos D. Farris', 'Talos', 'Farris', false, false, 'GOP', 2732, 37.14, false, true, 'lost', NULL, NULL, NULL),
  ('40fa70b5-6a73-4188-82bc-abe49b401c7d', '56f8a5de-77c3-4d2a-9049-d7cb979acc52', '7th Essex District', 'Representative, 7th Essex District', 1, '20261103MA23009', '125032', 'Manny Cruz', 'Manny', 'Cruz', false, true, 'Dem', 0, 0, true, true, 'won', '02eedd50-b5a5-48dd-b1a4-9b5220bf7e8e'::uuid, 'holder-exact-full-name', 'Manny Cruz'),
  ('f06f0d9b-8861-47b7-8975-a2a3794db91f', 'bada2ba7-3d1f-486f-af2e-2d9e759545bc', '7th Hampden District', 'Representative, 7th Hampden District', 1, '20261103MA23026', '177144', 'Aaron L. Saunders', 'Aaron', 'Saunders', false, true, 'Dem', 0, 0, true, true, 'won', 'e2daa3aa-02b6-4a4d-859b-fb75f674625b'::uuid, 'holder-exact-full-name', 'Aaron L. Saunders'),
  ('8ebaca4a-0086-4d79-827b-b99a6b0538bf', 'f857551b-637f-42e2-9bfc-d61be7e84741', '7th Middlesex District', 'Representative, 7th Middlesex District', 1, '20261103MA23041', '123580', 'Jack Patrick Lewis', 'Jack', 'Lewis', false, true, 'Dem', 0, 0, true, true, 'won', '04a9edee-5d51-49f3-a2c9-585e2231bd08'::uuid, 'holder-exact-first-last', 'Jack P. Lewis'),
  ('ce983f55-4c10-4a2d-90c7-42975378676f', 'ca056ab7-d327-4aea-a295-a42756b9b039', '7th Norfolk District', 'Representative, 7th Norfolk District', 1, '20261103MA23075', '166040', 'Richard Gerard Wells Jr.', 'Richard', 'Wells', false, true, 'Dem', 0, 0, true, true, 'won', 'a3131d21-f3ad-4483-ac6d-13c9c7ecdd74'::uuid, 'holder-exact-first-last', 'Richard G. Wells'),
  ('631ba90f-ab68-4964-8d8b-6c38137f67d2', '83d57ac6-84de-4b6e-ba09-f326a7d5df4c', '7th Plymouth District', 'Representative, 7th Plymouth District', 1, '20261103MA23088', '124293', 'Alyson M. Sullivan-Almeida', 'Alyson', 'Sullivan-Almeida', false, true, 'GOP', 10689, 58.61, false, true, 'won', '7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2'::uuid, 'holder-exact-first-last', 'Alyson Sullivan-Almeida'),
  ('631ba90f-ab68-4964-8d8b-6c38137f67d2', '83d57ac6-84de-4b6e-ba09-f326a7d5df4c', '7th Plymouth District', 'Representative, 7th Plymouth District', 1, '20261103MA23088', '177271', 'Rosemary Aahanna-Hill', 'Rosemary', 'Aahanna-Hill', false, false, 'Dem', 7547, 41.39, false, true, 'lost', NULL, NULL, NULL),
  ('db11c013-145b-4d2b-b748-759da1ec65a0', '9af4875a-30da-46a4-b2a6-8ed5c9e5f472', '7th Suffolk District', 'Representative, 7th Suffolk District', 1, '20261103MA23100', '123644', 'Chynah T. Tyler', 'Chynah', 'Tyler', false, true, 'Dem', 0, 0, true, true, 'won', 'fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid, 'holder-exact-first-last', 'Chynah Tyler'),
  ('6ecc0aaa-3126-48df-b447-278171b99d5e', 'f461b346-317d-447a-a3ce-7e103441c2ed', '7th Worcester District', 'Representative, 7th Worcester District', 1, '20261103MA23118', '54579', 'Paul K. Frost', 'Paul', 'Frost', false, true, 'GOP', 9615, 49.76, false, true, 'won', '799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'holder-exact-full-name', 'Paul K. Frost'),
  ('6ecc0aaa-3126-48df-b447-278171b99d5e', 'f461b346-317d-447a-a3ce-7e103441c2ed', '7th Worcester District', 'Representative, 7th Worcester District', 1, '20261103MA23118', '177330', 'Nicholas Lazzaro', 'Nicholas', 'Lazzaro', false, false, 'Dem', 8457, 43.76, false, true, 'lost', NULL, NULL, NULL),
  ('6ecc0aaa-3126-48df-b447-278171b99d5e', 'f461b346-317d-447a-a3ce-7e103441c2ed', '7th Worcester District', 'Representative, 7th Worcester District', 1, '20261103MA23118', '123658', 'Terry Burke Dotson', 'Terry', 'Dotson', false, false, 'Ind', 1252, 6.48, false, true, 'lost', NULL, NULL, NULL),
  ('7493b8d7-b426-4a63-97c2-f9a00d4a1a37', 'cc6a6617-56b2-4a21-814c-f8b297756fb2', '8th Bristol District', 'Representative, 8th Bristol District', 1, '20261103MA22998', '165958', 'Steven J. Ouellette', 'Steven', 'Ouellette', false, true, 'Dem', 8547, 48.69, false, true, 'lost', 'a4e6e14a-46f7-4574-94c6-5b7edd484d91'::uuid, 'holder-exact-full-name', 'Steven J. Ouellette'),
  ('7493b8d7-b426-4a63-97c2-f9a00d4a1a37', 'cc6a6617-56b2-4a21-814c-f8b297756fb2', '8th Bristol District', 'Representative, 8th Bristol District', 1, '20261103MA22998', '168197', 'Jesse W. St. Gelais', 'Jesse', 'St. Gelais', false, false, 'GOP', 9006, 51.31, false, true, 'won', NULL, NULL, NULL),
  ('91af7de7-b0cf-4b49-8ee7-eab3cdaaaff2', '6b66f837-d2a7-4b49-892e-a84c171e1612', '8th Essex District', 'Representative, 8th Essex District', 1, '20261103MA23010', '125036', 'Jennifer WB Armini', 'Jennifer', 'Armini', false, true, 'Dem', 0, 0, true, true, 'won', '6148f954-b8cc-4204-96ca-34f2afc1d24a'::uuid, 'holder-exact-first-last', 'Jennifer Balinsky Armini'),
  ('3227ab14-a0dc-4f63-9aa8-e5bd4a355ba4', 'fe18d9de-dde8-4f40-88a9-470e5b92e641', '8th Hampden District', 'Representative, 8th Hampden District', 1, '20261103MA23027', '125067', 'Shirley Arriaga', 'Shirley', 'Arriaga', false, true, 'Dem', 0, 0, true, true, 'won', '8995a410-276d-4a84-87f2-b097c1535f90'::uuid, 'holder-exact-first-last', 'Shirley A. Arriaga'),
  ('dee9cdb9-7334-4660-980a-99fa3ca96959', 'c581841a-0966-4473-89d9-a539b52d7cf5', '8th Middlesex District', 'Representative, 8th Middlesex District', 1, '20261103MA23042', '125091', 'James C. Arena-DeRosa', 'James', 'Arena-DeRosa', false, true, 'Dem', 0, 0, true, true, 'won', 'ea8ed274-32d6-499d-a787-7ad1f0624280'::uuid, 'holder-exact-first-last', 'James Arena-DeRosa'),
  ('6e1abb0f-2574-44e7-9420-4b11b919522d', '234072a7-3103-4631-890f-cd3ff26823b0', '8th Norfolk District', 'Representative, 8th Norfolk District', 1, '20261103MA23076', '124634', 'Ted Philips', 'Ted', 'Philips', false, true, 'Dem', 0, 0, true, true, 'won', '73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'holder-surname-plus-roster', 'Edward R. Philips'),
  ('fe0f7b69-ba6f-46c8-8678-607e719ea703', 'e3f55862-938c-4ec7-8660-cf7104708204', '8th Plymouth District', 'Representative, 8th Plymouth District', 1, '20261103MA23089', '166047', 'Dennis C. Gallagher', 'Dennis', 'Gallagher', false, true, 'Dem', 9332, 54.78, false, true, 'won', '17035eb6-e7d3-4372-9b96-0741adb57468'::uuid, 'holder-exact-full-name', 'Dennis C. Gallagher'),
  ('fe0f7b69-ba6f-46c8-8678-607e719ea703', 'e3f55862-938c-4ec7-8660-cf7104708204', '8th Plymouth District', 'Representative, 8th Plymouth District', 1, '20261103MA23089', '177348', 'John Edward Norris', 'John', 'Norris', false, false, 'GOP', 7703, 45.22, false, true, 'lost', NULL, NULL, NULL),
  ('eb8de04a-f380-4a07-9c2a-a717ec11a789', 'a878cf06-cf7a-4399-9e04-b4ff2e4f0711', '8th Suffolk District', 'Representative, 8th Suffolk District', 1, '20261103MA23101', '123287', 'Jay D. Livingstone', 'Jay', 'Livingstone', false, true, 'Dem', 0, 0, true, true, 'won', '852e4a21-5750-4ac8-ba06-0376c5a31685'::uuid, 'holder-exact-first-last', 'Jay Livingstone'),
  ('ca9b8728-4609-4f4d-9a58-38f07bc6a551', '0628edb7-3d36-4058-87a9-d27fa4795533', '8th Worcester District', 'Representative, 8th Worcester District', 1, '20261103MA23119', '123445', 'Michael J. Soter', 'Michael', 'Soter', false, true, 'GOP', 0, 0, true, true, 'won', '51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'holder-exact-full-name', 'Michael J. Soter'),
  ('0d894bf7-ab7c-49f6-bed3-43d32a2d1419', '42f065a2-72d4-457a-8a95-dd154bef4af5', '9th Bristol District', 'Representative, 9th Bristol District', 1, '20261103MA22999', '177130', 'Edward M. Pacheco', 'Edward', 'Pacheco', false, false, 'Dem', 9558, 56.09, false, true, 'won', NULL, NULL, NULL),
  ('0d894bf7-ab7c-49f6-bed3-43d32a2d1419', '42f065a2-72d4-457a-8a95-dd154bef4af5', '9th Bristol District', 'Representative, 9th Bristol District', 1, '20261103MA22999', '177338', 'Chester M. Tam', 'Chester', 'Tam', false, false, 'GOP', 7483, 43.91, false, true, 'lost', NULL, NULL, NULL),
  ('fd585f8b-6cf9-45e8-9c31-d0fb7aef81ed', 'eb9f8964-d6cc-4a41-bd37-ad882882ba2a', '9th Essex District', 'Representative, 9th Essex District', 1, '20261103MA23011', '122344', 'Donald H. Wong', 'Donald', 'Wong', false, true, 'GOP', 10166, 55.04, false, true, 'won', '44ca0b25-e4b9-4409-8407-f5119568be3e'::uuid, 'holder-exact-full-name', 'Donald H. Wong'),
  ('fd585f8b-6cf9-45e8-9c31-d0fb7aef81ed', 'eb9f8964-d6cc-4a41-bd37-ad882882ba2a', '9th Essex District', 'Representative, 9th Essex District', 1, '20261103MA23011', '177134', 'Peter Meaney', 'Peter', 'Meaney', false, false, 'Dem', 8305, 44.96, false, true, 'lost', NULL, NULL, NULL),
  ('6d445a94-4147-4a0c-9f83-7f6cf437dd17', 'eedd160e-d7dd-48a8-a0be-7a5788c61fb7', '9th Hampden District', 'Representative, 9th Hampden District', 1, '20261103MA23028', '124582', 'Orlando Ramos', 'Orlando', 'Ramos', false, true, 'Dem', 0, 0, true, true, 'won', 'ef8a23a0-7f93-425c-a773-dcec9eb96dfb'::uuid, 'holder-exact-full-name', 'Orlando Ramos'),
  ('9f230dbe-9d34-4e20-8cf9-d765d9908e70', 'bcd9dcb6-0f03-4dac-b23e-d3c39a4b63c9', '9th Middlesex District', 'Representative, 9th Middlesex District', 1, '20261103MA22134', '122570', 'Thomas M. Stanley', 'Thomas', 'Stanley', false, true, 'Dem', 0, 0, true, true, 'won', 'c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid, 'holder-exact-full-name', 'Thomas M. Stanley'),
  ('5f854446-d196-4009-ac18-894b5861af98', '888ecc56-4be1-4e13-8fbc-cf7f279c844b', '9th Norfolk District', 'Representative, 9th Norfolk District', 1, '20261103MA23077', '125245', 'Marcus S. Vaughn', 'Marcus', 'Vaughn', false, true, 'GOP', 11252, 52.35, false, true, 'won', 'c9a23774-469d-4c40-b316-7fbd46dab7d9'::uuid, 'holder-exact-full-name', 'Marcus S. Vaughn'),
  ('5f854446-d196-4009-ac18-894b5861af98', '888ecc56-4be1-4e13-8fbc-cf7f279c844b', '9th Norfolk District', 'Representative, 9th Norfolk District', 1, '20261103MA23077', '177219', 'Thomas R. Melville', 'Thomas', 'Melville', false, false, 'Dem', 10241, 47.65, false, true, 'lost', NULL, NULL, NULL),
  ('3d6c64b2-254d-4966-9be6-c0741ff0cb61', '5a5406b1-2072-44ec-b075-561c2a74eeb7', '9th Plymouth District', 'Representative, 9th Plymouth District', 1, '20261103MA23090', '166048', 'Bridget Marie Plouffe', 'Bridget', 'Plouffe', false, true, 'Dem', 11031, 65.45, false, true, 'won', '63df70bd-91d8-4576-8136-d2128ea5e9b9'::uuid, 'holder-exact-first-last', 'Bridget M. Plouffe'),
  ('3d6c64b2-254d-4966-9be6-c0741ff0cb61', '5a5406b1-2072-44ec-b075-561c2a74eeb7', '9th Plymouth District', 'Representative, 9th Plymouth District', 1, '20261103MA23090', '125251', 'Lawrence Peter Novak', 'Lawrence', 'Novak', false, false, 'GOP', 5823, 34.55, false, true, 'lost', NULL, NULL, NULL),
  ('76ece148-9ea3-4c1d-a39c-08d220c41b4d', '10f48196-836a-4de7-b12e-4af80ae7055e', '9th Suffolk District', 'Representative, 9th Suffolk District', 1, '20261103MA23102', '166052', 'John Francis Moran', 'John', 'Moran', false, true, 'Dem', 0, 0, true, true, 'won', '7cc9694b-3bca-44ec-ab75-762c1f6d5136'::uuid, 'holder-exact-first-last', 'John F. Moran'),
  ('8bc9a515-7cd2-40e1-b5b9-675d0ad9ca68', 'd9d47213-c923-40ce-af8e-a79ac13340e7', '9th Worcester District', 'Representative, 9th Worcester District', 1, '20261103MA23120', '123329', 'David Kent Muradian Jr.', 'David', 'Muradian', false, true, 'GOP', 0, 0, true, true, 'won', '891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'holder-exact-first-last', 'David K. Muradian'),
  ('1233970c-1286-4117-acd1-fd0068c82196', '556c918b-af76-42e6-943b-a40bbf4e7956', 'Barnstable-Dukes-Nantucket District', 'Representative, Barnstable-Dukes-Nantucket District', 1, '20261103MA22988', '165950', 'Thomas W. Moakley', 'Thomas', 'Moakley', false, true, 'Dem', 0, 0, true, true, 'won', '35cf0880-be86-45bb-97e9-4ef2097feba1'::uuid, 'holder-exact-full-name', 'Thomas W. Moakley'),
  ('4ab0b822-780a-415c-8ccb-8f31841ac972', 'c847c096-905f-434c-979e-9bd9bdf382a0', 'Berkshire-Hampden-Franklin-Hampshire District', 'Senator, Berkshire-Hampden-Franklin-Hampshire District', 1, '20261103MA23867', '63072', 'Paul W. Mark', 'Paul', 'Mark', false, true, 'Dem', 0, 0, true, true, 'won', 'f530be83-6f1b-4b04-a8c4-3a83dc35099f'::uuid, 'holder-exact-full-name', 'Paul W. Mark'),
  ('295eb41d-7f59-44b2-9477-a4c12869bb77', '2418e804-1728-4dcf-bfe9-be16ab5e03f2', 'Bristol and Norfolk District', 'Senator, Bristol and Norfolk District', 1, '20261103MA23868', '123991', 'Paul Richard Feeney', 'Paul', 'Feeney', false, true, 'Dem', 0, 0, true, true, 'won', 'c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'holder-exact-first-last', 'Paul R. Feeney'),
  ('71116bf8-408a-4569-9115-9959ad958da8', '5945ee11-9d78-40b5-80dd-a4d70c9b4a15', 'Cape and Islands District', 'Senator, Cape and Islands District', 1, '20261103MA22032', '123483', 'Julian Cyr', 'Julian', 'Cyr', false, true, 'Dem', 0, 0, true, true, 'won', 'bd451748-111f-461d-9752-95e7c243769e'::uuid, 'holder-exact-first-last', 'Julian A. Cyr'),
  ('6d107e0e-24c3-4f67-9fbf-684c36910afc', '58c80f50-6a02-43d5-a17d-f467b351af24', 'Fifth Middlesex District', 'Senator, Fifth Middlesex District', 1, '20261103MA24549', '124485', 'Kate Lipper-Garabedian', 'Kate', 'Lipper-Garabedian', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('66a44d0e-7f4d-4ed6-b150-c875511e8156', '2254f610-41b7-4525-b5c3-d4e82d5e329a', 'First Bristol and Plymouth District', 'Senator, First Bristol and Plymouth District', 1, '20261103MA23869', '54449', 'Michael J. Rodrigues', 'Michael', 'Rodrigues', false, true, 'Dem', 32898, 57.22, false, true, 'won', 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'holder-exact-full-name', 'Michael J. Rodrigues'),
  ('66a44d0e-7f4d-4ed6-b150-c875511e8156', '2254f610-41b7-4525-b5c3-d4e82d5e329a', 'First Bristol and Plymouth District', 'Senator, First Bristol and Plymouth District', 1, '20261103MA23869', '176885', 'Gabriel Boomer Amaral', 'Gabriel', 'Amaral', false, false, 'GOP', 24594, 42.78, false, true, 'lost', NULL, NULL, NULL),
  ('5593f238-424f-4708-ba4e-5adcfec015cb', 'b95e9919-a087-4b12-9674-e79b20578995', 'First Essex and Middlesex District', 'Senator, First Essex and Middlesex District', 1, '20261103MA23343', '54597', 'Bruce E. Tarr', 'Bruce', 'Tarr', false, true, 'GOP', 0, 0, true, true, 'won', 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'holder-exact-full-name', 'Bruce E. Tarr'),
  ('e7091c27-3632-4cd3-8898-f840ec4309bf', '8ddede12-de8f-4d67-9828-15c3be1ad92b', 'First Essex District', 'Senator, First Essex District', 1, '20261103MA22964', '123107', 'Pavel M. Payano', 'Pavel', 'Payano', false, true, 'Dem', 0, 0, true, true, 'won', '756f9e6b-5286-4a9e-9d05-f6341830bd12'::uuid, 'holder-exact-full-name', 'Pavel M. Payano'),
  ('cb4b7080-624c-48d7-bf3e-da09a1675637', 'b902c5f7-9ff9-4179-9ee5-ca18a7f4d2f7', 'First Middlesex District', 'Senator, First Middlesex District', 1, '20261103MA23174', '124598', 'Vanna Howard', 'Vanna', 'Howard', false, true, 'Dem', 27422, 58.43, false, true, 'won', 'c947719a-cd1a-497a-8fc9-d9c4d434b18f'::uuid, 'holder-exact-full-name', 'Vanna Howard'),
  ('cb4b7080-624c-48d7-bf3e-da09a1675637', 'b902c5f7-9ff9-4179-9ee5-ca18a7f4d2f7', 'First Middlesex District', 'Senator, First Middlesex District', 1, '20261103MA23174', '170422', 'Sam Meas', 'Sam', 'Meas', false, false, 'GOP', 12435, 26.5, false, true, 'lost', NULL, NULL, NULL),
  ('cb4b7080-624c-48d7-bf3e-da09a1675637', 'b902c5f7-9ff9-4179-9ee5-ca18a7f4d2f7', 'First Middlesex District', 'Senator, First Middlesex District', 1, '20261103MA23174', '170601', 'Joe Espinola', 'Joe', 'Espinola', false, false, 'Ind', 7072, 15.07, false, true, 'lost', NULL, NULL, NULL),
  ('ed220fd1-6a95-43ba-a1c9-fa8bbf63905e', 'a08cf4b2-38c3-4c18-acfe-d0780760f8e9', 'First Plymouth and Norfolk District', 'Senator, First Plymouth and Norfolk District', 1, '20261103MA23168', '176891', 'Patrick M. O''Connor', 'Patrick', 'O''Connor', false, true, 'GOP', 0, 0, true, true, 'won', 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'holder-exact-full-name', 'Patrick M. O''Connor'),
  ('81d28ab5-dcce-4692-ac5b-8872f6673351', 'd35965d8-081f-40f6-b9b6-88dba6ac8af7', 'First Suffolk District', 'Senator, First Suffolk District', 1, '20261103MA22977', '122208', 'Nicholas P. Collins', 'Nicholas', 'Collins', false, true, 'Dem', 0, 0, true, true, 'won', '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'holder-surname-plus-roster', 'Nick Collins'),
  ('cd5e8a7c-db96-4d01-9515-f84a10cfcac5', '0f99e2a4-c193-4f99-bf4c-57ec624288fb', 'First Worcester District', 'Senator, First Worcester District', 1, '20261103MA23171', '124958', 'Robyn Kennedy', 'Robyn', 'Kennedy', false, true, 'Dem', 0, 0, true, true, 'won', 'e47f2082-6fcb-4961-9df5-c5fb94004b59'::uuid, 'holder-exact-first-last', 'Robyn K. Kennedy'),
  ('3d3f3356-3187-451a-aaa7-7f6e7b514a02', '73f6816f-285c-4191-92a8-061ef6b76cf4', 'Fourth Middlesex District', 'Senator, Fourth Middlesex District', 1, '20261103MA22968', '124011', 'Cindy F. Friedman', 'Cindy', 'Friedman', false, true, 'Dem', 0, 0, true, true, 'won', '248f76d7-e76a-49e5-88b7-dc43a3131329'::uuid, 'holder-surname-plus-roster', 'Cynthia F. Friedman'),
  ('58a0d781-7e9d-4658-8e39-8e4f1993aea1', 'ed5b870e-0f58-46b2-92d0-7ee57013b9d4', 'Hampden and Hampshire District', 'Senator, Hampden and Hampshire District', 1, '20261103MA22041', '123197', 'John Christopher Velis', 'John', 'Velis', false, true, 'Dem', 0, 0, true, true, 'won', '973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'holder-exact-first-last', 'John C. Velis'),
  ('2d9674c1-ecc9-44fe-8616-b789c2e5bf6c', 'dc0970e5-651a-4327-b0ae-0961a1bcdab7', 'Hampden District', 'Senator, Hampden District', 1, '20261103MA22967', '124513', 'Adam Gomez', 'Adam', 'Gomez', false, true, 'Dem', 0, 0, true, true, 'won', '78ae3786-e71e-4dc4-8b84-0ab28b555632'::uuid, 'holder-exact-full-name', 'Adam Gómez'),
  ('81f69e70-6a22-4fb3-8b31-68c31f2a9975', 'd2f84b2d-4b52-4ed7-9716-9a82c951e589', 'Hampden-Hampshire-Worcester District', 'Senator, Hampden-Hampshire-Worcester District', 1, '20261103MA23176', '124577', 'Jacob R. Oliveira', 'Jacob', 'Oliveira', false, true, 'Dem', 0, 0, true, true, 'won', 'ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5'::uuid, 'holder-exact-full-name', 'Jacob R. Oliveira'),
  ('d1a795ca-4579-490f-921f-ac8559522549', 'af5db577-5613-4678-ace2-7da685ba7b14', 'Hampshire-Franklin-Worcester District', 'Senator, Hampshire-Franklin-Worcester District', 1, '20261103MA23166', '124334', 'Joanne M. Comerford', 'Joanne', 'Comerford', false, true, 'Dem', 0, 0, true, true, 'won', '961506eb-3f00-4358-a9a3-1730e7004474'::uuid, 'holder-exact-full-name', 'Joanne M. Comerford'),
  ('d9d6a858-6ea1-4601-9a2a-a4c91a24b44a', '17577265-62e7-44c8-b966-6674c354f25c', 'Middlesex and Norfolk District', 'Senator, Middlesex and Norfolk District', 1, '20261103MA22969', '122428', 'Karen E. Spilka', 'Karen', 'Spilka', false, true, 'Dem', 0, 0, true, true, 'won', '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'holder-exact-full-name', 'Karen E. Spilka'),
  ('033edb14-d56a-4ec3-8cff-104f0f4f94b4', '6e636bdb-7f21-4bba-b2ac-1bbb23669e5d', 'Middlesex and Worcester District', 'Senator, Middlesex and Worcester District', 1, '20261103MA22972', '122429', 'James Bradley Eldridge', 'James', 'Eldridge', false, true, 'Dem', 55401, 73.63, false, true, 'won', '9ed1b75f-a314-4241-87ff-231de4aba963'::uuid, 'holder-exact-first-last', 'James B. Eldridge'),
  ('033edb14-d56a-4ec3-8cff-104f0f4f94b4', '6e636bdb-7f21-4bba-b2ac-1bbb23669e5d', 'Middlesex and Worcester District', 'Senator, Middlesex and Worcester District', 1, '20261103MA22972', '123760', 'Joseph Timothy Shea', 'Joseph', 'Shea', false, false, 'GOP', 19844, 26.37, false, true, 'lost', NULL, NULL, NULL),
  ('60f35ebe-c98c-44b7-9225-e828f7138158', '644861ae-b067-481e-83a6-3a116ba5119d', 'Norfolk and Middlesex District', 'Senator, Norfolk and Middlesex District', 1, '20261103MA24055', '54609', 'Cynthia Stone Creem', 'Cynthia', 'Creem', false, true, 'Dem', 0, 0, true, true, 'won', 'b46a6774-2d85-4750-813a-6d4ef2eefb5b'::uuid, 'holder-exact-first-last', 'Cynthia S. Creem'),
  ('97fe1f1d-fe5e-40c2-8f64-0c9ff9775636', 'fb4f16b3-743e-477b-96e4-c20b9efc57bb', 'Norfolk and Plymouth District', 'Senator, Norfolk and Plymouth District', 1, '20261103MA22975', '122137', 'John F. Keenan', 'John', 'Keenan', false, true, 'Dem', 40211, 73.07, false, true, 'won', '5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'holder-exact-full-name', 'John F. Keenan'),
  ('97fe1f1d-fe5e-40c2-8f64-0c9ff9775636', 'fb4f16b3-743e-477b-96e4-c20b9efc57bb', 'Norfolk and Plymouth District', 'Senator, Norfolk and Plymouth District', 1, '20261103MA22975', '123822', 'Alexander Mendez', 'Alexander', 'Mendez', false, false, 'Ind', 14817, 26.93, false, true, 'lost', NULL, NULL, NULL),
  ('6ff16418-5dcd-4ba9-ab13-dabed0fa496e', '1c0bce90-1351-4799-ad2b-46616829e304', 'Norfolk and Suffolk District', 'Senator, Norfolk and Suffolk District', 1, '20261103MA22980', '176879', 'Persis S. Yu', 'Persis', 'Yu', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('50127a58-065b-4cba-bc51-b5a9da6d51e1', '511f853a-fd2c-4692-99c7-945873a1fadd', 'Norfolk-Plymouth-Bristol District', 'Senator, Norfolk-Plymouth-Bristol District', 1, '20261103MA23169', '123602', 'William J. Driscoll Jr.', 'William', 'Driscoll', false, true, 'Dem', 0, 0, true, true, 'won', 'ab975fdf-b4f1-4955-94a4-97681a2a8d08'::uuid, 'holder-exact-first-last', 'William J. Driscoll'),
  ('6bbd266f-5bf2-423b-96ed-d6ac1a5f02a5', 'd5f3a740-a353-4049-ad34-2265efa161cf', 'Norfolk-Worcester-Middlesex District', 'Senator, Norfolk-Worcester-Middlesex District', 1, '20261103MA23879', '124017', 'Rebecca L. Rausch', 'Rebecca', 'Rausch', false, true, 'Dem', 0, 0, true, true, 'won', 'b7369e32-1916-413e-b0eb-2871a5348470'::uuid, 'holder-exact-full-name', 'Rebecca L. Rausch'),
  ('0725cf42-ac3f-4ea4-af22-9e3ac8f0c12a', '83132d3f-0bd0-43e3-9e52-646b8cc5400e', 'Plymouth and Barnstable District', 'Senator, Plymouth and Barnstable District', 1, '20261103MA22976', '123514', 'Dylan A. Fernandes', 'Dylan', 'Fernandes', false, true, 'Dem', 55533, 59.92, false, true, 'won', '8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid, 'holder-exact-full-name', 'Dylan A. Fernandes'),
  ('0725cf42-ac3f-4ea4-af22-9e3ac8f0c12a', '83132d3f-0bd0-43e3-9e52-646b8cc5400e', 'Plymouth and Barnstable District', 'Senator, Plymouth and Barnstable District', 1, '20261103MA22976', '124989', 'Kari Della MacRae', 'Kari', 'MacRae', false, false, 'GOP', 37153, 40.08, false, true, 'lost', NULL, NULL, NULL),
  ('b8edbfbe-e443-49ca-b785-96bbc5fed125', '5d05c288-1021-4329-9a25-0f3719cd40fe', 'Second Bristol and Plymouth District', 'Senator, Second Bristol and Plymouth District', 1, '20261103MA23870', '122425', 'Mark C. W. Montigny', 'Mark', 'Montigny', false, true, 'Dem', 34268, 63.85, false, true, 'won', '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, 'holder-exact-first-last', 'Mark C. Montigny'),
  ('b8edbfbe-e443-49ca-b785-96bbc5fed125', '5d05c288-1021-4329-9a25-0f3719cd40fe', 'Second Bristol and Plymouth District', 'Senator, Second Bristol and Plymouth District', 1, '20261103MA23870', '125200', 'Robert Scott McConnell', 'Robert', 'McConnell', false, false, 'GOP', 19398, 36.15, false, true, 'lost', NULL, NULL, NULL),
  ('ca8c8b5f-fe99-4f27-a25d-a89c48fc48cc', 'c50ef8da-e2ba-4d28-a986-ff2883e0f123', 'Second Essex and Middlesex District', 'Senator, Second Essex and Middlesex District', 1, '20261103MA23172', '54472', 'Barry R. Finegold', 'Barry', 'Finegold', false, true, 'Dem', 48790, 63.69, false, true, 'won', '15f59b0c-f71c-4199-b195-7b653a05a310'::uuid, 'holder-exact-full-name', 'Barry R. Finegold'),
  ('ca8c8b5f-fe99-4f27-a25d-a89c48fc48cc', 'c50ef8da-e2ba-4d28-a986-ff2883e0f123', 'Second Essex and Middlesex District', 'Senator, Second Essex and Middlesex District', 1, '20261103MA23172', '176890', 'Theodore T. Semesnyei', 'Theodore', 'Semesnyei', false, false, 'GOP', 27820, 36.31, false, true, 'lost', NULL, NULL, NULL),
  ('c23ec86c-bf8f-4d29-9f45-1bd8270ad908', '79b9424d-b361-40ec-a897-d27bccc484e4', 'Second Essex District', 'Senator, Second Essex District', 1, '20261103MA22965', '63045', 'Joan B. Lovely', 'Joan', 'Lovely', false, true, 'Dem', 0, 0, true, true, 'won', '6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'holder-exact-full-name', 'Joan B. Lovely'),
  ('edb900bb-21bc-4c39-ab32-3ef424ec4a99', 'b1ed4e2a-4a9c-4b41-9e46-8500f608e026', 'Second Middlesex District', 'Senator, Second Middlesex District', 1, '20261103MA23175', '124607', 'Erika Uyterhoeven', 'Erika', 'Uyterhoeven', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('024c4426-8fa5-46f3-adee-61edc629aaee', 'be02c0c8-b4a7-492b-8d9e-74147c9f2e6b', 'Second Plymouth and Norfolk District', 'Senator, Second Plymouth and Norfolk District', 1, '20261103MA23170', '122587', 'Michael D. Brady', 'Michael', 'Brady', false, true, 'Dem', 0, 0, true, true, 'won', '67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'holder-exact-full-name', 'Michael D. Brady'),
  ('5342371a-d79e-42f1-89a8-26c928bdb41a', '12b598a5-6c67-4c66-a4dd-1e3a09bc478a', 'Second Suffolk District', 'Senator, Second Suffolk District', 1, '20261103MA22978', '124215', 'Liz Miranda', 'Liz', 'Miranda', false, true, 'Dem', 0, 0, true, true, 'won', '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'holder-exact-full-name', 'Liz Miranda'),
  ('3984d8f2-d35f-4a9f-b370-36eb57fbc1ed', 'ba0249f2-7a1f-4124-92f2-b888202db232', 'Second Worcester District', 'Senator, Second Worcester District', 1, '20261103MA22786', '63064', 'Michael O. Moore', 'Michael', 'Moore', false, true, 'Dem', 0, 0, true, true, 'won', 'c0b79f82-6ce7-413a-a18a-286c9a8fa5fd'::uuid, 'holder-exact-full-name', 'Michael O. Moore'),
  ('b7eb1726-cda3-412d-9881-7ea6b0033a6b', '03fa0eeb-8ed6-4f5d-8c47-1d35db497c04', 'Third Bristol and Plymouth District', 'Senator, Third Bristol and Plymouth District', 1, '20261103MA22973', '124676', 'Kelly A. Dooner', 'Kelly', 'Dooner', false, true, 'GOP', 0, 0, true, true, 'won', '247cf8e5-426a-4104-9027-6a2a0b1b61c9'::uuid, 'holder-exact-full-name', 'Kelly A. Dooner'),
  ('61b2349b-f532-43e4-ae34-1c8fcf4b0988', 'f586736b-7f51-40aa-91a1-493caa3492a5', 'Third Essex District', 'Senator, Third Essex District', 1, '20261103MA24551', '123171', 'Brendan Peter Crighton', 'Brendan', 'Crighton', false, true, 'Dem', 0, 0, true, true, 'won', '99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'holder-exact-first-last', 'Brendan P. Crighton'),
  ('2b79d36d-1f2a-4e34-8762-2525c81ccd5e', 'aff2ab54-96a5-447a-a455-43c9b1888128', 'Third Middlesex District', 'Senator, Third Middlesex District', 1, '20261103MA22044', '63050', 'Michael J. Barrett', 'Michael', 'Barrett', false, true, 'Dem', 0, 0, true, true, 'won', '60e4da77-0c2b-4ca4-8d02-a4210bd91d90'::uuid, 'holder-exact-full-name', 'Michael J. Barrett'),
  ('a1fc10c4-04c0-4dd7-ac08-5fcf87ac8fdb', '317ee1aa-303f-431c-bf24-0a64ec26973e', 'Third Suffolk District', 'Senator, Third Suffolk District', 1, '20261103MA23873', '123904', 'Lydia Marie Edwards', 'Lydia', 'Edwards', false, true, 'Dem', 0, 0, true, true, 'won', '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'holder-exact-first-last', 'Lydia M. Edwards'),
  ('93879f19-8e57-4f55-a5e4-2292393827a6', 'aaf44b12-c002-4b33-ac54-0e0ea0df9634', 'Worcester and Hampden District', 'Senator, Worcester and Hampden District', 1, '20261103MA22981', '122408', 'Ryan C. Fattman', 'Ryan', 'Fattman', false, true, 'GOP', 0, 0, true, true, 'won', '785c2d95-9d99-41c9-b903-7aab661f8928'::uuid, 'holder-exact-full-name', 'Ryan C. Fattman'),
  ('b36692fe-aeea-48ce-992c-0cf72dd6c7d3', '18aae1ae-05eb-4d87-9b8e-97e01e38901b', 'Worcester and Hampshire District', 'Senator, Worcester and Hampshire District', 1, '20261103MA22983', '122397', 'Peter J. Durant', 'Peter', 'Durant', false, true, 'GOP', 37888, 53.96, false, true, 'won', '82943cda-5803-46c7-a854-697ad6052eda'::uuid, 'holder-exact-full-name', 'Peter J. Durant'),
  ('b36692fe-aeea-48ce-992c-0cf72dd6c7d3', '18aae1ae-05eb-4d87-9b8e-97e01e38901b', 'Worcester and Hampshire District', 'Senator, Worcester and Hampshire District', 1, '20261103MA22983', '176884', 'Shannon M. Teabo', 'Shannon', 'Teabo', false, false, 'Dem', 32332, 46.04, false, true, 'lost', NULL, NULL, NULL),
  ('9f7de529-fa42-4cb6-aeca-81685481a963', 'ac3543b7-d5af-4939-b4ae-1cf49bf2578e', 'Worcester and Middlesex District', 'Senator, Worcester and Middlesex District', 1, '20261103MA22982', '124528', 'John Cronin', 'John', 'Cronin', false, true, 'Dem', 45723, 79.79, false, true, 'won', 'ef888471-24a9-4a9f-9115-e530c16986ae'::uuid, 'holder-exact-first-last', 'John J. Cronin'),
  ('9f7de529-fa42-4cb6-aeca-81685481a963', 'ac3543b7-d5af-4939-b4ae-1cf49bf2578e', 'Worcester and Middlesex District', 'Senator, Worcester and Middlesex District', 1, '20261103MA22982', '179355', 'Ming Zhang', 'Ming', 'Zhang', false, false, 'Unr', 11584, 20.21, false, true, 'lost', NULL, NULL, NULL);

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> 256 THEN RAISE EXCEPTION 'CC_0413: expected 256 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> 196 THEN RAISE EXCEPTION 'CC_0413: expected 196 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> 195 THEN RAISE EXCEPTION 'CC_0413: expected 195 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> 59 THEN RAISE EXCEPTION 'CC_0413: expected 59 losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0413: expected 2 rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> 256 THEN RAISE EXCEPTION 'CC_0413: the race join sees % of the 256 rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 Massachusetts legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> 'ma'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % pinned row(s) are not in a 2026-11-03 Massachusetts legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: winner count does not match races.seats: %', txt; END IF;

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
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> 178 THEN RAISE EXCEPTION 'CC_0413: expected 178 incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: external_id already in use: %', txt; END IF;
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
         || '2026-11-03/results/races/MA/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against the Secretary of the Commonwealth''s own "2026 State Election Candidates" page '
         || '(https://www.sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm, read 2026-11-13). Seeded by CC_0413.'
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
  IF n <> 256 THEN RAISE EXCEPTION 'CC_0413: expected 256 rows written, found %', n; END IF;

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
  IF n <> 256 THEN RAISE EXCEPTION 'CC_0413: only % of 256 written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0413: a citation quotes a vote count: %', txt; END IF;

  -- The 196 races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = 'ma'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0413: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> 178 THEN RAISE EXCEPTION 'CC_0413: the seat holder changed for % of the 178 linked office(s) — this file seats nobody', 178 - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION 'CC_0413: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'CC_0413: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
