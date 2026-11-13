-- CC_0415 - 2026-11-03 Maryland legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the 118 races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. `CC_0381`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for Maryland.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The Maryland legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    `essentials.office_terms` is untouched, `essentials.offices` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--    289 candidacies across 118 races
--    178 won · 91 lost · 20 with NO result (4 race(s) AP has not called)
--     98 linked to a politician we already hold; the rest carry politician_id NULL
--      0 declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
--    The uncalled race(s) here:
--      State Legislative Subdistrict 34B (AP race 20261103MD22395, Too Early to Call)
--      State Legislative District 31 (AP race 20261103MD22159, Too Early to Call)
--      State Legislative District 6 (AP race 20261103MD22200, Too Early to Call)
--      State Legislative District 4 (AP race 20261103MD22799, Too Early to Call)
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read 2026-11-13:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/MD/
-- and the State Board of Elections' own unofficial returns for State Senator and the House of Delegates,
-- read 2026-11-13 with Playwright:
--   https://elections.maryland.gov/elections/2026/general_results/index.html
--
-- The join, the differences and how each one was settled are in
-- `backend/data/state-leg-2026-seed/` — `md-crosscheck-2026-11-13.json` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (`CC_0408`-`CC_0411`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. 41 of these 118 races are uncontested and 69 of the 289 rows carry a
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
-- 🔴 AP REUSES ONE CANDIDATE ID FOR TWO DIFFERENT PEOPLE IN THIS STATE. Id 120083 is "Mark
--    Fisher" in BOTH Subdistrict 27C — where AP flags him incumbent, our roster names the
--    holder "Mark N. Fisher", and he wins — and District 13, in another county, where AP flags
--    the SAME id as not incumbent and he loses. Maryland's own returns name them separately
--    ("Mark N. Fisher" and "Mark Fisher"). Whether AP has merged two namesakes or contradicted
--    itself about one man, our side holds two candidacies, and keying on the person's id would
--    have collided them. `A NAME THAT MATCHES IS NOT A PERSON THAT MATCHES` — and neither is a
--    published id.
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
--   holder-exact-full-name      73
--   holder-surname-plus-roster   8
--   holder-exact-first-last     14
--   holder-initial-in-first-name-field   1
--   holder-suffix-folded         2
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
-- Slot CC_0415 reserved via steward. Applied to production 2026-11-13 by Chris Cantrell.
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
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '122259', 'J. Sandy Bartlett', 'J.', 'Bartlett', false, true, 'Dem', 28604, 24.92, false, true, 'won', '7d818044-a989-47e1-b6cf-d482ebad0600'::uuid, 'holder-exact-full-name', 'J. Sandy Bartlett'),
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '173685', 'Spencer F. Dixon', 'Spencer', 'Dixon', false, false, 'Dem', 27035, 23.55, false, true, 'won', NULL, NULL, NULL),
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '122262', 'Mike Rogers', 'Mike', 'Rogers', false, true, 'Dem', 27708, 24.14, false, true, 'won', NULL, NULL, NULL),
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '173689', 'Colin McEvers', 'Colin', 'McEvers', false, false, 'GOP', 10616, 9.25, false, true, 'lost', NULL, NULL, NULL),
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '173690', 'Mary Phelps', 'Mary', 'Phelps', false, false, 'GOP', 11047, 9.62, false, true, 'lost', NULL, NULL, NULL),
  ('6a089f56-c704-4512-b9d0-ad4e180e536a', 'f1009191-dcef-4657-a2eb-40a20289a054', 'State Legislative District 32', 'Delegate', 3, '20261103MD22160', '173691', 'Marcus Damon Snipes Jr.', 'Marcus', 'Snipes', false, false, 'GOP', 9784, 8.52, false, true, 'lost', NULL, NULL, NULL),
  ('93fd5845-11f8-491f-86e0-d6cad160390d', '7f8936f1-734a-4f4e-9d48-d73399dba7f1', 'State Legislative Subdistrict 42A', 'Delegate', 1, '20261103MD22911', '173736', 'Jyoti Mohan', 'Jyoti', 'Mohan', false, false, 'Dem', 9305, 44.69, false, true, 'lost', NULL, NULL, NULL),
  ('93fd5845-11f8-491f-86e0-d6cad160390d', '7f8936f1-734a-4f4e-9d48-d73399dba7f1', 'State Legislative Subdistrict 42A', 'Delegate', 1, '20261103MD22911', '173739', 'Charles Edward Murphy III', 'Charles', 'Murphy', false, false, 'GOP', 11514, 55.31, false, true, 'won', NULL, NULL, NULL),
  ('c35cb34a-e803-4314-9ac4-2c2a84690dfb', '208c685a-5b1b-4c5e-b324-33f5f015cc6d', 'State Legislative Subdistrict 47B', 'Delegate', 1, '20261103MD22798', '122600', 'Deni Taveras', 'Deni', 'Taveras', false, true, 'Dem', 0, 0, true, true, 'won', 'a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid, 'holder-exact-full-name', 'Deni Taveras'),
  ('ba26d54a-4a7f-4df2-a5e5-fc1daf7743e0', '63a04f44-51eb-4999-afe0-0f8ef4d5ddbf', 'State Legislative Subdistrict 47A', 'Delegate', 2, '20261103MD22797', '120427', 'Diana M. Fennell', 'Diana', 'Fennell', false, true, 'Dem', 14755, 50.69, false, true, 'won', '192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid, 'holder-exact-full-name', 'Diana M. Fennell'),
  ('ba26d54a-4a7f-4df2-a5e5-fc1daf7743e0', '63a04f44-51eb-4999-afe0-0f8ef4d5ddbf', 'State Legislative Subdistrict 47A', 'Delegate', 2, '20261103MD22797', '122598', 'Robert Julian Ivey', 'Robert', 'Ivey', false, true, 'Dem', 13031, 44.77, false, true, 'won', NULL, NULL, NULL),
  ('ba26d54a-4a7f-4df2-a5e5-fc1daf7743e0', '63a04f44-51eb-4999-afe0-0f8ef4d5ddbf', 'State Legislative Subdistrict 47A', 'Delegate', 2, '20261103MD22797', '120675', 'Fred M. Price Jr.', 'Fred', 'Price', false, false, 'GOP', 1320, 4.54, false, true, 'lost', NULL, NULL, NULL),
  ('5a457eab-8e09-4e10-9b20-6f3e5ad7e260', '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', 'State Legislative District 46', 'Delegate', 3, '20261103MD22173', '120424', 'Luke Clippinger', 'Luke', 'Clippinger', false, true, 'Dem', 25902, 31.89, false, true, 'won', 'ad1aaa25-0ef6-4c88-9d78-d75aec7398c7'::uuid, 'holder-exact-full-name', 'Luke Clippinger'),
  ('5a457eab-8e09-4e10-9b20-6f3e5ad7e260', '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', 'State Legislative District 46', 'Delegate', 3, '20261103MD22173', '121664', 'Mark Edelson', 'Mark', 'Edelson', false, true, 'Dem', 25063, 30.86, false, true, 'won', NULL, NULL, NULL),
  ('5a457eab-8e09-4e10-9b20-6f3e5ad7e260', '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', 'State Legislative District 46', 'Delegate', 3, '20261103MD22173', '122330', 'Robbyn Lewis', 'Robbyn', 'Lewis', false, true, 'Dem', 25350, 31.21, false, true, 'won', NULL, NULL, NULL),
  ('5a457eab-8e09-4e10-9b20-6f3e5ad7e260', '5b0426c8-c6ad-4e0d-a102-3bd20762bd98', 'State Legislative District 46', 'Delegate', 3, '20261103MD22173', '173753', 'Jeremy L. Amason', 'Jeremy', 'Amason', false, false, 'GOP', 4900, 6.03, false, true, 'lost', NULL, NULL, NULL),
  ('cb5d7f70-3adb-4e60-9caa-6d6f70331828', '2f135b6a-4dd6-458a-988a-95d72b291956', 'State Legislative District 45', 'Delegate', 3, '20261103MD22172', '122610', 'Jackie Addison', 'Jackie', 'Addison', false, true, 'Dem', 25629, 32.78, false, true, 'won', '01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid, 'holder-exact-full-name', 'Jackie Addison'),
  ('cb5d7f70-3adb-4e60-9caa-6d6f70331828', '2f135b6a-4dd6-458a-988a-95d72b291956', 'State Legislative District 45', 'Delegate', 3, '20261103MD22172', '173747', 'Chanel A. Branch', 'Chanel', 'Branch', false, false, 'Dem', 24653, 31.53, false, true, 'won', NULL, NULL, NULL),
  ('cb5d7f70-3adb-4e60-9caa-6d6f70331828', '2f135b6a-4dd6-458a-988a-95d72b291956', 'State Legislative District 45', 'Delegate', 3, '20261103MD22172', '122349', 'Caylin Young', 'Caylin', 'Young', false, true, 'Dem', 23522, 30.08, false, true, 'won', NULL, NULL, NULL),
  ('cb5d7f70-3adb-4e60-9caa-6d6f70331828', '2f135b6a-4dd6-458a-988a-95d72b291956', 'State Legislative District 45', 'Delegate', 3, '20261103MD22172', '123076', 'Renaud De''Aundre Brown', 'Renaud', 'Brown', false, false, 'Grn', 4382, 5.6, false, true, 'lost', NULL, NULL, NULL),
  ('59531d14-0c66-49cb-b5ba-a4ceca994d40', 'f5446de1-714e-44fe-bd32-d3740fe078ad', 'State Legislative Subdistrict 44B', 'Delegate', 2, '20261103MD22796', '121872', 'Aletheia McCaskill', 'Aletheia', 'McCaskill', false, true, 'Dem', 23064, 45.46, false, true, 'won', 'fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid, 'holder-exact-full-name', 'Aletheia McCaskill'),
  ('59531d14-0c66-49cb-b5ba-a4ceca994d40', 'f5446de1-714e-44fe-bd32-d3740fe078ad', 'State Legislative Subdistrict 44B', 'Delegate', 2, '20261103MD22796', '122594', 'Sheila Ruth', 'Sheila', 'Ruth', false, true, 'Dem', 22218, 43.79, false, true, 'won', NULL, NULL, NULL),
  ('59531d14-0c66-49cb-b5ba-a4ceca994d40', 'f5446de1-714e-44fe-bd32-d3740fe078ad', 'State Legislative Subdistrict 44B', 'Delegate', 2, '20261103MD22796', '173746', 'Domonic Martin', 'Domonic', 'Martin', false, false, 'GOP', 5453, 10.75, false, true, 'lost', NULL, NULL, NULL),
  ('1e8966ee-0529-482a-9912-003153463642', '8325738a-bc3c-4fc1-b7f3-6f7d0bcedc82', 'State Legislative Subdistrict 44A', 'Delegate', 1, '20261103MD22795', '121156', 'Eric Ebersole', 'Eric', 'Ebersole', false, true, 'Dem', 8364, 69.26, false, true, 'won', '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid, 'holder-exact-full-name', 'Eric Ebersole'),
  ('1e8966ee-0529-482a-9912-003153463642', '8325738a-bc3c-4fc1-b7f3-6f7d0bcedc82', 'State Legislative Subdistrict 44A', 'Delegate', 1, '20261103MD22795', '173744', 'Chuck Linton', 'Chuck', 'Linton', false, false, 'GOP', 3712, 30.74, false, true, 'lost', NULL, NULL, NULL),
  ('5dad7b8a-4c4c-423d-b9c5-680f94f70bc9', 'ab23be1b-2601-4d9c-b840-850c58e67f44', 'State Legislative Subdistrict 43B', 'Delegate', 1, '20261103MD22910', '122590', 'Cathi Forbes', 'Cathi', 'Forbes', false, true, 'Dem', 0, 0, true, true, 'won', 'c017b328-4469-45c4-aa8a-7b9035c77e22'::uuid, 'holder-surname-plus-roster', 'Catherine M. Forbes'),
  ('9696aaac-e2d2-4ce8-a8ae-17324d756c67', '90259d95-991d-4535-8d06-db1abca0c6f9', 'State Legislative Subdistrict 43A', 'Delegate', 2, '20261103MD22170', '121891', 'Regina T. Boyce', 'Regina', 'Boyce', false, true, 'Dem', 0, 0, true, true, 'won', '027a2610-1160-4525-a5c1-469fe85d46e1'::uuid, 'holder-exact-full-name', 'Regina T. Boyce'),
  ('9696aaac-e2d2-4ce8-a8ae-17324d756c67', '90259d95-991d-4535-8d06-db1abca0c6f9', 'State Legislative Subdistrict 43A', 'Delegate', 2, '20261103MD22170', '121636', 'Elizabeth Embry', 'Elizabeth', 'Embry', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('76417dd2-3c83-490f-a14f-a788590d8caf', 'bb979c67-1e70-4002-beaa-d4c7a7fe92cc', 'State Legislative Subdistrict 42C', 'Delegate', 1, '20261103MD22793', '173742', 'Corynne Courpas', 'Corynne', 'Courpas', false, false, 'Dem', 6709, 34.96, false, true, 'lost', NULL, NULL, NULL),
  ('76417dd2-3c83-490f-a14f-a788590d8caf', 'bb979c67-1e70-4002-beaa-d4c7a7fe92cc', 'State Legislative Subdistrict 42C', 'Delegate', 1, '20261103MD22793', '173743', 'Steve Patten', 'Steve', 'Patten', false, false, 'GOP', 12479, 65.04, false, true, 'won', NULL, NULL, NULL),
  ('f3a05b96-0a46-4888-af77-fa473872331e', '5d83206a-c916-4f89-bcb4-f05b33b9754d', 'State Legislative Subdistrict 42B', 'Delegate', 1, '20261103MD22794', '121882', 'Michele Guyton', 'Michele', 'Guyton', false, true, 'Dem', 10050, 66.13, false, true, 'won', 'bb180c23-b965-4bba-a2b9-73febd484d21'::uuid, 'holder-exact-full-name', 'Michele Guyton'),
  ('f3a05b96-0a46-4888-af77-fa473872331e', '5d83206a-c916-4f89-bcb4-f05b33b9754d', 'State Legislative Subdistrict 42B', 'Delegate', 1, '20261103MD22794', '173740', 'Jeffry K. McDonald', 'Jeffry', 'McDonald', false, false, 'GOP', 5147, 33.87, false, true, 'lost', NULL, NULL, NULL),
  ('bfe7b0a0-7922-46b6-9d92-d0422c2dbc2d', 'd22d3bdb-71c0-41af-b84d-a8ceb4e17b97', 'State Legislative District 41', 'Delegate', 3, '20261103MD22168', '54751', 'S. I. Rosenberg', 'S. I.', 'Rosenberg', false, true, 'Dem', 0, 0, true, true, 'won', '36eecaff-4677-441a-b36e-a323e87d9158'::uuid, 'holder-surname-plus-roster', 'Samuel I. Rosenberg'),
  ('bfe7b0a0-7922-46b6-9d92-d0422c2dbc2d', 'd22d3bdb-71c0-41af-b84d-a8ceb4e17b97', 'State Legislative District 41', 'Delegate', 3, '20261103MD22168', '121461', 'Sean A. Stinnett', 'Sean', 'Stinnett', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('bfe7b0a0-7922-46b6-9d92-d0422c2dbc2d', 'd22d3bdb-71c0-41af-b84d-a8ceb4e17b97', 'State Legislative District 41', 'Delegate', 3, '20261103MD22168', '173735', 'Ryan Turner', 'Ryan', 'Turner', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('79feecb7-0925-4079-a46c-43935e9e06b3', 'd5ec3f19-e9e2-4f4a-8cda-9a2ded496e60', 'State Legislative District 40', 'Delegate', 3, '20261103MD22167', '122996', 'Marlon D. Amprey', 'Marlon', 'Amprey', false, true, 'Dem', 0, 0, true, true, 'won', '62bed8b6-beb2-4c41-b234-dc6427bfc9c0'::uuid, 'holder-exact-first-last', 'Marlon Amprey'),
  ('79feecb7-0925-4079-a46c-43935e9e06b3', 'd5ec3f19-e9e2-4f4a-8cda-9a2ded496e60', 'State Legislative District 40', 'Delegate', 3, '20261103MD22167', '173727', 'Tiffany Welch', 'Tiffany', 'Welch', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('79feecb7-0925-4079-a46c-43935e9e06b3', 'd5ec3f19-e9e2-4f4a-8cda-9a2ded496e60', 'State Legislative District 40', 'Delegate', 3, '20261103MD22167', '122309', 'Melissa Wells', 'Melissa', 'Wells', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('654bd1fb-641a-4ef0-89c9-63523bb78c96', '0cb0a265-5710-4456-8f78-7a4fab3c8f86', 'State Legislative District 39', 'Delegate', 3, '20261103MD22166', '122295', 'Gabriel Acevero', 'Gabriel', 'Acevero', false, true, 'Dem', 0, 0, true, true, 'won', 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid, 'holder-exact-full-name', 'Gabriel Acevero'),
  ('654bd1fb-641a-4ef0-89c9-63523bb78c96', '0cb0a265-5710-4456-8f78-7a4fab3c8f86', 'State Legislative District 39', 'Delegate', 3, '20261103MD22166', '122298', 'Lesley J. Lopez', 'Lesley', 'Lopez', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('654bd1fb-641a-4ef0-89c9-63523bb78c96', '0cb0a265-5710-4456-8f78-7a4fab3c8f86', 'State Legislative District 39', 'Delegate', 3, '20261103MD22166', '173722', 'Greg Wims', 'Greg', 'Wims', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('5dad8dfe-c3a0-42e6-a109-d9d99d0eb19a', '4edd1103-07ee-41b0-93c9-83b8cfdb662e', 'State Legislative Subdistrict 38C', 'Delegate', 1, '20261103MD22792', '122292', 'Wayne A. Hartman', 'Wayne', 'Hartman', false, true, 'GOP', 0, 0, true, true, 'won', '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid, 'holder-exact-full-name', 'Wayne A. Hartman'),
  ('ff106dcd-0347-4d4b-96e5-6f733ca10d6b', 'af0c4413-22d1-4219-8972-c81da7d5970c', 'State Legislative Subdistrict 38B', 'Delegate', 1, '20261103MD22397', '173717', 'Josh Hastings', 'Josh', 'Hastings', false, false, 'Dem', 7927, 60.32, false, true, 'won', NULL, NULL, NULL),
  ('ff106dcd-0347-4d4b-96e5-6f733ca10d6b', 'af0c4413-22d1-4219-8972-c81da7d5970c', 'State Legislative Subdistrict 38B', 'Delegate', 1, '20261103MD22397', '173718', 'Barry S. Beauchamp', 'Barry', 'Beauchamp', false, true, 'GOP', 5215, 39.68, false, true, 'lost', 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid, 'holder-exact-first-last', 'Barry Beauchamp'),
  ('8fcd8a2c-b915-4518-b09b-f3399023aa31', 'd7ba04fc-d342-44f2-8df7-76a33241f352', 'State Legislative Subdistrict 38A', 'Delegate', 1, '20261103MD22396', '173714', 'Shelley Johnson', 'Shelley', 'Johnson', false, false, 'Dem', 7002, 42.06, false, true, 'lost', NULL, NULL, NULL),
  ('8fcd8a2c-b915-4518-b09b-f3399023aa31', 'd7ba04fc-d342-44f2-8df7-76a33241f352', 'State Legislative Subdistrict 38A', 'Delegate', 1, '20261103MD22396', '173716', 'C.L. Marshall III', 'C.L.', 'Marshall', false, false, 'GOP', 9645, 57.94, false, true, 'won', NULL, NULL, NULL),
  ('d68f8b6b-e3da-4d58-a6e4-756c7e034d5b', 'bd0973d8-505f-4477-bfee-9d1b67f4125b', 'State Legislative Subdistrict 37B', 'Delegate', 2, '20261103MD22208', '173233', 'Edmund J. Barrett', 'Edmund', 'Barrett', false, false, 'Dem', 14773, 19.76, false, true, 'lost', NULL, NULL, NULL),
  ('d68f8b6b-e3da-4d58-a6e4-756c7e034d5b', 'bd0973d8-505f-4477-bfee-9d1b67f4125b', 'State Legislative Subdistrict 37B', 'Delegate', 2, '20261103MD22208', '173713', 'Michele W. Johnson', 'Michele', 'Johnson', false, false, 'Dem', 15771, 21.1, false, true, 'lost', NULL, NULL, NULL),
  ('d68f8b6b-e3da-4d58-a6e4-756c7e034d5b', 'bd0973d8-505f-4477-bfee-9d1b67f4125b', 'State Legislative Subdistrict 37B', 'Delegate', 2, '20261103MD22208', '121425', 'Chris Adams', 'Chris', 'Adams', false, true, 'GOP', 21629, 28.93, false, true, 'won', '1eada938-f28c-46b9-bd21-df241656cd2b'::uuid, 'holder-surname-plus-roster', 'Christopher T. Adams'),
  ('d68f8b6b-e3da-4d58-a6e4-756c7e034d5b', 'bd0973d8-505f-4477-bfee-9d1b67f4125b', 'State Legislative Subdistrict 37B', 'Delegate', 2, '20261103MD22208', '122988', 'Tom Hutchinson', 'Tom', 'Hutchinson', false, true, 'GOP', 22585, 30.21, false, true, 'won', NULL, NULL, NULL),
  ('f8639ed1-97b4-40bb-ae60-23a751e1f3e5', '6b47e6da-37bd-40ce-9f8f-d5bb98c71edd', 'State Legislative Subdistrict 37A', 'Delegate', 1, '20261103MD22164', '121419', 'Sheree Sample-Hughes', 'Sheree', 'Sample-Hughes', false, true, 'Dem', 0, 0, true, true, 'won', 'a1c2b55c-df7d-487c-ad90-7f7e2c2e6951'::uuid, 'holder-exact-full-name', 'Sheree Sample-Hughes'),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '173710', 'Nevin Crouse', 'Nevin', 'Crouse', false, false, 'Dem', 17292, 12.51, false, true, 'lost', NULL, NULL, NULL),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '173711', 'Michelle Ravert', 'Michelle', 'Ravert', false, false, 'Dem', 19169, 13.87, false, true, 'lost', NULL, NULL, NULL),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '122282', 'Crystal Woodward', 'Crystal', 'Woodward', false, false, 'Dem', 19465, 14.09, false, true, 'lost', NULL, NULL, NULL),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '121408', 'Steve Arentz', 'Steve', 'Arentz', false, true, 'GOP', 28807, 20.85, false, true, 'won', 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid, 'holder-initial-in-first-name-field', 'Steven J. Arentz'),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '121410', 'Jeff Ghrist', 'Jeff', 'Ghrist', false, true, 'GOP', 25600, 18.53, false, true, 'won', NULL, NULL, NULL),
  ('b9779e6e-e258-4836-bb52-9f0e5036160d', 'c07711d6-eee8-4343-8ab7-62479fe4ffac', 'State Legislative District 36', 'Delegate', 3, '20261103MD22163', '120155', 'Jay A. Jacobs', 'Jay', 'Jacobs', false, true, 'GOP', 27843, 20.15, false, true, 'won', NULL, NULL, NULL),
  ('0ca1f92b-523a-455c-9b14-9af8aebfabb3', 'aefe1a1a-4df7-4803-ac6f-754c963ac2a7', 'State Legislative Subdistrict 35B', 'Delegate', 1, '20261103MD22188', '162579', 'Blessing T. Oluwadare', 'Blessing', 'Oluwadare', false, false, 'Dem', 4961, 32.79, false, true, 'lost', NULL, NULL, NULL),
  ('0ca1f92b-523a-455c-9b14-9af8aebfabb3', 'aefe1a1a-4df7-4803-ac6f-754c963ac2a7', 'State Legislative Subdistrict 35B', 'Delegate', 1, '20261103MD22188', '121000', 'Derek J. Howell', 'Derek', 'Howell', false, false, 'GOP', 10169, 67.21, false, true, 'won', NULL, NULL, NULL),
  ('2bb935ea-54a2-4b70-8217-4932473d6568', '1220b835-9c8d-4b71-8e24-cc803c688015', 'State Legislative Subdistrict 35A', 'Delegate', 2, '20261103MD22182', '173706', 'Gregory V. Anderson', 'Gregory', 'Anderson', false, false, 'Dem', 12448, 17.64, false, true, 'lost', NULL, NULL, NULL),
  ('2bb935ea-54a2-4b70-8217-4932473d6568', '1220b835-9c8d-4b71-8e24-cc803c688015', 'State Legislative Subdistrict 35A', 'Delegate', 2, '20261103MD22182', '173707', 'Michael A. Eckels Jr.', 'Michael', 'Eckels', false, false, 'Dem', 11539, 16.35, false, true, 'lost', NULL, NULL, NULL),
  ('2bb935ea-54a2-4b70-8217-4932473d6568', '1220b835-9c8d-4b71-8e24-cc803c688015', 'State Legislative Subdistrict 35A', 'Delegate', 2, '20261103MD22182', '122589', 'Mike Griffith', 'Mike', 'Griffith', false, true, 'GOP', 24395, 34.58, false, true, 'won', '0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid, 'holder-exact-full-name', 'Mike Griffith'),
  ('2bb935ea-54a2-4b70-8217-4932473d6568', '1220b835-9c8d-4b71-8e24-cc803c688015', 'State Legislative Subdistrict 35A', 'Delegate', 2, '20261103MD22182', '121403', 'Teresa Reilly', 'Teresa', 'Reilly', false, true, 'GOP', 22173, 31.43, false, true, 'won', NULL, NULL, NULL),
  ('e3532266-a824-449e-bb16-bb1bf81c31bc', 'eea7ec6c-af84-4267-a3e7-27af07d24735', 'State Legislative Subdistrict 34B', 'Delegate', 1, '20261103MD22395', '173702', 'Anthony Lyon', 'Anthony', 'Lyon', false, false, 'Dem', 9603, 49.42, false, false, NULL, NULL, NULL, NULL),
  ('e3532266-a824-449e-bb16-bb1bf81c31bc', 'eea7ec6c-af84-4267-a3e7-27af07d24735', 'State Legislative Subdistrict 34B', 'Delegate', 1, '20261103MD22395', '173703', 'Jake Taylor', 'Jake', 'Taylor', false, false, 'GOP', 9828, 50.58, false, false, NULL, NULL, NULL, NULL),
  ('322306e9-95a9-47d1-b2ba-8c9262b6c3d4', '9269138d-b572-4609-bb86-bdffa3ec8bf7', 'State Legislative Subdistrict 34A', 'Delegate', 2, '20261103MD22394', '122975', 'Andre V. Johnson Jr.', 'Andre', 'Johnson', false, true, 'Dem', 19789, 42.66, false, true, 'won', 'b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid, 'holder-exact-full-name', 'Andre V. Johnson, Jr.'),
  ('322306e9-95a9-47d1-b2ba-8c9262b6c3d4', '9269138d-b572-4609-bb86-bdffa3ec8bf7', 'State Legislative Subdistrict 34A', 'Delegate', 2, '20261103MD22394', '121374', 'Steve Johnson', 'Steve', 'Johnson', false, true, 'Dem', 15457, 33.32, false, true, 'won', NULL, NULL, NULL),
  ('322306e9-95a9-47d1-b2ba-8c9262b6c3d4', '9269138d-b572-4609-bb86-bdffa3ec8bf7', 'State Legislative Subdistrict 34A', 'Delegate', 2, '20261103MD22394', '173701', 'Elliott Joseph Herneker', 'Elliott', 'Herneker', false, false, 'GOP', 11146, 24.03, false, true, 'lost', NULL, NULL, NULL),
  ('c88970bc-3ec1-4d22-9c1d-fc3347cfce37', 'ad40af1e-198c-4e9a-9a83-36c2ca196abb', 'State Legislative Subdistrict 33C', 'Delegate', 1, '20261103MD22392', '122966', 'Heather A. Bagnall', 'Heather', 'Bagnall', false, true, 'Dem', 12547, 61.67, false, true, 'won', '41749b94-11b8-4047-8421-95db0900d4b2'::uuid, 'holder-exact-first-last', 'Heather Bagnall'),
  ('c88970bc-3ec1-4d22-9c1d-fc3347cfce37', 'ad40af1e-198c-4e9a-9a83-36c2ca196abb', 'State Legislative Subdistrict 33C', 'Delegate', 1, '20261103MD22392', '173700', 'Kristin M. Norris', 'Kristin', 'Norris', false, false, 'GOP', 7800, 38.33, false, true, 'lost', NULL, NULL, NULL),
  ('1b162347-3013-48b1-a48c-73042ead23e1', '84a3c1ef-f6ea-4e8b-b6d9-26f7cda0ee2e', 'State Legislative Subdistrict 33B', 'Delegate', 1, '20261103MD22393', '173698', 'Chuck Cook', 'Chuck', 'Cook', false, false, 'Dem', 11598, 54.94, false, true, 'won', NULL, NULL, NULL),
  ('1b162347-3013-48b1-a48c-73042ead23e1', '84a3c1ef-f6ea-4e8b-b6d9-26f7cda0ee2e', 'State Legislative Subdistrict 33B', 'Delegate', 1, '20261103MD22393', '173699', 'Stuart M. Schmidt Jr.', 'Stuart', 'Schmidt', false, true, 'GOP', 9514, 45.06, false, true, 'lost', '55d9d0b6-78a3-460b-97b9-87913ffc8e85'::uuid, 'holder-suffix-folded', 'Stuart Michael Schmidt, Jr.'),
  ('ff54c638-c2bb-4b1f-8973-b71974c50d1a', '446e0f44-f36d-41ae-b6e7-92add4844960', 'State Legislative Subdistrict 33A', 'Delegate', 1, '20261103MD22912', '122952', 'Andrew C. Pruski', 'Andrew', 'Pruski', false, true, 'Dem', 0, 0, true, true, 'won', 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid, 'holder-exact-full-name', 'Andrew C. Pruski'),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '173675', 'Joan Barone Cole', 'Joan', 'Barone Cole', false, false, 'Dem', 24431, 16.2, false, false, NULL, NULL, NULL, NULL),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '173677', 'Heidi Buchanan Schmidt', 'Heidi', 'Buchanan Schmidt', false, false, 'Dem', 24658, 16.35, false, false, NULL, NULL, NULL, NULL),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '173680', 'Ryan Kelly Shaban', 'Ryan', 'Shaban', false, false, 'Dem', 22998, 15.25, false, false, NULL, NULL, NULL, NULL),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '173681', 'LaToya Marie Caldwell-Nkongolo', 'LaToya', 'Caldwell-Nkongolo', false, true, 'GOP', 24926, 16.52, false, false, NULL, NULL, NULL, NULL),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '121343', 'Brian A. Chisholm', 'Brian', 'Chisholm', false, true, 'GOP', 27473, 18.21, false, false, NULL, 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid, 'holder-exact-first-last', 'Brian Chisholm'),
  ('99279f26-a63a-42be-bb19-ce239844eb60', 'd1fe529b-3567-4675-af1f-4174f398ef5a', 'State Legislative District 31', 'Delegate', 3, '20261103MD22159', '173683', 'Mike Jacobs', 'Mike', 'Jacobs', false, false, 'GOP', 26353, 17.47, false, false, NULL, NULL, NULL, NULL),
  ('713f1e08-6024-475c-8f65-1439357dc5e1', '1af19bbc-4a4d-4dc7-b564-2892c0b356d6', 'State Legislative Subdistrict 30B', 'Delegate', 1, '20261103MD22788', '173669', 'Matt Johnston', 'Matt', 'Johnston', false, false, 'Dem', 9043, 48.25, false, true, 'lost', NULL, NULL, NULL),
  ('713f1e08-6024-475c-8f65-1439357dc5e1', '1af19bbc-4a4d-4dc7-b564-2892c0b356d6', 'State Legislative Subdistrict 30B', 'Delegate', 1, '20261103MD22788', '120610', 'Seth Howard', 'Seth', 'Howard', false, true, 'GOP', 9700, 51.75, false, true, 'won', '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid, 'holder-exact-first-last', 'Seth A. Howard'),
  ('5bdf52d6-d9e7-48f2-8739-8c791e3d9a26', '04771969-dba3-4a5b-96a3-0903e9d24910', 'State Legislative Subdistrict 30A', 'Delegate', 2, '20261103MD22787', '173652', 'Dylan Behler', 'Dylan', 'Behler', false, true, 'Dem', 0, 0, true, true, 'won', '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid, 'holder-exact-full-name', 'Dylan Behler'),
  ('5bdf52d6-d9e7-48f2-8739-8c791e3d9a26', '04771969-dba3-4a5b-96a3-0903e9d24910', 'State Legislative Subdistrict 30A', 'Delegate', 2, '20261103MD22787', '122585', 'Dana Jones', 'Dana', 'Jones', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('f6f16ab6-33b2-4aec-8cff-168e0967307b', 'e738df23-e9e2-419e-94e5-3ab59b6ee2af', 'State Legislative Subdistrict 29C', 'Delegate', 1, '20261103MD22210', '173650', 'Shaara Watts', 'Shaara', 'Watts', false, false, 'Dem', 8386, 43.68, false, true, 'lost', NULL, NULL, NULL),
  ('f6f16ab6-33b2-4aec-8cff-168e0967307b', 'e738df23-e9e2-419e-94e5-3ab59b6ee2af', 'State Legislative Subdistrict 29C', 'Delegate', 1, '20261103MD22210', '122620', 'Todd B. Morgan', 'Todd', 'Morgan', false, true, 'GOP', 10811, 56.32, false, true, 'won', '7d79931f-101c-415b-a6a0-b7a919f70905'::uuid, 'holder-exact-full-name', 'Todd B. Morgan'),
  ('454f9950-60fe-475e-a60b-8e23cd98670e', 'cbf4386d-2f9a-4b0a-b3e7-993ce8339c3b', 'State Legislative Subdistrict 29B', 'Delegate', 1, '20261103MD22187', '173640', 'Adrianne M. Mathis', 'Adrianne', 'Mathis', false, false, 'Dem', 7973, 59.71, false, true, 'won', NULL, NULL, NULL),
  ('454f9950-60fe-475e-a60b-8e23cd98670e', 'cbf4386d-2f9a-4b0a-b3e7-993ce8339c3b', 'State Legislative Subdistrict 29B', 'Delegate', 1, '20261103MD22187', '173642', 'BJ Hall', 'BJ', 'Hall', false, false, 'GOP', 5379, 40.29, false, true, 'lost', NULL, NULL, NULL),
  ('11ed05f0-fed8-4ee7-8aa4-ad4268db034b', 'e357be2a-eb0a-4cb0-a91e-8ba64c1085a6', 'State Legislative Subdistrict 29A', 'Delegate', 1, '20261103MD22181', '173638', 'Jennifer Lynn Clancy', 'Jennifer', 'Clancy', false, false, 'Dem', 6324, 35.07, false, true, 'lost', NULL, NULL, NULL),
  ('11ed05f0-fed8-4ee7-8aa4-ad4268db034b', 'e357be2a-eb0a-4cb0-a91e-8ba64c1085a6', 'State Legislative Subdistrict 29A', 'Delegate', 1, '20261103MD22181', '120375', 'Matt Morgan', 'Matt', 'Morgan', false, true, 'GOP', 11709, 64.93, false, true, 'won', 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid, 'holder-surname-plus-roster', 'Matthew Morgan'),
  ('6b40fc4a-60e5-4328-8db1-7eb8a798a961', 'a645a828-f92a-4950-8d79-3b21b2731961', 'State Legislative District 28', 'Delegate', 3, '20261103MD22180', '173624', 'Abena Affum-McAllister', 'Abena', 'Affum-McAllister', false, false, 'Dem', 39150, 27.49, false, true, 'won', NULL, NULL, NULL),
  ('6b40fc4a-60e5-4328-8db1-7eb8a798a961', 'a645a828-f92a-4950-8d79-3b21b2731961', 'State Legislative District 28', 'Delegate', 3, '20261103MD22180', '66991', 'Debra Davis', 'Debra', 'Davis', false, true, 'Dem', 40174, 28.2, false, true, 'won', '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid, 'holder-exact-full-name', 'Debra Davis'),
  ('6b40fc4a-60e5-4328-8db1-7eb8a798a961', 'a645a828-f92a-4950-8d79-3b21b2731961', 'State Legislative District 28', 'Delegate', 3, '20261103MD22180', '121311', 'Edith J. Patterson', 'Edith', 'Patterson', false, true, 'Dem', 37853, 26.58, false, true, 'won', NULL, NULL, NULL),
  ('6b40fc4a-60e5-4328-8db1-7eb8a798a961', 'a645a828-f92a-4950-8d79-3b21b2731961', 'State Legislative District 28', 'Delegate', 3, '20261103MD22180', '122936', 'James Emerson Ashburn', 'James', 'Ashburn', false, false, 'GOP', 12985, 9.12, false, true, 'lost', NULL, NULL, NULL),
  ('6b40fc4a-60e5-4328-8db1-7eb8a798a961', 'a645a828-f92a-4950-8d79-3b21b2731961', 'State Legislative District 28', 'Delegate', 3, '20261103MD22180', '173634', 'Winfield W. Clark Jr.', 'Winfield', 'Clark', false, false, 'GOP', 12275, 8.62, false, true, 'lost', NULL, NULL, NULL),
  ('f9b90ebc-ad66-43c0-92a7-4b0a5c692337', '1b47226e-e815-437f-aec4-fa4dfee69c99', 'State Legislative Subdistrict 27C', 'Delegate', 1, '20261103MD22802', '173621', 'Jennifer M. Davidson', 'Jennifer', 'Davidson', false, false, 'Dem', 9011, 45.37, false, true, 'lost', NULL, NULL, NULL),
  ('f9b90ebc-ad66-43c0-92a7-4b0a5c692337', '1b47226e-e815-437f-aec4-fa4dfee69c99', 'State Legislative Subdistrict 27C', 'Delegate', 1, '20261103MD22802', '120083', 'Mark Fisher', 'Mark', 'Fisher', false, true, 'GOP', 10852, 54.63, false, true, 'won', '71542618-59c8-4b06-a765-e3df60cca763'::uuid, 'holder-exact-first-last', 'Mark N. Fisher'),
  ('22bbc17b-110d-42a7-9bab-cb28d9f31a27', '238e6cf6-a265-48c1-be42-8556d4c989ff', 'State Legislative Subdistrict 27B', 'Delegate', 1, '20261103MD22207', '122931', 'Jeffrie E. Long Jr.', 'Jeffrie', 'Long', false, true, 'Dem', 13982, 68.63, false, true, 'won', '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid, 'holder-exact-full-name', 'Jeffrie E. Long, Jr.'),
  ('22bbc17b-110d-42a7-9bab-cb28d9f31a27', '238e6cf6-a265-48c1-be42-8556d4c989ff', 'State Legislative Subdistrict 27B', 'Delegate', 1, '20261103MD22207', '173620', 'Dan L. Thomas', 'Dan', 'Thomas', false, false, 'GOP', 6391, 31.37, false, true, 'lost', NULL, NULL, NULL),
  ('fb4a6bce-f8c7-4f0d-8154-c96c1ffa5f79', '3fbcee6e-2972-4c85-8d74-ead4cfb946ed', 'State Legislative Subdistrict 27A', 'Delegate', 1, '20261103MD22157', '173582', 'Darrell C. Odom Sr.', 'Darrell', 'Odom', false, true, 'Dem', 15221, 85.62, false, true, 'won', '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid, 'holder-exact-first-last', 'Darrell Odom'),
  ('fb4a6bce-f8c7-4f0d-8154-c96c1ffa5f79', '3fbcee6e-2972-4c85-8d74-ead4cfb946ed', 'State Legislative Subdistrict 27A', 'Delegate', 1, '20261103MD22157', '121314', 'Jim Crawford', 'Jim', 'Crawford', false, false, 'GOP', 2557, 14.38, false, true, 'lost', NULL, NULL, NULL),
  ('ac9cd01c-0a93-48e8-8ec1-9f6f695dda2b', 'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', 'State Legislative District 26', 'Delegate', 3, '20261103MD22156', '54706', 'Veronica Turner', 'Veronica', 'Turner', false, true, 'Dem', 37433, 33.55, false, true, 'won', '7a76712a-38cd-41de-b260-cd0127284f16'::uuid, 'holder-exact-full-name', 'Veronica Turner'),
  ('ac9cd01c-0a93-48e8-8ec1-9f6f695dda2b', 'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', 'State Legislative District 26', 'Delegate', 3, '20261103MD22156', '120118', 'Kriselda Valderrama', 'Kriselda', 'Valderrama', false, true, 'Dem', 33805, 30.3, false, true, 'won', NULL, NULL, NULL),
  ('ac9cd01c-0a93-48e8-8ec1-9f6f695dda2b', 'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', 'State Legislative District 26', 'Delegate', 3, '20261103MD22156', '122013', 'Jamila J. Woods', 'Jamila', 'Woods', false, true, 'Dem', 35613, 31.92, false, true, 'won', NULL, NULL, NULL),
  ('ac9cd01c-0a93-48e8-8ec1-9f6f695dda2b', 'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', 'State Legislative District 26', 'Delegate', 3, '20261103MD22156', '173578', 'JoAnn Y. Fisher', 'JoAnn', 'Fisher', false, false, 'GOP', 2504, 2.24, false, true, 'lost', NULL, NULL, NULL),
  ('ac9cd01c-0a93-48e8-8ec1-9f6f695dda2b', 'a7c1f3b2-2e7c-4374-9ae0-7db4b9f11b9a', 'State Legislative District 26', 'Delegate', 3, '20261103MD22156', '122008', 'Ike Puzon', 'Ike', 'Puzon', false, false, 'GOP', 2208, 1.98, false, true, 'lost', NULL, NULL, NULL),
  ('49f42039-94c1-4ae7-bceb-d872f6fb16bb', '70130202-21d0-4ff3-927d-976492f1fd74', 'State Legislative District 25', 'Delegate', 3, '20261103MD22155', '122222', 'Kent Roberson', 'Kent', 'Roberson', false, true, 'Dem', 0, 0, true, true, 'won', '338210ee-b9ab-4820-bfce-98f5354837af'::uuid, 'holder-exact-full-name', 'Kent Roberson'),
  ('49f42039-94c1-4ae7-bceb-d872f6fb16bb', '70130202-21d0-4ff3-927d-976492f1fd74', 'State Legislative District 25', 'Delegate', 3, '20261103MD22155', '173572', 'Denise Roberts', 'Denise', 'Roberts', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('49f42039-94c1-4ae7-bceb-d872f6fb16bb', '70130202-21d0-4ff3-927d-976492f1fd74', 'State Legislative District 25', 'Delegate', 3, '20261103MD22155', '122908', 'Karen Toles', 'Karen', 'Toles', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('53709198-5a8a-4ec5-a0af-e9782502f8de', 'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', 'State Legislative District 24', 'Delegate', 3, '20261103MD22154', '173568', 'Derrick L. Coley', 'Derrick', 'Coley', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('53709198-5a8a-4ec5-a0af-e9782502f8de', 'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', 'State Legislative District 24', 'Delegate', 3, '20261103MD22154', '173569', 'Andrea Fletcher Harrison', 'Andrea', 'Fletcher Harrison', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('53709198-5a8a-4ec5-a0af-e9782502f8de', 'e30a0a5e-1d1e-464b-a70f-8d8eb8979f26', 'State Legislative District 24', 'Delegate', 3, '20261103MD22154', '122215', 'LaTasha R. Ward', 'LaTasha', 'Ward', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('7986a09c-3d62-4f41-ac86-fb55905ffc51', 'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'State Legislative District 23', 'Delegate', 3, '20261103MD22909', '54697', 'Marvin E. Holmes Jr.', 'Marvin', 'Holmes', false, true, 'Dem', 45620, 31.9, false, true, 'won', NULL, NULL, NULL),
  ('7986a09c-3d62-4f41-ac86-fb55905ffc51', 'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'State Legislative District 23', 'Delegate', 3, '20261103MD22909', '122889', 'Keenon James', 'Keenon', 'James', false, false, 'Dem', 43023, 30.08, false, true, 'won', NULL, NULL, NULL),
  ('7986a09c-3d62-4f41-ac86-fb55905ffc51', 'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'State Legislative District 23', 'Delegate', 3, '20261103MD22909', '122893', 'Kym Taylor', 'Kym', 'Taylor', false, true, 'Dem', 44090, 30.83, false, true, 'won', NULL, NULL, NULL),
  ('7986a09c-3d62-4f41-ac86-fb55905ffc51', 'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'State Legislative District 23', 'Delegate', 3, '20261103MD22909', '173565', 'Michael Riker', 'Michael', 'Riker', false, false, 'GOP', 5137, 3.59, false, true, 'lost', NULL, NULL, NULL),
  ('7986a09c-3d62-4f41-ac86-fb55905ffc51', 'f959c581-ce74-491e-9cb5-e27fc81cbd01', 'State Legislative District 23', 'Delegate', 3, '20261103MD22909', '173566', 'Kimberly Simmons Robinson', 'Kimberly', 'Simmons Robinson', false, false, 'GOP', 5140, 3.59, false, true, 'lost', NULL, NULL, NULL),
  ('f2e6be74-699b-4ee4-b321-a776b3e6d93f', 'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'State Legislative District 22', 'Delegate', 3, '20261103MD22389', '173557', 'Tracy Gant', 'Tracy', 'Gant', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('f2e6be74-699b-4ee4-b321-a776b3e6d93f', 'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'State Legislative District 22', 'Delegate', 3, '20261103MD22389', '121997', 'Ashanti Martinez', 'Ashanti', 'Martinez', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('f2e6be74-699b-4ee4-b321-a776b3e6d93f', 'e2c83e12-9a12-4acf-b55d-25f6753bc8d6', 'State Legislative District 22', 'Delegate', 3, '20261103MD22389', '173559', 'Molly McKee-Seabrook', 'Molly', 'McKee-Seabrook', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('efe65f80-d0c4-4815-beb6-b4cad176cfe6', '4de4d6bc-c24c-44dc-ae7d-f39d1732bd8d', 'State Legislative District 21', 'Delegate', 3, '20261103MD22151', '120111', 'Ben Barnes', 'Ben', 'Barnes', false, true, 'Dem', 0, 0, true, true, 'won', '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid, 'holder-exact-full-name', 'Ben Barnes'),
  ('efe65f80-d0c4-4815-beb6-b4cad176cfe6', '4de4d6bc-c24c-44dc-ae7d-f39d1732bd8d', 'State Legislative District 21', 'Delegate', 3, '20261103MD22151', '122193', 'Mary A. Lehman', 'Mary', 'Lehman', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('efe65f80-d0c4-4815-beb6-b4cad176cfe6', '4de4d6bc-c24c-44dc-ae7d-f39d1732bd8d', 'State Legislative District 21', 'Delegate', 3, '20261103MD22151', '64812', 'Joseline A. Peña-Melnyk', 'Joseline', 'Peña-Melnyk', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('e5fd9bff-1db9-4e37-81a9-dd5bbc6fd733', 'ce7eef8b-bd6e-41e0-816c-fbff5d310699', 'State Legislative District 20', 'Delegate', 3, '20261103MD22150', '122186', 'Lorig Charkoudian', 'Lorig', 'Charkoudian', false, true, 'Dem', 0, 0, true, true, 'won', '9c5e1ac7-8a39-4c6e-8b20-0788a92f8607'::uuid, 'holder-exact-full-name', 'Lorig Charkoudian'),
  ('e5fd9bff-1db9-4e37-81a9-dd5bbc6fd733', 'ce7eef8b-bd6e-41e0-816c-fbff5d310699', 'State Legislative District 20', 'Delegate', 3, '20261103MD22150', '121234', 'David Moon', 'David', 'Moon', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('e5fd9bff-1db9-4e37-81a9-dd5bbc6fd733', 'ce7eef8b-bd6e-41e0-816c-fbff5d310699', 'State Legislative District 20', 'Delegate', 3, '20261103MD22150', '122190', 'Jheanelle K. Wilkins', 'Jheanelle', 'Wilkins', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('0148179c-84e9-49c9-8b8e-3a83b5833134', 'f1e0b780-b752-4cbd-85ed-065fccd39a78', 'State Legislative District 19', 'Delegate', 3, '20261103MD22149', '121226', 'Charlotte Crutchfield', 'Charlotte', 'Crutchfield', false, true, 'Dem', 0, 0, true, true, 'won', '98d6a17e-59dc-4d11-a342-869603862f10'::uuid, 'holder-exact-full-name', 'Charlotte Crutchfield'),
  ('0148179c-84e9-49c9-8b8e-3a83b5833134', 'f1e0b780-b752-4cbd-85ed-065fccd39a78', 'State Legislative District 19', 'Delegate', 3, '20261103MD22149', '122182', 'Vaughn Stewart', 'Vaughn', 'Stewart', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('0148179c-84e9-49c9-8b8e-3a83b5833134', 'f1e0b780-b752-4cbd-85ed-065fccd39a78', 'State Legislative District 19', 'Delegate', 3, '20261103MD22149', '173556', 'Christa Tichy', 'Christa', 'Tichy', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('763b5b43-6c0d-456f-afaa-4f437177cf2a', '4984e70f-5313-4313-a658-65e38cc228ec', 'State Legislative District 18', 'Delegate', 3, '20261103MD22148', '122879', 'Aaron M. Kaufman', 'Aaron', 'Kaufman', false, true, 'Dem', 0, 0, true, true, 'won', 'bc703231-6af8-48c6-8ae6-4a93fc60b18f'::uuid, 'holder-exact-full-name', 'Aaron M. Kaufman'),
  ('763b5b43-6c0d-456f-afaa-4f437177cf2a', '4984e70f-5313-4313-a658-65e38cc228ec', 'State Legislative District 18', 'Delegate', 3, '20261103MD22148', '121220', 'Emily Shetty', 'Emily', 'Shetty', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('763b5b43-6c0d-456f-afaa-4f437177cf2a', '4984e70f-5313-4313-a658-65e38cc228ec', 'State Legislative District 18', 'Delegate', 3, '20261103MD22148', '122174', 'Jared Solomon', 'Jared', 'Solomon', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('a2e065e6-182f-4362-8ce3-009485768a58', '40a3e126-e06d-4e63-acc8-924512a7e643', 'State Legislative District 17', 'Delegate', 3, '20261103MD22147', '122166', 'Julie Palakovich Carr', 'Julie', 'Palakovich Carr', false, true, 'Dem', 0, 0, true, true, 'won', '70d58d4b-4203-4fc2-b36f-32e6231c4339'::uuid, 'holder-exact-full-name', 'Julie Palakovich Carr'),
  ('a2e065e6-182f-4362-8ce3-009485768a58', '40a3e126-e06d-4e63-acc8-924512a7e643', 'State Legislative District 17', 'Delegate', 3, '20261103MD22147', '173550', 'Ryan Spiegel', 'Ryan', 'Spiegel', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('a2e065e6-182f-4362-8ce3-009485768a58', '40a3e126-e06d-4e63-acc8-924512a7e643', 'State Legislative District 17', 'Delegate', 3, '20261103MD22147', '122876', 'Joe Vogel', 'Joe', 'Vogel', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('3f6e01ce-b7b9-4e06-94a4-ecc646c03107', 'ca7b3ffe-3345-4b52-8a79-0e1b703be635', 'State Legislative District 16', 'Delegate', 3, '20261103MD22146', '121197', 'Marc Korman', 'Marc', 'Korman', false, true, 'Dem', 40768, 31.1, false, true, 'won', 'e76d0654-b0c6-43dc-9159-e929e480d070'::uuid, 'holder-exact-full-name', 'Marc Korman'),
  ('3f6e01ce-b7b9-4e06-94a4-ecc646c03107', 'ca7b3ffe-3345-4b52-8a79-0e1b703be635', 'State Legislative District 16', 'Delegate', 3, '20261103MD22146', '173546', 'Sarah Wolek', 'Sarah', 'Wolek', false, true, 'Dem', 39981, 30.5, false, true, 'won', NULL, NULL, NULL),
  ('3f6e01ce-b7b9-4e06-94a4-ecc646c03107', 'ca7b3ffe-3345-4b52-8a79-0e1b703be635', 'State Legislative District 16', 'Delegate', 3, '20261103MD22146', '173547', 'Teresa Saavedra Woorman', 'Teresa', 'Woorman', false, true, 'Dem', 37480, 28.59, false, true, 'won', NULL, NULL, NULL),
  ('3f6e01ce-b7b9-4e06-94a4-ecc646c03107', 'ca7b3ffe-3345-4b52-8a79-0e1b703be635', 'State Legislative District 16', 'Delegate', 3, '20261103MD22146', '173548', 'Ann Guthrie Hingston', 'Ann', 'Hingston', false, false, 'GOP', 9997, 7.63, false, true, 'lost', NULL, NULL, NULL),
  ('3f6e01ce-b7b9-4e06-94a4-ecc646c03107', 'ca7b3ffe-3345-4b52-8a79-0e1b703be635', 'State Legislative District 16', 'Delegate', 3, '20261103MD22146', '178529', 'Bob White', 'Bob', 'White', false, false, 'WCP', 2866, 2.19, false, true, 'lost', NULL, NULL, NULL),
  ('207e12f2-f0f8-421c-ac00-80c7aaa3b066', '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'State Legislative District 15', 'Delegate', 3, '20261103MD22145', '122869', 'Linda Foley', 'Linda', 'Foley', false, true, 'Dem', 34266, 31.08, false, true, 'won', 'b80a680a-9f79-4d56-994b-00ce24ec7ef3'::uuid, 'holder-exact-full-name', 'Linda Foley'),
  ('207e12f2-f0f8-421c-ac00-80c7aaa3b066', '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'State Legislative District 15', 'Delegate', 3, '20261103MD22145', '120560', 'David V. Fraser-Hidalgo', 'David', 'Fraser-Hidalgo', false, true, 'Dem', 32222, 29.23, false, true, 'won', NULL, NULL, NULL),
  ('207e12f2-f0f8-421c-ac00-80c7aaa3b066', '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'State Legislative District 15', 'Delegate', 3, '20261103MD22145', '122152', 'Lily Qi', 'Lily', 'Qi', false, true, 'Dem', 32536, 29.51, false, true, 'won', NULL, NULL, NULL),
  ('207e12f2-f0f8-421c-ac00-80c7aaa3b066', '0aeb08e5-41bd-41f2-9935-7303dfb02dee', 'State Legislative District 15', 'Delegate', 3, '20261103MD22145', '173544', 'Peter Chan', 'Peter', 'Chan', false, false, 'GOP', 11230, 10.19, false, true, 'lost', NULL, NULL, NULL),
  ('868fe012-73d0-4ec2-95f9-70c8a15418ba', '1ee9cdb3-7faf-4a70-8356-0c932c9c8f34', 'State Legislative District 14', 'Delegate', 3, '20261103MD22388', '54670', 'Anne R. Kaiser', 'Anne', 'Kaiser', false, true, 'Dem', 0, 0, true, true, 'won', 'bfd0f15f-abb1-4d28-b1f4-e06875adce16'::uuid, 'holder-exact-full-name', 'Anne R. Kaiser'),
  ('868fe012-73d0-4ec2-95f9-70c8a15418ba', '1ee9cdb3-7faf-4a70-8356-0c932c9c8f34', 'State Legislative District 14', 'Delegate', 3, '20261103MD22388', '173541', 'Bernice Mireku-North', 'Bernice', 'Mireku-North', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('868fe012-73d0-4ec2-95f9-70c8a15418ba', '1ee9cdb3-7faf-4a70-8356-0c932c9c8f34', 'State Legislative District 14', 'Delegate', 3, '20261103MD22388', '173542', 'Matt Post', 'Matt', 'Post', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('3322037a-cdbd-40ca-9afd-66884f575fb9', '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'State Legislative District 13', 'Delegate', 3, '20261103MD22387', '122846', 'Amy Brooks', 'Amy', 'Brooks', false, false, 'Dem', 40467, 32.7, false, true, 'won', NULL, NULL, NULL),
  ('3322037a-cdbd-40ca-9afd-66884f575fb9', '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'State Legislative District 13', 'Delegate', 3, '20261103MD22387', '122847', 'Pam Lanman Guzzone', 'Pam', 'Guzzone', false, true, 'Dem', 36143, 29.2, false, true, 'won', '589ed7af-602a-4ec9-8072-448b05446772'::uuid, 'holder-exact-full-name', 'Pam Lanman Guzzone'),
  ('3322037a-cdbd-40ca-9afd-66884f575fb9', '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'State Legislative District 13', 'Delegate', 3, '20261103MD22387', '173539', 'Gabriel Maximilian Moreno', 'Gabriel', 'Moreno', false, true, 'Dem', 35933, 29.04, false, true, 'won', NULL, NULL, NULL),
  ('3322037a-cdbd-40ca-9afd-66884f575fb9', '072a4ac6-ba14-403a-8c91-eb8295d8155b', 'State Legislative District 13', 'Delegate', 3, '20261103MD22387', '120083', 'Mark Fisher', 'Mark', 'Fisher', false, false, 'GOP', 11214, 9.06, false, true, 'lost', NULL, NULL, NULL),
  ('6ea9911b-4c3c-413c-bf01-e131f673400f', '467327cd-a27c-4e26-9574-f802d34cbe95', 'State Legislative Subdistrict 12B', 'Delegate', 1, '20261103MD22205', '122842', 'Gary Simmons', 'Gary', 'Simmons', false, true, 'Dem', 7936, 64.55, false, true, 'won', '69cbeb94-6978-4f3f-b8b7-735f789c6d3c'::uuid, 'holder-exact-full-name', 'Gary Simmons'),
  ('6ea9911b-4c3c-413c-bf01-e131f673400f', '467327cd-a27c-4e26-9574-f802d34cbe95', 'State Legislative Subdistrict 12B', 'Delegate', 1, '20261103MD22205', '173536', 'Blair L. Brannock', 'Blair', 'Brannock', false, false, 'GOP', 4359, 35.45, false, true, 'lost', NULL, NULL, NULL),
  ('451d87fd-802c-49e5-8e0c-7875ec0102af', '117ea3a2-17e5-4ce3-bb84-b42d54b6a628', 'State Legislative Subdistrict 12A', 'Delegate', 2, '20261103MD22144', '122133', 'Jessica Feldmark', 'Jessica', 'Feldmark', false, true, 'Dem', 27283, 46.05, false, true, 'won', 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid, 'holder-exact-full-name', 'Jessica Feldmark'),
  ('451d87fd-802c-49e5-8e0c-7875ec0102af', '117ea3a2-17e5-4ce3-bb84-b42d54b6a628', 'State Legislative Subdistrict 12A', 'Delegate', 2, '20261103MD22144', '71834', 'Terri Hill', 'Terri', 'Hill', false, true, 'Dem', 24769, 41.8, false, true, 'won', NULL, NULL, NULL),
  ('451d87fd-802c-49e5-8e0c-7875ec0102af', '117ea3a2-17e5-4ce3-bb84-b42d54b6a628', 'State Legislative Subdistrict 12A', 'Delegate', 2, '20261103MD22144', '173535', 'Frank Glover', 'Frank', 'Glover', false, false, 'GOP', 7200, 12.15, false, true, 'lost', NULL, NULL, NULL),
  ('72fffea6-1d39-49db-b5c4-4f875d9d86a2', 'a88be23e-bbd9-4703-bf76-7877f179e131', 'State Legislative Subdistrict 11B', 'Delegate', 2, '20261103MD84780', '54663', 'Jon S. Cardin', 'Jon', 'Cardin', false, true, 'Dem', 23970, 42.72, false, true, 'won', '631dac5c-fb86-41f5-a82d-5963164a9142'::uuid, 'holder-exact-full-name', 'Jon S. Cardin'),
  ('72fffea6-1d39-49db-b5c4-4f875d9d86a2', 'a88be23e-bbd9-4703-bf76-7877f179e131', 'State Legislative Subdistrict 11B', 'Delegate', 2, '20261103MD84780', '120094', 'Dana Stein', 'Dana', 'Stein', false, true, 'Dem', 21900, 39.04, false, true, 'won', NULL, NULL, NULL),
  ('72fffea6-1d39-49db-b5c4-4f875d9d86a2', 'a88be23e-bbd9-4703-bf76-7877f179e131', 'State Legislative Subdistrict 11B', 'Delegate', 2, '20261103MD84780', '173533', 'John C. Gordon', 'John', 'Gordon', false, false, 'GOP', 10233, 18.24, false, true, 'lost', NULL, NULL, NULL),
  ('12aff572-e773-4550-a50f-6e31dd4c2246', '65b9821b-ecf8-4fa9-af00-044904170f2a', 'State Legislative Subdistrict 11A', 'Delegate', 1, '20261103MD22143', '122827', 'Cheryl E. Pasteur', 'Cheryl', 'Pasteur', false, true, 'Dem', 0, 0, true, true, 'won', 'b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid, 'holder-exact-full-name', 'Cheryl E. Pasteur'),
  ('6bfc5ee3-63b3-4fae-9733-f846994643d3', 'a7f0b89f-ba30-4e14-954e-cf402194303d', 'State Legislative District 10', 'Delegate', 3, '20261103MD22142', '173530', 'Robin Harvey', 'Robin', 'Harvey', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('6bfc5ee3-63b3-4fae-9733-f846994643d3', 'a7f0b89f-ba30-4e14-954e-cf402194303d', 'State Legislative District 10', 'Delegate', 3, '20261103MD22142', '122824', 'N. Scott Phillips', 'N.', 'Phillips', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('6bfc5ee3-63b3-4fae-9733-f846994643d3', 'a7f0b89f-ba30-4e14-954e-cf402194303d', 'State Legislative District 10', 'Delegate', 3, '20261103MD22142', '122825', 'Jennifer White Holland', 'Jennifer', 'White Holland', false, true, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('2d29bbde-405c-4b9e-b9b2-d344556ccb71', 'b1112077-bdb6-4726-b5bc-1590ed1831e1', 'State Legislative Subdistrict 9B', 'Delegate', 1, '20261103MD22204', '121518', 'Courtney Watson', 'Courtney', 'Watson', false, true, 'Dem', 0, 0, true, true, 'won', 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid, 'holder-exact-full-name', 'Courtney Watson'),
  ('a0b52691-5f93-4852-9299-4db4e68f7501', 'd3550c38-2ebe-41d2-b06a-59fad7901015', 'State Legislative Subdistrict 9A', 'Delegate', 2, '20261103MD22203', '122809', 'Chao Wu', 'Chao', 'Wu', false, true, 'Dem', 21396, 31.35, false, true, 'won', '7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid, 'holder-exact-full-name', 'Chao Wu'),
  ('a0b52691-5f93-4852-9299-4db4e68f7501', 'd3550c38-2ebe-41d2-b06a-59fad7901015', 'State Legislative Subdistrict 9A', 'Delegate', 2, '20261103MD22203', '122118', 'Natalie Ziegler', 'Natalie', 'Ziegler', false, true, 'Dem', 20951, 30.7, false, true, 'won', NULL, NULL, NULL),
  ('a0b52691-5f93-4852-9299-4db4e68f7501', 'd3550c38-2ebe-41d2-b06a-59fad7901015', 'State Legislative Subdistrict 9A', 'Delegate', 2, '20261103MD22203', '173527', 'Fitzgerald Mofor', 'Fitzgerald', 'Mofor', false, false, 'GOP', 11908, 17.45, false, true, 'lost', NULL, NULL, NULL),
  ('a0b52691-5f93-4852-9299-4db4e68f7501', 'd3550c38-2ebe-41d2-b06a-59fad7901015', 'State Legislative Subdistrict 9A', 'Delegate', 2, '20261103MD22203', '173528', 'Spencer Rhoda', 'Spencer', 'Rhoda', false, false, 'GOP', 11503, 16.86, false, true, 'lost', NULL, NULL, NULL),
  ('a0b52691-5f93-4852-9299-4db4e68f7501', 'd3550c38-2ebe-41d2-b06a-59fad7901015', 'State Legislative Subdistrict 9A', 'Delegate', 2, '20261103MD22203', '122804', 'Saif Rehman', 'Saif', 'Rehman', false, false, 'Una', 2487, 3.64, false, true, 'lost', NULL, NULL, NULL),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '122803', 'Nick Allen', 'Nick', 'Allen', false, true, 'Dem', 24694, 23.43, false, true, 'won', 'a1f58b34-76ee-43ce-b152-4843c42f4f79'::uuid, 'holder-exact-full-name', 'Nick Allen'),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '121104', 'Harry Bhandari', 'Harry', 'Bhandari', false, true, 'Dem', 24278, 23.04, false, true, 'won', NULL, NULL, NULL),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '173523', 'Kim L. Ross', 'Kim', 'Ross', false, true, 'Dem', 24081, 22.85, false, true, 'won', NULL, NULL, NULL),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '173524', 'Brian A. Campbell', 'Brian', 'Campbell', false, false, 'GOP', 11453, 10.87, false, true, 'lost', NULL, NULL, NULL),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '123049', 'Glen Geelhaar', 'Glen', 'Geelhaar', false, false, 'GOP', 10475, 9.94, false, true, 'lost', NULL, NULL, NULL),
  ('fd554d10-cbfb-46f8-8a5d-ab5a2981d0cf', '346c6035-4668-427f-96ad-afd832484ad3', 'State Legislative District 8', 'Delegate', 3, '20261103MD22202', '173525', 'Steven J. Riemer', 'Steven', 'Riemer', false, false, 'GOP', 10405, 9.87, false, true, 'lost', NULL, NULL, NULL),
  ('2151f879-d739-4300-87f1-3dadcdad40ee', 'd5cacb6b-be09-4e81-aa98-d260e3c1ac79', 'State Legislative Subdistrict 7B', 'Delegate', 1, '20261103MD22201', '173520', 'Candace Hart', 'Candace', 'Hart', false, false, 'Dem', 7893, 39.08, false, true, 'lost', NULL, NULL, NULL),
  ('2151f879-d739-4300-87f1-3dadcdad40ee', 'd5cacb6b-be09-4e81-aa98-d260e3c1ac79', 'State Legislative Subdistrict 7B', 'Delegate', 1, '20261103MD22201', '122089', 'Lauren Arikan', 'Lauren', 'Arikan', false, true, 'GOP', 12304, 60.92, false, true, 'won', '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid, 'holder-exact-full-name', 'Lauren Arikan'),
  ('21d4356d-eb90-41d0-8560-fb3d17e90816', 'dcdd107f-c96f-4087-887f-6071434f0ae3', 'State Legislative Subdistrict 7A', 'Delegate', 2, '20261103MD22177', '173517', 'Ly Xinzhen Brown', 'Ly Xinzhen', 'Brown', false, false, 'Dem', 13697, 21.26, false, true, 'lost', NULL, NULL, NULL),
  ('21d4356d-eb90-41d0-8560-fb3d17e90816', 'dcdd107f-c96f-4087-887f-6071434f0ae3', 'State Legislative Subdistrict 7A', 'Delegate', 2, '20261103MD22177', '173518', 'Satish Chapagain', 'Satish', 'Chapagain', false, false, 'Dem', 13958, 21.66, false, true, 'lost', NULL, NULL, NULL),
  ('21d4356d-eb90-41d0-8560-fb3d17e90816', 'dcdd107f-c96f-4087-887f-6071434f0ae3', 'State Legislative Subdistrict 7A', 'Delegate', 2, '20261103MD22177', '122788', 'Ryan Nawrocki', 'Ryan', 'Nawrocki', false, true, 'GOP', 18590, 28.85, false, true, 'won', 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid, 'holder-exact-full-name', 'Ryan Nawrocki'),
  ('21d4356d-eb90-41d0-8560-fb3d17e90816', 'dcdd107f-c96f-4087-887f-6071434f0ae3', 'State Legislative Subdistrict 7A', 'Delegate', 2, '20261103MD22177', '64775', 'Kathy Szeliga', 'Kathy', 'Szeliga', false, true, 'GOP', 18193, 28.23, false, true, 'won', NULL, NULL, NULL),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '173497', 'Artus W. Huffman', 'Artus', 'Huffman', false, false, 'Dem', 13416, 14.92, false, false, NULL, NULL, NULL, NULL),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '122087', 'Megan Ann Mioduszewski', 'Megan', 'Mioduszewski', false, false, 'Dem', 14096, 15.67, false, false, NULL, NULL, NULL, NULL),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '173498', 'Rayneika Robinson', 'Rayneika', 'Robinson', false, false, 'Dem', 13309, 14.8, false, false, NULL, NULL, NULL, NULL),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '121088', 'Robin L. Grammer', 'Robin', 'Grammer', false, true, 'GOP', 15963, 17.75, false, false, NULL, '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid, 'holder-suffix-folded', 'Robin L. Grammer, Jr.'),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '120537', 'Bob Long', 'Bob', 'Long', false, true, 'GOP', 16993, 18.89, false, false, NULL, NULL, NULL, NULL),
  ('5d4cfcbb-1f29-494c-a01a-943ad624f9a1', '60f53046-9328-495b-bbe7-5947a3ea3ea6', 'State Legislative District 6', 'Delegate', 3, '20261103MD22200', '120086', 'Ric Metzgar', 'Ric', 'Metzgar', false, true, 'GOP', 16167, 17.97, false, false, NULL, NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '173489', 'Dayana Bergman', 'Dayana', 'Bergman', false, false, 'Dem', 21824, 13.97, false, true, 'lost', NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '173490', 'Alison Rudolph', 'Alison', 'Rudolph', false, false, 'Dem', 22565, 14.45, false, true, 'lost', NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '173491', 'Courtney Alexa Welch', 'Courtney', 'Welch', false, false, 'Dem', 20874, 13.36, false, true, 'lost', NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '122340', 'April R. Rose', 'April', 'Rose', false, true, 'GOP', 30606, 19.59, false, true, 'won', NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '122781', 'Chris Tomlinson', 'Chris', 'Tomlinson', false, true, 'GOP', 30786, 19.71, false, true, 'won', NULL, NULL, NULL),
  ('9a6a7c28-faca-43fd-9595-0ede98dd8e03', '9acf873d-3144-4bc0-8c5b-e136bbdbdec2', 'State Legislative District 5', 'Delegate', 3, '20261103MD22800', '173496', 'Steve Whisler', 'Steve', 'Whisler', false, false, 'GOP', 29551, 18.92, false, true, 'won', NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '173479', 'Jerry Donald', 'Jerry', 'Donald', false, false, 'Dem', 29681, 17.7, false, false, NULL, NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '51605', 'Andrew Duck', 'Andrew', 'Duck', false, false, 'Dem', 28890, 17.23, false, false, NULL, NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '173484', 'Alleria Stanley', 'Alleria', 'Stanley', false, false, 'Dem', 27672, 16.5, false, false, NULL, NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '173485', 'Jason E. Keckler', 'Jason', 'Keckler', false, false, 'GOP', 26462, 15.78, false, false, NULL, NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '122770', 'April Fleming Miller', 'April', 'Miller', false, true, 'GOP', 27023, 16.12, false, false, NULL, NULL, NULL, NULL),
  ('ed25b262-4f2e-48c0-98ca-d6a910f18d26', '5fdaeaf6-f145-4fba-b9c9-c67a89b7c749', 'State Legislative District 4', 'Delegate', 3, '20261103MD22799', '120958', 'Jesse T. Pippy', 'Jesse', 'Pippy', false, true, 'GOP', 27947, 16.67, false, false, NULL, NULL, NULL, NULL),
  ('26fc0712-940a-4c74-8f9a-cb79263061af', '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', 'State Legislative District 3', 'Delegate', 3, '20261103MD22384', '122765', 'Kris Fair', 'Kris', 'Fair', false, true, 'Dem', 34683, 30.01, false, true, 'won', 'dfb9ae21-4605-4c58-94e8-84b1eb1a30c1'::uuid, 'holder-exact-full-name', 'Kris Fair'),
  ('26fc0712-940a-4c74-8f9a-cb79263061af', '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', 'State Legislative District 3', 'Delegate', 3, '20261103MD22384', '122071', 'Ken Kerr', 'Ken', 'Kerr', false, true, 'Dem', 34131, 29.53, false, true, 'won', NULL, NULL, NULL),
  ('26fc0712-940a-4c74-8f9a-cb79263061af', '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', 'State Legislative District 3', 'Delegate', 3, '20261103MD22384', '122255', 'Karen Simpson', 'Karen', 'Simpson', false, true, 'Dem', 33730, 29.18, false, true, 'won', NULL, NULL, NULL),
  ('26fc0712-940a-4c74-8f9a-cb79263061af', '98ad3ec2-a14b-4ce9-a2c0-c06955caf8b1', 'State Legislative District 3', 'Delegate', 3, '20261103MD22384', '122673', 'Angela McIntosh', 'Angela', 'McIntosh', false, false, 'GOP', 13031, 11.27, false, true, 'lost', NULL, NULL, NULL),
  ('4b3ab024-5fba-4084-95bb-731666973ce0', '775816cb-2d23-42d2-a7d2-83f36eb56b09', 'State Legislative Subdistrict 2B', 'Delegate', 1, '20261103MD22183', '173473', 'Matthew J. Schindler', 'Matthew', 'Schindler', false, true, 'Dem', 6532, 65.87, false, true, 'won', '18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5'::uuid, 'holder-exact-full-name', 'Matthew J. Schindler'),
  ('4b3ab024-5fba-4084-95bb-731666973ce0', '775816cb-2d23-42d2-a7d2-83f36eb56b09', 'State Legislative Subdistrict 2B', 'Delegate', 1, '20261103MD22183', '122756', 'Brenda J. Thiam', 'Brenda', 'Thiam', false, false, 'GOP', 3385, 34.13, false, true, 'lost', NULL, NULL, NULL),
  ('d2cfe243-dfc3-4002-8887-fdabedb991d2', 'ecd872d1-6f97-4a99-afd1-b80fc76d7ced', 'State Legislative Subdistrict 2A', 'Delegate', 2, '20261103MD22176', '122018', 'John D. Leonard', 'John', 'Leonard', false, false, 'Dem', 12716, 20.82, false, true, 'lost', NULL, NULL, NULL),
  ('d2cfe243-dfc3-4002-8887-fdabedb991d2', 'ecd872d1-6f97-4a99-afd1-b80fc76d7ced', 'State Legislative Subdistrict 2A', 'Delegate', 2, '20261103MD22176', '173458', 'Brandon Thompson', 'Brandon', 'Thompson', false, false, 'Dem', 12637, 20.69, false, true, 'lost', NULL, NULL, NULL),
  ('d2cfe243-dfc3-4002-8887-fdabedb991d2', 'ecd872d1-6f97-4a99-afd1-b80fc76d7ced', 'State Legislative Subdistrict 2A', 'Delegate', 2, '20261103MD22176', '122747', 'William Valentine', 'William', 'Valentine', false, true, 'GOP', 17734, 29.03, false, true, 'won', 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid, 'holder-exact-full-name', 'William Valentine'),
  ('d2cfe243-dfc3-4002-8887-fdabedb991d2', 'ecd872d1-6f97-4a99-afd1-b80fc76d7ced', 'State Legislative Subdistrict 2A', 'Delegate', 2, '20261103MD22176', '122060', 'William J. Wivell', 'William', 'Wivell', false, true, 'GOP', 17998, 29.46, false, true, 'won', NULL, NULL, NULL),
  ('917f6a95-aec4-4362-be5d-22841a35bf1b', '1fc5f604-b99a-48cf-bd9f-7e45ad7f7191', 'State Legislative Subdistrict 1C', 'Delegate', 1, '20261103MD22196', '173453', 'Seth Funk', 'Seth', 'Funk', false, false, 'Dem', 4549, 30.76, false, true, 'lost', NULL, NULL, NULL),
  ('917f6a95-aec4-4362-be5d-22841a35bf1b', '1fc5f604-b99a-48cf-bd9f-7e45ad7f7191', 'State Legislative Subdistrict 1C', 'Delegate', 1, '20261103MD22196', '64798', 'Terry Baker', 'Terry', 'Baker', false, true, 'GOP', 10239, 69.24, false, true, 'won', 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid, 'holder-exact-first-last', 'Terry L. Baker'),
  ('63361078-2f07-42c2-82c5-42cd5dd6f14f', 'd046b5c7-b6e8-4166-9547-841494604068', 'State Legislative Subdistrict 1B', 'Delegate', 1, '20261103MD22141', '173451', 'Rhiannon C. Brown', 'Rhiannon', 'Brown', false, false, 'Dem', 6198, 41.36, false, true, 'lost', NULL, NULL, NULL),
  ('63361078-2f07-42c2-82c5-42cd5dd6f14f', 'd046b5c7-b6e8-4166-9547-841494604068', 'State Legislative Subdistrict 1B', 'Delegate', 1, '20261103MD22141', '121024', 'Jason C. Buckel', 'Jason', 'Buckel', false, true, 'GOP', 8789, 58.64, false, true, 'won', '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid, 'holder-exact-full-name', 'Jason C. Buckel'),
  ('fb9be5a9-0e62-47f5-868f-258352d4cf0b', 'be0d2bcf-bc8f-4cd3-bcd3-e09e255dd5f8', 'State Legislative Subdistrict 1A', 'Delegate', 1, '20261103MD22175', '173447', 'Jason M. Jobe', 'Jason', 'Jobe', false, false, 'Dem', 3670, 24.29, false, true, 'lost', NULL, NULL, NULL),
  ('fb9be5a9-0e62-47f5-868f-258352d4cf0b', 'be0d2bcf-bc8f-4cd3-bcd3-e09e255dd5f8', 'State Legislative Subdistrict 1A', 'Delegate', 1, '20261103MD22175', '173449', 'Dan Duggan', 'Dan', 'Duggan', false, false, 'GOP', 11438, 75.71, false, true, 'won', NULL, NULL, NULL),
  ('ceeebfbf-6c9d-4b86-be74-609c28bd7e38', '4281af61-6cf0-48b0-8390-1b8981502683', 'State Senate District 28', 'Senator', 1, '20261103MD22121', '120373', 'C. T. Wilson', 'C. T.', 'Wilson', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('f320bd09-ac45-42d6-b283-c6b80f71d668', '7c79603d-d48c-4b82-bcda-b69559cf0463', 'State Senate District 47', 'Senator', 1, '20261103MD22140', '120900', 'Malcolm Augustine', 'Malcolm', 'Augustine', false, true, 'Dem', 0, 0, true, true, 'won', '9d191d69-084f-4941-bc0a-c59d336f032e'::uuid, 'holder-exact-full-name', 'Malcolm Augustine'),
  ('f47909f4-af8e-48ff-8518-534af7349f56', 'cfe5fa9d-f8a2-434a-bf18-eec753810913', 'State Senate District 46', 'Senator', 1, '20261103MD22139', '120520', 'Bill Ferguson', 'Bill', 'Ferguson', false, true, 'Dem', 28246, 87.86, false, true, 'won', '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid, 'holder-exact-full-name', 'Bill Ferguson'),
  ('f47909f4-af8e-48ff-8518-534af7349f56', 'cfe5fa9d-f8a2-434a-bf18-eec753810913', 'State Senate District 46', 'Senator', 1, '20261103MD22139', '122733', 'Emmanuel Digman', 'Emmanuel', 'Digman', false, false, 'GOP', 3904, 12.14, false, true, 'lost', NULL, NULL, NULL),
  ('4d37f640-b53b-4323-9c5f-608fb17d05bf', '79a31563-0d71-4480-a84b-4a62743d9c43', 'State Senate District 45', 'Senator', 1, '20261103MD22138', '121488', 'Cory V. McCray', 'Cory', 'McCray', false, true, 'Dem', 0, 0, true, true, 'won', '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid, 'holder-exact-full-name', 'Cory V. McCray'),
  ('6b71c20d-0b37-4cc2-83ce-1b92aa1b5b7d', '43cb63a6-b6d5-4514-a7a8-a258ca04c6ad', 'State Senate District 29', 'Senator', 1, '20261103MD22122', '173223', 'Chuck Borges', 'Chuck', 'Borges', false, false, 'Dem', 23103, 45.52, false, true, 'lost', NULL, NULL, NULL),
  ('6b71c20d-0b37-4cc2-83ce-1b92aa1b5b7d', '43cb63a6-b6d5-4514-a7a8-a258ca04c6ad', 'State Senate District 29', 'Senator', 1, '20261103MD22122', '122022', 'Jack Bailey', 'Jack', 'Bailey', false, true, 'GOP', 27655, 54.48, false, true, 'won', '0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid, 'holder-exact-full-name', 'Jack Bailey'),
  ('1bd335b1-56a7-4931-a574-2ed0cf25207e', '9a9438df-fb70-4a7b-8353-b7ef90c74411', 'State Senate District 44', 'Senator', 1, '20261103MD22137', '121482', 'Charles E. Sydnor III', 'Charles', 'Sydnor', false, true, 'Dem', 0, 0, true, true, 'won', '30f96c7e-7bf0-4270-bfbb-ee4c520a7344'::uuid, 'holder-exact-full-name', 'Charles E. Sydnor, III'),
  ('9a9b840d-c339-43f2-aedb-c9899b63a3ab', 'ad3e5fa0-506d-48f7-a7fe-0436b5b7aa76', 'State Senate District 43', 'Senator', 1, '20261103MD22136', '120179', 'Mary Washington', 'Mary', 'Washington', false, true, 'Dem', 0, 0, true, true, 'won', '38404814-7be0-40e3-b044-062f98b2a5b0'::uuid, 'holder-exact-full-name', 'Mary Washington'),
  ('46010171-06d3-4139-be35-b5b88ffe1f48', '6c2421ee-9193-4da2-a95a-447732e29cac', 'State Senate District 42', 'Senator', 1, '20261103MD22135', '173242', 'Stephanie Popescu', 'Stephanie', 'Popescu', false, false, 'Dem', 25712, 46.51, false, true, 'lost', NULL, NULL, NULL),
  ('46010171-06d3-4139-be35-b5b88ffe1f48', '6c2421ee-9193-4da2-a95a-447732e29cac', 'State Senate District 42', 'Senator', 1, '20261103MD22135', '173220', 'Kevin Ford', 'Kevin', 'Ford', false, false, 'GOP', 29576, 53.49, false, true, 'won', NULL, NULL, NULL),
  ('ed689ab2-0770-4fe0-8921-f79c74f90bbd', 'bce321bb-f23c-493a-b24c-9a9a25795bfd', 'State Senate District 41', 'Senator', 1, '20261103MD22134', '173239', 'Malcolm P. Ruff', 'Malcolm', 'Ruff', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('a5c363dd-af64-4943-bd6b-1502661cc0a5', 'ae4911d4-ed3a-49aa-a361-323ddb09b8f8', 'State Senate District 40', 'Senator', 1, '20261103MD22133', '121453', 'Antonio Hayes', 'Antonio', 'Hayes', false, true, 'Dem', 25696, 89.42, false, true, 'won', '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid, 'holder-exact-full-name', 'Antonio Hayes'),
  ('a5c363dd-af64-4943-bd6b-1502661cc0a5', 'ae4911d4-ed3a-49aa-a361-323ddb09b8f8', 'State Senate District 40', 'Senator', 1, '20261103MD22133', '178528', 'Alan Rebar', 'Alan', 'Rebar', false, false, 'WCP', 3039, 10.58, false, true, 'lost', NULL, NULL, NULL),
  ('42e2f012-4e4d-4e43-a917-d95ec308a12b', 'f4b68d2b-ea9a-4259-acd2-3948066a86bb', 'State Senate District 39', 'Senator', 1, '20261103MD22132', '173236', 'Amar Mukunda', 'Amar', 'Mukunda', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('41c711f3-326f-41e2-a547-ad2597f8a78f', 'bab98082-feb9-4305-a9ed-02ca21a2f081', 'State Senate District 38', 'Senator', 1, '20261103MD22131', '173235', 'Lino V. Cressotti', 'Lino', 'Cressotti', false, false, 'Dem', 19462, 38.39, false, true, 'lost', NULL, NULL, NULL),
  ('41c711f3-326f-41e2-a547-ad2597f8a78f', 'bab98082-feb9-4305-a9ed-02ca21a2f081', 'State Senate District 38', 'Senator', 1, '20261103MD22131', '121442', 'Mary Beth Carozza', 'Mary Beth', 'Carozza', false, true, 'GOP', 31238, 61.61, false, true, 'won', '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid, 'holder-exact-full-name', 'Mary Beth Carozza'),
  ('fe5fd89d-1159-4524-aeb4-094cfe150a8f', 'c8959b0e-255f-4019-b1ba-e5efb33eae10', 'State Senate District 37', 'Senator', 1, '20261103MD22130', '173234', 'Katie G. Clendaniel', 'Katie', 'Clendaniel', false, false, 'Dem', 23591, 44.58, false, true, 'lost', NULL, NULL, NULL),
  ('fe5fd89d-1159-4524-aeb4-094cfe150a8f', 'c8959b0e-255f-4019-b1ba-e5efb33eae10', 'State Senate District 37', 'Senator', 1, '20261103MD22130', '121429', 'Johnny Mautz', 'Johnny', 'Mautz', false, true, 'GOP', 29326, 55.42, false, true, 'won', '34c94aa4-11b7-4594-9c3e-c506f10309f6'::uuid, 'holder-exact-full-name', 'Johnny Mautz'),
  ('70a07db3-2bdd-4aa9-916c-2d1e8c0a8733', '51b42be1-dc28-4f2a-b21a-6eb882978a45', 'State Senate District 36', 'Senator', 1, '20261103MD22129', '173231', 'Nivek Johnson', 'Nivek', 'Johnson', false, false, 'Dem', 21145, 40.03, false, true, 'lost', NULL, NULL, NULL),
  ('70a07db3-2bdd-4aa9-916c-2d1e8c0a8733', '51b42be1-dc28-4f2a-b21a-6eb882978a45', 'State Senate District 36', 'Senator', 1, '20261103MD22129', '120619', 'Steve Hershey', 'Steve', 'Hershey', false, true, 'GOP', 31678, 59.97, false, true, 'won', '72287137-7faf-4570-8d9e-c6f8d162f4e0'::uuid, 'holder-surname-plus-roster', 'Stephen S. Hershey, Jr.'),
  ('dd506f33-7364-41d9-8a11-a4c89f81b2bc', 'a2498ff4-ea30-45d3-a5f9-bc282b62261a', 'State Senate District 35', 'Senator', 1, '20261103MD22128', '173230', 'Neil Jennings', 'Neil', 'Jennings', false, false, 'Dem', 18500, 33.34, false, true, 'lost', NULL, NULL, NULL),
  ('dd506f33-7364-41d9-8a11-a4c89f81b2bc', 'a2498ff4-ea30-45d3-a5f9-bc282b62261a', 'State Senate District 35', 'Senator', 1, '20261103MD22128', '120395', 'Jason C. Gallion', 'Jason', 'Gallion', false, true, 'GOP', 36986, 66.66, false, true, 'won', 'e2ca1bfd-255d-417b-a9d7-424e6c10749d'::uuid, 'holder-exact-full-name', 'Jason C. Gallion'),
  ('65b31f0a-c550-4e42-bd49-4c3794423de7', 'c1d532ce-c417-47fd-858d-e83731716a55', 'State Senate District 34', 'Senator', 1, '20261103MD22127', '54731', 'Mary-Dulany James', 'Mary-Dulany', 'James', false, true, 'Dem', 31161, 60.44, false, true, 'won', '18313901-28d8-464c-9368-2873577e9d44'::uuid, 'holder-exact-full-name', 'Mary-Dulany James'),
  ('65b31f0a-c550-4e42-bd49-4c3794423de7', 'c1d532ce-c417-47fd-858d-e83731716a55', 'State Senate District 34', 'Senator', 1, '20261103MD22127', '173229', 'Raj Goel', 'Raj', 'Goel', false, false, 'GOP', 20397, 39.56, false, true, 'lost', NULL, NULL, NULL),
  ('fa0de4f2-4d7f-47e0-a5ff-3c0837f673e7', 'c3983764-b15b-4e2f-b7a1-bfc475f13d57', 'State Senate District 33', 'Senator', 1, '20261103MD22126', '122722', 'Dawn D. Gile', 'Dawn', 'Gile', false, true, 'Dem', 36914, 63.83, false, true, 'won', 'ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid, 'holder-exact-first-last', 'Dawn Gile'),
  ('fa0de4f2-4d7f-47e0-a5ff-3c0837f673e7', 'c3983764-b15b-4e2f-b7a1-bfc475f13d57', 'State Senate District 33', 'Senator', 1, '20261103MD22126', '173228', 'Amy Leahy', 'Amy', 'Leahy', false, false, 'GOP', 20920, 36.17, false, true, 'lost', NULL, NULL, NULL),
  ('a5c14fb6-61f5-458f-ae66-020447a37b48', '9869176e-f7e6-4478-bdb2-87c9bf0ded9e', 'State Senate District 32', 'Senator', 1, '20261103MD22125', '121347', 'Mark S. Chang', 'Mark', 'Chang', false, false, 'Dem', 30906, 73.69, false, true, 'won', NULL, NULL, NULL),
  ('a5c14fb6-61f5-458f-ae66-020447a37b48', '9869176e-f7e6-4478-bdb2-87c9bf0ded9e', 'State Senate District 32', 'Senator', 1, '20261103MD22125', '173227', 'Justin Gallucci', 'Justin', 'Gallucci', false, false, 'GOP', 11035, 26.31, false, true, 'lost', NULL, NULL, NULL),
  ('aa21b7be-fbf1-48e5-a67a-aeb621004873', 'a6102124-3983-4855-a1de-eaac07932591', 'State Senate District 31', 'Senator', 1, '20261103MD22124', '173225', 'Brent Mulrooney', 'Brent', 'Mulrooney', false, false, 'Dem', 24779, 45.56, false, true, 'lost', NULL, NULL, NULL),
  ('aa21b7be-fbf1-48e5-a67a-aeb621004873', 'a6102124-3983-4855-a1de-eaac07932591', 'State Senate District 31', 'Senator', 1, '20261103MD22124', '120134', 'Nicholaus Kipke', 'Nicholaus', 'Kipke', false, false, 'GOP', 29611, 54.44, false, true, 'won', NULL, NULL, NULL),
  ('7a98eeac-a4fa-45d0-9af6-92246173d67a', 'aac17e10-afc4-4f32-a998-0e424d9d2dd6', 'State Senate District 30', 'Senator', 1, '20261103MD22123', '122584', 'Shaneka T. Henson', 'Shaneka', 'Henson', false, true, 'Dem', 31765, 59.04, false, true, 'won', '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'holder-exact-first-last', 'Shaneka Henson'),
  ('7a98eeac-a4fa-45d0-9af6-92246173d67a', 'aac17e10-afc4-4f32-a998-0e424d9d2dd6', 'State Senate District 30', 'Senator', 1, '20261103MD22123', '173224', 'Jessica Haire', 'Jessica', 'Haire', false, false, 'GOP', 22038, 40.96, false, true, 'lost', NULL, NULL, NULL),
  ('085dfd9b-d48f-4575-9477-fdf2b13a12e6', '4433d575-b5a8-4f8e-ad0a-521804eaff08', 'State Senate District 1', 'Senator', 1, '20261103MD22094', '173078', 'Ashley Emerick', 'Ashley', 'Emerick', false, false, 'Dem', 14419, 31.96, false, true, 'lost', NULL, NULL, NULL),
  ('085dfd9b-d48f-4575-9477-fdf2b13a12e6', '4433d575-b5a8-4f8e-ad0a-521804eaff08', 'State Senate District 1', 'Senator', 1, '20261103MD22094', '121029', 'Mike McKay', 'Mike', 'McKay', false, true, 'GOP', 30691, 68.04, false, true, 'won', 'f88cd73d-1970-4da1-9bea-2142a25999a7'::uuid, 'holder-exact-full-name', 'Mike McKay'),
  ('e0b6bc2e-bef4-4ea9-b946-adbe18765364', 'e67e2845-4dc4-4b1a-8c2a-3f2183303800', 'State Senate District 2', 'Senator', 1, '20261103MD22095', '173116', 'Eric Martin Van Buren', 'Eric', 'Van Buren', false, false, 'Dem', 19163, 45.24, false, true, 'lost', NULL, NULL, NULL),
  ('e0b6bc2e-bef4-4ea9-b946-adbe18765364', 'e67e2845-4dc4-4b1a-8c2a-3f2183303800', 'State Senate District 2', 'Senator', 1, '20261103MD22095', '122062', 'Paul D. Corderman', 'Paul', 'Corderman', false, true, 'GOP', 23194, 54.76, false, true, 'won', '5127f8d8-ca40-40aa-8773-4c1abad66f41'::uuid, 'holder-exact-full-name', 'Paul D. Corderman'),
  ('11f22ddd-b078-4705-8d94-4c5beda38f78', 'f391024b-2383-471c-81ee-832b4bd27817', 'State Senate District 3', 'Senator', 1, '20261103MD22096', '173117', 'Karen Lewis Young', 'Karen', 'Lewis Young', false, true, 'Dem', 36003, 74.18, false, true, 'won', '1f78b5e2-b192-4aae-8112-19338aaa891d'::uuid, 'holder-exact-full-name', 'Karen Lewis Young'),
  ('11f22ddd-b078-4705-8d94-4c5beda38f78', 'f391024b-2383-471c-81ee-832b4bd27817', 'State Senate District 3', 'Senator', 1, '20261103MD22096', '173118', 'Shelley Aloi', 'Shelley', 'Aloi', false, false, 'GOP', 12529, 25.82, false, true, 'lost', NULL, NULL, NULL),
  ('af67c7dd-f2e3-43a2-927b-b4eb81c0e8d0', 'd383a280-2a6b-4b1a-99e7-0f28ce9b4673', 'State Senate District 4', 'Senator', 1, '20261103MD22097', '173120', 'Lara Westdorp', 'Lara', 'Westdorp', false, false, 'Dem', 30640, 51.81, false, true, 'won', NULL, NULL, NULL),
  ('af67c7dd-f2e3-43a2-927b-b4eb81c0e8d0', 'd383a280-2a6b-4b1a-99e7-0f28ce9b4673', 'State Senate District 4', 'Senator', 1, '20261103MD22097', '121052', 'William Folden', 'William', 'Folden', false, true, 'GOP', 28495, 48.19, false, true, 'lost', '4a5241b7-8737-4a58-adf2-c5335111d3c4'::uuid, 'holder-exact-first-last', 'William G. Folden'),
  ('af43ccf3-bf01-4f64-a813-a83d9ebeef94', '0fd6c6a8-d5fa-494c-8303-c2afd6a3ca6c', 'State Senate District 5', 'Senator', 1, '20261103MD22098', '173124', 'Gary Foote', 'Gary', 'Foote', false, false, 'Dem', 22919, 41.16, false, true, 'lost', NULL, NULL, NULL),
  ('af43ccf3-bf01-4f64-a813-a83d9ebeef94', '0fd6c6a8-d5fa-494c-8303-c2afd6a3ca6c', 'State Senate District 5', 'Senator', 1, '20261103MD22098', '120315', 'Justin Ready', 'Justin', 'Ready', false, true, 'GOP', 32760, 58.84, false, true, 'won', '493c5d0c-1986-40d4-9fff-3a3bc3fe62e8'::uuid, 'holder-exact-full-name', 'Justin Ready'),
  ('32fffefb-0f89-464f-b10b-9bdb3d878698', 'a33a7480-2bb1-480f-8b55-3ec0c9d6ea6a', 'State Senate District 6', 'Senator', 1, '20261103MD22099', '122085', 'Justin Holliday', 'Justin', 'Holliday', false, false, 'Dem', 16260, 47.45, false, true, 'lost', NULL, NULL, NULL),
  ('32fffefb-0f89-464f-b10b-9bdb3d878698', 'a33a7480-2bb1-480f-8b55-3ec0c9d6ea6a', 'State Senate District 6', 'Senator', 1, '20261103MD22099', '68513', 'Johnny Ray Salling', 'Johnny', 'Salling', false, true, 'GOP', 18007, 52.55, false, true, 'won', '9f8d0005-c5ff-42f8-b158-cdb6e4eee872'::uuid, 'holder-exact-full-name', 'Johnny Ray Salling'),
  ('27b4d399-85f9-4c97-9659-16c250ef9b77', '44cb2ec1-efc5-4bde-9e3a-9894727bb1cc', 'State Senate District 7', 'Senator', 1, '20261103MD22100', '173128', 'Bill Geibler', 'Bill', 'Geibler', false, false, 'Dem', 24016, 43.32, false, true, 'lost', NULL, NULL, NULL),
  ('27b4d399-85f9-4c97-9659-16c250ef9b77', '44cb2ec1-efc5-4bde-9e3a-9894727bb1cc', 'State Senate District 7', 'Senator', 1, '20261103MD22100', '54649', 'J.B. Jennings', 'J.B.', 'Jennings', false, true, 'GOP', 31425, 56.68, false, true, 'won', '5927d5ab-2fd7-4454-bcc3-34e494821aac'::uuid, 'holder-exact-full-name', 'J.B. Jennings'),
  ('c1ee9908-84b4-418c-b2ca-7a622a55fcca', 'e4b0e073-3f5e-4f3e-b1a2-0f2395f43b8c', 'State Senate District 8', 'Senator', 1, '20261103MD22101', '122113', 'Carl Jackson', 'Carl', 'Jackson', false, true, 'Dem', 27734, 71.14, false, true, 'won', '2fbad601-c2da-4f99-b04f-d28ae30b80f7'::uuid, 'holder-exact-full-name', 'Carl Jackson'),
  ('c1ee9908-84b4-418c-b2ca-7a622a55fcca', 'e4b0e073-3f5e-4f3e-b1a2-0f2395f43b8c', 'State Senate District 8', 'Senator', 1, '20261103MD22101', '173129', 'Yahu Blackwell', 'Yahu', 'Blackwell', false, false, 'GOP', 11249, 28.86, false, true, 'lost', NULL, NULL, NULL),
  ('259a5fd6-ce9f-4cd5-9666-d828a387d580', '500bea34-2e1e-4dc2-b866-07bb9cc6aab1', 'State Senate District 9', 'Senator', 1, '20261103MD22102', '121977', 'Katie Fry Hester', 'Katie', 'Hester', false, true, 'Dem', 37375, 67.62, false, true, 'won', '6da20195-1b0c-43f2-b1b3-7a3954326fe6'::uuid, 'holder-exact-full-name', 'Katie Fry Hester'),
  ('259a5fd6-ce9f-4cd5-9666-d828a387d580', '500bea34-2e1e-4dc2-b866-07bb9cc6aab1', 'State Senate District 9', 'Senator', 1, '20261103MD22102', '173131', 'Ben Hightower', 'Ben', 'Hightower', false, false, 'GOP', 17896, 32.38, false, true, 'lost', NULL, NULL, NULL),
  ('7c2f2e69-484a-4d20-a61c-2d8e78406529', 'f5995b57-73b8-49be-aedf-6cc5f299f8fc', 'State Senate District 10', 'Senator', 1, '20261103MD22103', '122688', 'Ben Brooks', 'Ben', 'Brooks', false, true, 'Dem', 0, 0, true, true, 'won', 'a16b94b0-dd22-40a9-af91-03295ea27986'::uuid, 'holder-surname-plus-roster', 'Benjamin Brooks'),
  ('85284d6c-a542-4d6b-bdb6-9c7ef7164eef', '9aa9067e-6140-4429-9566-83354ab351cf', 'State Senate District 11', 'Senator', 1, '20261103MD22104', '121142', 'Shelly L. Hettleman', 'Shelly', 'Hettleman', false, true, 'Dem', 37344, 76.37, false, true, 'won', '3089c813-f0a8-46af-9a7b-1699129037e9'::uuid, 'holder-exact-first-last', 'Shelly Hettleman'),
  ('85284d6c-a542-4d6b-bdb6-9c7ef7164eef', '9aa9067e-6140-4429-9566-83354ab351cf', 'State Senate District 11', 'Senator', 1, '20261103MD22104', '68514', 'Jim Simpson', 'Jim', 'Simpson', false, false, 'GOP', 11556, 23.63, false, true, 'lost', NULL, NULL, NULL),
  ('2ea6b2e3-8880-46d7-a917-c3b30dd5f2f6', 'ea712341-4379-4644-915b-7d5a319b9a30', 'State Senate District 12', 'Senator', 1, '20261103MD22105', '121160', 'Clarence Lam', 'Clarence', 'Lam', false, true, 'Dem', 0, 0, true, true, 'won', 'fc23b939-0dfd-4968-ab19-fc1e7745e997'::uuid, 'holder-exact-first-last', 'Clarence K. Lam'),
  ('a5681c8d-a32d-480e-abe3-9ab985037068', 'd44ddb89-07a9-4700-9d80-552757ac12c1', 'State Senate District 13', 'Senator', 1, '20261103MD22106', '120097', 'Guy Guzzone', 'Guy', 'Guzzone', false, true, 'Dem', 0, 0, true, true, 'won', 'f0fafa0e-3dd9-4d50-bc5e-c96315f766d7'::uuid, 'holder-exact-full-name', 'Guy Guzzone'),
  ('cbeb02ff-4a23-4018-b432-e5dc8354fac9', 'f8c16196-808a-49b4-9d29-998c89c1a481', 'State Senate District 14', 'Senator', 1, '20261103MD22107', '120339', 'Craig J. Zucker', 'Craig', 'Zucker', false, true, 'Dem', 0, 0, true, true, 'won', '82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid, 'holder-exact-full-name', 'Craig J. Zucker'),
  ('b2397923-dc3d-4cbf-b389-8a9d2eb21afa', 'b374132a-b037-49dd-9806-bb14e7f19761', 'State Senate District 15', 'Senator', 1, '20261103MD22108', '54674', 'Brian J. Feldman', 'Brian', 'Feldman', false, true, 'Dem', 0, 0, true, true, 'won', 'd423151e-8477-470d-8f73-ba7d2092f714'::uuid, 'holder-exact-full-name', 'Brian J. Feldman'),
  ('4760ad80-119e-4a85-acee-bab2f41d8947', '88f2dbad-f712-47e6-ab3a-ad2c3c477814', 'State Senate District 16', 'Senator', 1, '20261103MD22109', '122159', 'Sara N. Love', 'Sara', 'Love', false, true, 'Dem', 0, 0, true, true, 'won', 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'holder-exact-first-last', 'Sara Love'),
  ('d41b5806-5a13-4404-9607-6d1819d7beed', '9d5f8d3c-6c42-4a17-9439-76ed7e791ece', 'State Senate District 17', 'Senator', 1, '20261103MD22110', '120281', 'Cheryl C. Kagan', 'Cheryl', 'Kagan', false, true, 'Dem', 32809, 83.88, false, true, 'won', 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'holder-exact-full-name', 'Cheryl C. Kagan'),
  ('d41b5806-5a13-4404-9607-6d1819d7beed', '9d5f8d3c-6c42-4a17-9439-76ed7e791ece', 'State Senate District 17', 'Senator', 1, '20261103MD22110', '122870', 'Helene Meister', 'Helene', 'Meister', false, false, 'GOP', 6306, 16.12, false, true, 'lost', NULL, NULL, NULL),
  ('bf65549c-3315-40ab-808d-2775673c5f0f', '5a377830-d27f-4913-8e0b-967c5f11ce70', 'State Senate District 18', 'Senator', 1, '20261103MD22111', '120107', 'Jeff Waldstreicher', 'Jeff', 'Waldstreicher', false, true, 'Dem', 0, 0, true, true, 'won', 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'holder-exact-full-name', 'Jeff Waldstreicher'),
  ('62224301-f2c4-4aaa-8eac-6f98d3c0fd0c', '95d570a9-0385-49c4-945d-93d53c5dcc85', 'State Senate District 19', 'Senator', 1, '20261103MD22112', '120108', 'Ben Kramer', 'Ben', 'Kramer', false, true, 'Dem', 0, 0, true, true, 'won', '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'holder-surname-plus-roster', 'Benjamin F. Kramer'),
  ('7d151389-ae1d-47f3-a983-c1d7e1aa8176', 'e568b6bd-c636-4563-8a07-95bd7db5bee9', 'State Senate District 20', 'Senator', 1, '20261103MD22113', '121238', 'Will Smith', 'Will', 'Smith', false, true, 'Dem', 0, 0, true, true, 'won', 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'holder-surname-plus-roster', 'William C. Smith, Jr.'),
  ('e50cd410-cd63-46e1-b698-46058e1d5917', 'd27f5b16-1490-4d78-b146-a643990c5efe', 'State Senate District 21', 'Senator', 1, '20261103MD22114', '120068', 'Jim Rosapepe', 'Jim', 'Rosapepe', false, true, 'Dem', 29791, 84.43, false, true, 'won', '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'holder-exact-full-name', 'Jim Rosapepe'),
  ('e50cd410-cd63-46e1-b698-46058e1d5917', 'd27f5b16-1490-4d78-b146-a643990c5efe', 'State Senate District 21', 'Senator', 1, '20261103MD22114', '58525', 'Lee Havis', 'Lee', 'Havis', false, false, 'GOP', 5492, 15.57, false, true, 'lost', NULL, NULL, NULL),
  ('32454497-3686-4825-9263-8d6403592acc', 'd4951db2-03f1-4fbf-b670-066aec0b745b', 'State Senate District 22', 'Senator', 1, '20261103MD22115', '121250', 'Alonzo T. Washington', 'Alonzo', 'Washington', false, true, 'Dem', 28780, 92.78, false, true, 'won', '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'holder-exact-full-name', 'Alonzo T. Washington'),
  ('32454497-3686-4825-9263-8d6403592acc', 'd4951db2-03f1-4fbf-b670-066aec0b745b', 'State Senate District 22', 'Senator', 1, '20261103MD22115', '173213', 'Jim Wass', 'Jim', 'Wass', false, false, 'GOP', 2239, 7.22, false, true, 'lost', NULL, NULL, NULL),
  ('d9677dc0-9466-4b14-9f93-d08d027b053b', '4401b212-c1bd-40f7-8c73-fc35370aaa7a', 'State Senate District 23', 'Senator', 1, '20261103MD22116', '121255', 'Ron Watson', 'Ron', 'Watson', false, true, 'Dem', 49955, 90.99, false, true, 'won', '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'holder-exact-full-name', 'Ron Watson'),
  ('d9677dc0-9466-4b14-9f93-d08d027b053b', '4401b212-c1bd-40f7-8c73-fc35370aaa7a', 'State Senate District 23', 'Senator', 1, '20261103MD22116', '173218', 'James A. T. Amah', 'James', 'Amah', false, false, 'GOP', 4948, 9.01, false, true, 'lost', NULL, NULL, NULL),
  ('d8e58308-1167-4718-ad07-105378c212ad', 'ff52f036-ad8b-46b4-815f-e51216f7ea8d', 'State Senate District 24', 'Senator', 1, '20261103MD22117', '120459', 'Tiffany Alston', 'Tiffany', 'Alston', false, false, 'Dem', 0, 0, true, true, 'won', NULL, NULL, NULL),
  ('8bb3b6c1-e30b-4f29-804a-18236702cdf2', '7d1b51c8-3cb4-4953-9b7b-ca9be0f9f655', 'State Senate District 25', 'Senator', 1, '20261103MD22118', '121272', 'Nick Charles', 'Nick', 'Charles', false, true, 'Dem', 0, 0, true, true, 'won', 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'holder-exact-full-name', 'Nick Charles'),
  ('332ef7df-f217-4212-ba28-392026fa0a51', '2bb5e64e-137d-4d7f-880a-5690d12a70e5', 'State Senate District 26', 'Senator', 1, '20261103MD22119', '120071', 'C. Anthony Muse', 'C.', 'Muse', false, true, 'Dem', 0, 0, true, true, 'won', '47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'holder-exact-full-name', 'C. Anthony Muse'),
  ('89f3b6da-cc85-4044-a8c5-5eed755b8c44', '5b5ac0eb-c33d-4378-adc2-831f6ef1d3e1', 'State Senate District 27', 'Senator', 1, '20261103MD22120', '122923', 'Kevin M. Harris', 'Kevin', 'Harris', false, true, 'Dem', 38701, 66.48, false, true, 'won', '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'holder-exact-full-name', 'Kevin M. Harris'),
  ('89f3b6da-cc85-4044-a8c5-5eed755b8c44', '5b5ac0eb-c33d-4378-adc2-831f6ef1d3e1', 'State Senate District 27', 'Senator', 1, '20261103MD22120', '122709', 'Al Larsen', 'Al', 'Larsen', false, false, 'GOP', 19513, 33.52, false, true, 'lost', NULL, NULL, NULL);

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> 289 THEN RAISE EXCEPTION 'CC_0415: expected 289 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> 118 THEN RAISE EXCEPTION 'CC_0415: expected 118 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> 178 THEN RAISE EXCEPTION 'CC_0415: expected 178 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> 91 THEN RAISE EXCEPTION 'CC_0415: expected 91 losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> 20 THEN RAISE EXCEPTION 'CC_0415: expected 20 rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> 289 THEN RAISE EXCEPTION 'CC_0415: the race join sees % of the 289 rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 Maryland legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> 'md'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % pinned row(s) are not in a 2026-11-03 Maryland legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: winner count does not match races.seats: %', txt; END IF;

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
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> 98 THEN RAISE EXCEPTION 'CC_0415: expected 98 incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_race_id || '-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: external_id already in use: %', txt; END IF;
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
         || '2026-11-03/results/races/MD/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against the State Board of Elections'' own unofficial returns for State Senator and the House of Delegates '
         || '(https://elections.maryland.gov/elections/2026/general_results/index.html, read 2026-11-13). Seeded by CC_0415.'
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
  IF n <> 289 THEN RAISE EXCEPTION 'CC_0415: expected 289 rows written, found %', n; END IF;

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
  IF n <> 289 THEN RAISE EXCEPTION 'CC_0415: only % of 289 written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0415: a citation quotes a vote count: %', txt; END IF;

  -- The 118 races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = 'md'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_race_id || '-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0415: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> 98 THEN RAISE EXCEPTION 'CC_0415: the seat holder changed for % of the 98 linked office(s) — this file seats nobody', 98 - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION 'CC_0415: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'CC_0415: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
