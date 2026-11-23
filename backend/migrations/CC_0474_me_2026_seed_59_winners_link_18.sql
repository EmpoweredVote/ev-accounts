-- CC_0474 — Maine: create the 59 legislative winners we do not hold, and LINK the 18 who are
-- sitting members already.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 77 BLOCKERS, 59 PEOPLE. THE OTHER 18 ARE ALREADY IN THE TABLE, AND MAINE IS WHY.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `derive-seating-wave.mjs` reports 77 `winner_no_record` blockers for Maine — the largest
-- seeding job in the pass — and this file creates 59. THE BLOCKER IS COMPUTED FROM THE WINNER'S
-- OWN RACE ROW AND NEVER SAYS "NO RECORD ANYWHERE". Nevada taught this once, with Danielle
-- Gallant; Maine does it eighteen times, and term limits are the reason.
--
-- Maine caps a member at four consecutive terms in one chamber, so members at the cap do not
-- retire — THEY CHANGE CHAMBERS. Fourteen of the eighteen are exactly that:
--
--   Senate → House                          House → Senate
--     Susan Bernard         SD1  → HD3        Lucien J.B. Daigle     HD1   → SD1
--     Stacey K. Guerin      SD4  → HD34       Chad Richard Perkins   HD31  → SD4
--     Russell J. Black      SD5  → HD74       Elizabeth M. Caruso    HD72  → SD5
--     Jeffrey L. Timberlake SD17 → HD91       Billy Bob Faulkingham  HD12  → SD6
--                                             Amy J. Roeder          HD23  → SD9
--                                             Ann H. Matlack         HD43  → SD12
--                                             Richard G. Mason       HD97  → SD17
--                                             Kimberly J. Pomerleau  HD85  → SD22
--                                             Sophia Bailey Warren   HD124 → SD30
--                                             Daniel R. Sayre        HD135 → SD34
--                                             Michele Meyer          HD150 → SD35
--
-- The other four hold a LOCAL office we already seeded: April D. Fournier (Portland),
-- Ayn M. Hanselmann (Sanford) and Mallory A. Cook (Bangor School Department) — plus
-- Chad Richard Perkins, counted above.
--
-- 🔴 SEEDING ANY OF THE EIGHTEEN WOULD HAVE PUT A SECOND ROW ON THE BOARD FOR A SERVING
--    OFFICIAL, and CLAUDE.md's rule is one row per person.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 A NAME THAT MATCHES IS NOT A PERSON THAT MATCHES, AND THE SWEEP ALMOST SAID OTHERWISE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The sweep for "Chad Perkins" returns TWO active politicians rows. One holds MISSOURI State
-- House District 40; the other holds MAINE State House District 31. They are different people
-- who share a name, not a duplicate to merge.
--
-- ⚠ THE FIRST VERSION OF THAT SWEEP PRINTED THE SEAT WITHOUT ITS STATE. It read "Chad Perkins,
--   State House District 40" beside "Chad Perkins, State House District 31" — which is exactly
--   what one person's two terms under two different maps would look like, and Maine DID
--   redistrict in 2021. ▶ **PRINT THE FIELD THAT DISCRIMINATES, NOT THE ONE THAT IDENTIFIES.**
--   Maine's winner is 84f4f54e-6b77-4094-b6bd-d2304b919160; the Missouri row is untouched, and
--   P5 and assertion 3 both say so.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- HOW ALL 77 WERE CHECKED, AND AGAINST WHAT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 NOT ONE OF THESE NAMES RESTS ON AP ALONE. Every winner carries at least one corroboration
--    from a Maine source, and the two sources between them cover all 77:
--
--   • 60 ARE NAMED BY THE LEGISLATURE ITSELF — "133rd Maine Legislature, Orientation for Newly
--     Elected Members", Groups A and B, each person listed as "Representative-elect" or
--     "Senator-elect". https://legislature.maine.gov/doc/12790, read 2026-11-23.
--   • 72 APPEAR ON THE SECRETARY OF STATE'S OWN CANDIDATE FILING LIST, matched on SURNAME AND
--     DISTRICT — a far stronger key than a name alone — with ZERO first-name disagreements.
--     2026 Candidate List, maine.gov/sos, read 2026-11-23.
--   • 0 HAVE NEITHER. The five absent from the filing list (HD44, HD45, HD121, HD144, HD148)
--     filed after the primary and are all on the orientation roster; the fifteen absent from the
--     orientation roster are sitting members, who are not "newly elected".
--
-- 🟢🟢 AND THOSE TWO PARTITIONS AGREE WITHOUT EITHER BEING DERIVED FROM THE OTHER. "Already in
--    our politicians table as a sitting Maine legislator" and "absent from the Legislature's
--    newly-elected roster" name the same people. That is the control this step is owed, and it
--    cost nothing but reading a second document.
--
-- ⚠ THE ORIENTATION LIST IS AUTHORITATIVE ABOUT **WHO** AND UNRELIABLE ABOUT **HOW THEY SPELL
--   IT.** It is a staff scheduling agenda, not a published roster, and it disagrees with the
--   Secretary of State's filing record four times — every time in AP's favour:
--
--     HD43   agenda "Riannon Hampson"   · filing "Hampson, Rhiannon Corey"   ← ours
--     HD112  agenda "Shean M. Mahoney"  · filing "Mahoney, Sean M"           ← ours
--     HD55   agenda "Maureen Aucoin"    · filing "AuCoin, Maureen"           ← ours
--     HD75   agenda "Scott H. Landry"   · filing "Landry, H. Scott"          ← ours
--
--   🔴 THIS IS THE OPPOSITE CALL FROM NEVADA, AND THE DIFFERENCE IS WHAT THE DOCUMENT IS FOR.
--   CC_0466 spelt Assembly District 15 "Miguel Dávila" because the Nevada Legislature's own
--   PUBLISHED MEMBER PAGE outranked AP on a member's name. An internal agenda is not that.
--   ▶ **ASK WHAT A DOCUMENT IS FOR BEFORE LETTING IT OVERRULE A NAME.** Here the state's own
--   filing record — what the candidate wrote on the form — is the better authority, and it
--   agrees with the rows we already hold.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS FILE DOES NOT DO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- • `party` IS LEFT NULL ON ALL 59. The orientation roster gives no party, and the Secretary of
--   State's Party column is empty for every legislative filing in that sheet. A party is a claim
--   about a person and a guessed one is a wrong claim about a real person. Many Maine rows
--   already in this table carry NULL here. ▶ Owed, from the chamber's published roster once the
--   133rd convenes on 2026-12-02.
-- • NOBODY IS SEATED AND NO TERM IS WRITTEN. A winner who has not taken office is not an
--   officeholder, and essentials.politicians no longer carries is_incumbent at all (CA_0378).
-- • 🔴 THREE MAINE SEATS ARE STILL INVISIBLE AND THIS FILE CANNOT REACH THEM. State House 86,
--   State House 96 and State Senate 18 carry a 2026 race with NO recorded result, so they sit
--   outside office_pending_winner and outside these 77. ▶ THE ORIENTATION ROSTER NAMES ALL THREE
--   WINNERS — Abigail Geer (Rep-elect), Kerryl Clement (Rep-elect) and Elizabeth Bosworth
--   (Senator-elect) — and each is a candidate our own race_candidates already holds with
--   `result` NULL. That is a finding for the results programme, not a licence for this file to
--   write a result. Assertion 7 asserts the three are still there when this finishes.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 SEVENTY-SEVEN `race_candidates.politician_id` VALUES, AND THE VALUE OVERWRITTEN IS NULL ON
--    ALL SEVENTY-SEVEN. The UPDATE is guarded `WHERE politician_id IS NULL` and assertion 2
--    refuses unless all 77 moved. No other column of race_candidates is touched.
-- 🔴 THE 59 NEW ROWS CARRY EXPLICIT IDs rather than gen_random_uuid(), so this file records
--    exactly what it created and the seating wave's selection digest can be computed before it
--    runs — CC_0466's reasoning, at four times the scale.

BEGIN;

CREATE TEMP TABLE cc0474_people (
  seat       text,
  office_id  uuid,
  person_id  uuid,
  full_name  text,
  first_name text,
  last_name  text,
  create_row boolean
) ON COMMIT DROP;

INSERT INTO cc0474_people VALUES
  ('State House District 1', '11ae35e4-1267-428f-9fc0-51249878d06a', '8d66667b-aa90-43b0-95e6-74a17aa43271', 'Austin Theriault', 'Austin', 'Theriault', true),
  ('State House District 3', 'b1d74bd9-4c8e-4057-8a4f-d9d37380f9ff', '4fcdb98d-b61f-499d-8d19-8f9462c907dd', 'Susan Bernard', 'Susan', 'Bernard', false),
  ('State House District 5', 'ab1735d1-5550-4b4e-ab1b-d1c5e71c65ef', '17d0931e-c9e1-436d-a2af-c72550575db5', 'Douglas C. Carlisle Jr.', 'Douglas', 'Carlisle', true),
  ('State House District 7', '01ee34b3-5ea9-4a6c-9eca-b4aeefc5cda1', 'baa09d2e-6fb0-40e6-87a2-743e041e0141', 'Jantzen Stephen Craine', 'Jantzen', 'Craine', true),
  ('State House District 12', '9b05741f-ba5e-4167-8251-dacd4bd2522e', '48838c51-be9a-4b36-9419-043c0f4d457d', 'Thomas Arthur Hart Jr.', 'Thomas', 'Hart', true),
  ('State House District 23', '2df5a507-6dd4-43b8-b90a-3a431e50fbde', '2dc6e25f-10e3-4bb7-8f61-a33a4d8c87ff', 'Victoria P. Kornfield', 'Victoria', 'Kornfield', true),
  ('State House District 27', '617ee970-023d-4354-9071-700a0448f225', '17216245-dd5a-4ad4-9561-cf38215d9477', 'David Giles', 'David', 'Giles', true),
  ('State House District 31', '334dd517-72ac-4556-b396-621d89020e27', '37687fd9-cee1-46ce-ae23-052bc1fec157', 'Andrew R. Torbett', 'Andrew', 'Torbett', true),
  ('State House District 32', 'ddd3da71-30bb-4d2b-a7e8-0796a9e138ee', 'c010a3fc-45d8-46fd-bc8b-1b8a2ac0b3c8', 'Shawn L. Lancaster', 'Shawn', 'Lancaster', true),
  ('State House District 34', 'f4ed555b-f848-4233-ae68-4cc9a9c3841d', 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', 'Stacey K. Guerin', 'Stacey', 'Guerin', false),
  ('State House District 39', 'f9b096e5-1abc-4da0-88fd-9955cb82a8e5', 'bd75c0e9-d066-42a1-94d2-68289fe2325f', 'Madison Crissey Cook', 'Madison', 'Cook', true),
  ('State House District 41', 'c7fae8ff-3f94-46ea-9b60-831db046ffa0', '356cedbc-bc50-4af6-bd4b-98f0a2c6b028', 'Joshua D. Gerritsen', 'Joshua', 'Gerritsen', true),
  ('State House District 43', 'c8915162-7dbc-4f10-8801-38352d528dac', 'c33eaac9-f238-45eb-a56b-78fbed3aa459', 'Rhiannon Corey Hampson', 'Rhiannon', 'Hampson', true),
  ('State House District 44', '7b545b37-325d-4245-a51b-10f25b918dea', '598c79a0-8023-4212-8f33-f9202cb80ae5', 'Shawn Saindon', 'Shawn', 'Saindon', true),
  ('State House District 45', '0ccac3b9-f107-419b-9051-a9b04375ce54', '7e72cc0f-8d0f-45af-aa9e-fde2b816942f', 'Clinton E. Collamore', 'Clinton', 'Collamore', true),
  ('State House District 46', '0683ecd5-d1ac-4bc0-bc8f-0f4197df0ce4', '8c2314e7-0fd2-477c-bdd5-e1cedf611f2a', 'Jennifer F. Mayher', 'Jennifer', 'Mayher', true),
  ('State House District 48', 'e8ef2c54-29be-44ab-a482-e554af324670', '071439db-cea8-4bbb-bbab-3cee17e724f2', 'Charlotte Nutt', 'Charlotte', 'Nutt', true),
  ('State House District 49', '638c38eb-f1bb-49bd-a861-bf7c85a2953d', '2c2b5fe6-2638-4a04-9eef-70148759590f', 'Trent E. Vellella', 'Trent', 'Vellella', true),
  ('State House District 55', '465f0785-a507-4170-b16f-a674f7d106a8', '5dba6c3b-52c6-4e3e-a5c0-baeb17a5ca45', 'Maureen AuCoin', 'Maureen', 'AuCoin', true),
  ('State House District 59', '5fcc3f80-cd90-4dbb-aded-177fc584da34', 'b4f14349-7af1-4b0c-80ff-5a657664d822', 'Katrina Couch Ray-Saulis', 'Katrina', 'Couch Ray-Saulis', true),
  ('State House District 66', '584cc0de-2a95-495d-8403-7fd9916d074a', '0fca3aac-7fca-4542-a305-b6293f8d39b0', 'Michael D. Perkins', 'Michael', 'Perkins', true),
  ('State House District 67', 'd48a879f-cfe9-4a58-9bb9-a478292c53b0', '36940e51-e8ce-4b13-9e8d-9f3ea549bbe3', 'Shawn M. Dixon', 'Shawn', 'Dixon', true),
  ('State House District 72', 'a450cb67-e476-4461-adcd-39b52edda991', 'a849392b-633f-478c-85ca-307cb3afe5ba', 'Douglas Andrew Thomas', 'Douglas', 'Thomas', true),
  ('State House District 74', '381992d1-2f56-46b3-bd7f-652dbc892fec', '81db75c5-8c48-40f3-8cb1-7220def31e72', 'Russell J. Black', 'Russell', 'Black', false),
  ('State House District 75', '1a3bd9b3-f59a-45d4-a0bf-0612777be082', 'a49b7aee-f0d5-4211-811d-129ed685f22b', 'H. Scott Landry', 'H. Scott', 'Landry', true),
  ('State House District 80', '3823fd51-eed9-4606-b3a6-1f5f9fcc3e34', 'bdb9ee76-0685-40cf-aa3d-95d69d221afe', 'Ernest M. Fitts IV', 'Ernest', 'Fitts', true),
  ('State House District 81', 'f3ff04d7-3e8e-43d0-a97c-88f53499b2e2', '13dfc2e4-0185-4875-a0a9-8a3688988062', 'Christopher A. Easton', 'Christopher', 'Easton', true),
  ('State House District 82', '1e260e08-d77a-4c16-87f4-ed8afcf42ed7', 'f8ed8fef-9890-48cf-9489-9107ed5b9737', 'Christopher Alfred Lewey', 'Christopher', 'Lewey', true),
  ('State House District 83', '0c0a4a37-681d-4120-8485-accb518f880b', 'dd9b2181-56c8-49f2-804f-21c3ca17c66b', 'Timothy J. Becker', 'Timothy', 'Becker', true),
  ('State House District 85', '5c538a8f-60c5-462e-b4af-482bf3cada60', '3182dde3-dcd7-41be-a120-be3301e17359', 'Adrienne Paul', 'Adrienne', 'Paul', true),
  ('State House District 88', '0fec242b-7c08-4d07-9dde-bd483185d543', '6e8dd209-c272-4318-916d-c9c5c6add5be', 'Dana N. Staples', 'Dana', 'Staples', true),
  ('State House District 90', '085952f4-2a3f-44f7-9101-008a3823ba3f', '3a643bee-4ea3-4de3-84af-2bb92401e491', 'Pamela B. Hart', 'Pamela', 'Hart', true),
  ('State House District 91', '40e0bebf-1ee9-48c7-831f-d008194afc53', 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', 'Jeffrey L. Timberlake', 'Jeffrey', 'Timberlake', false),
  ('State House District 95', '0a9751bb-c858-4e1d-aef4-31e35cfc78b7', '03b5c16a-00c4-4011-9c47-a572453bbb88', 'Kiernan Innes Majerus-Collins', 'Kiernan', 'Majerus-Collins', true),
  ('State House District 97', 'f4f313bb-9ac0-4d18-bbe7-2520a06066c1', '88a73bc2-4e39-4e64-b11b-943e73f25501', 'Dale John Crafts', 'Dale', 'Crafts', true),
  ('State House District 102', 'ec0bcc6d-e0fb-4783-b79a-8211d9dd8be7', '231eeabd-037c-4441-959a-63b239b898eb', 'Maura H. Pillsbury', 'Maura', 'Pillsbury', true),
  ('State House District 103', 'e392c7d6-23f2-4b70-9658-a69d39d5f4df', '86857b45-a373-4ba6-b047-1e9fd5b31d11', 'Karin Orenstein', 'Karin', 'Orenstein', true),
  ('State House District 104', '985771b9-33e4-4274-becf-7341b6920de0', '311e6209-23ae-451d-9a63-c0ab73ccdc3a', 'R. Melissa Winslow', 'R.', 'Winslow', true),
  ('State House District 106', '35262abb-f222-49f8-85d2-67d83dcf90c7', '55f33f21-6f47-49fd-94ab-7aa119beb96a', 'Bradley M. Youngs', 'Bradley', 'Youngs', true),
  ('State House District 107', 'a349de7e-d018-4240-84a4-427c3b0e0b3a', '9cb8a92f-9016-4347-ac0f-03b3c7ee5e63', 'Joseph A. Campbell', 'Joseph', 'Campbell', true),
  ('State House District 109', '04d7d9a3-9123-47b9-92b2-e7881be51a67', 'ba4294c8-63e7-47c5-8710-96a475a493ab', 'Seven R. Siegel', 'Seven', 'Siegel', true),
  ('State House District 112', 'ae1e74d3-5dc2-414e-87f6-1a99cbb18643', '696a2f4c-f3a9-4e76-83ef-12a1b7b178d5', 'Sean M. Mahoney', 'Sean', 'Mahoney', true),
  ('State House District 114', '2db692b3-c519-4ee3-8199-398d0195b1f1', '9a358472-ddfa-451e-b7a5-3b3295f55ea6', 'April D. Fournier', 'April', 'Fournier', false),
  ('State House District 115', '89613a5b-0266-4f1c-bda0-a223fac10551', '8036b015-0e65-47d2-a091-f2756cc77439', 'Andrew J. Zarro', 'Andrew', 'Zarro', true),
  ('State House District 119', '8350ef16-bf6f-4b7b-a952-2594d6fa7b3f', '7f7b4945-cdae-44f9-8ffd-684b2b467af9', 'Michael P. Dixon', 'Michael', 'Dixon', true),
  ('State House District 120', '895e42f8-a3bb-43d6-9907-b973d2a4b118', '124c71b6-db6d-42ce-bd08-998aee1030a4', 'Jason J. Shedlock', 'Jason', 'Shedlock', true),
  ('State House District 121', '2832f4d1-3fe8-4951-afdc-340a79d032c8', '890f3709-0124-403b-baf7-a2e50a1065c2', 'Lucy Louisa Perkins', 'Lucy', 'Perkins', true),
  ('State House District 124', 'a13df238-94d6-4094-b974-9cecd2a02f4c', '1046d65a-6e62-4cf4-9b92-3e69bfe0c477', 'Eric James Nathanson', 'Eric', 'Nathanson', true),
  ('State House District 131', '3cebc93b-5119-4c01-95c1-0155317f5cd6', 'dad87b8f-46d8-4836-bd9c-4ab5f6c7c929', 'Robert James Kelly', 'Robert', 'Kelly', true),
  ('State House District 135', '292f35ae-e51f-48ca-b0c3-21b25896fe9e', 'f2be87b5-652b-4d9d-9a1d-7e03755bc1d5', 'Lisa Joy Pratt', 'Lisa', 'Pratt', true),
  ('State House District 137', '27927d37-6be8-48a7-8a1b-623ea007ee82', '19632f04-2218-4f98-be27-495b90d5f5b9', 'Charles Tilburg', 'Charles', 'Tilburg', true),
  ('State House District 138', 'ff860a26-3bc4-4ed0-9dc6-8e05fb055107', '86871760-149b-44c7-97f2-cc5b2d110148', 'Jonathan Lee Kinney', 'Jonathan', 'Kinney', true),
  ('State House District 139', '7cec4591-2b60-4040-809a-7608a670ecbe', '1ab95b8e-d718-4d36-a461-c7cf9d73b364', 'Jamie K. Newton', 'Jamie', 'Newton', true),
  ('State House District 141', '0170d349-441e-4792-989f-75eee29c06a5', '9546168b-700a-4bee-ae02-a0438269d568', 'Marc A. Boisse', 'Marc', 'Boisse', true),
  ('State House District 142', '137f5c0a-1da3-48e4-85ba-ea34a49a68a3', 'aa9b7a50-036c-40f8-8332-c3376374bdf1', 'Ayn M. Hanselmann', 'Ayn', 'Hanselmann', false),
  ('State House District 143', 'c273e2d2-b458-4b87-9c32-ed0f2649c98b', 'f709a7e4-8963-408d-90f2-be4e2f4e3456', 'John R. Henkelman', 'John', 'Henkelman', true),
  ('State House District 144', 'be2b1141-523f-4cc4-9395-169f693d58d3', 'e2859ce2-0c2a-4876-a3cb-6699ca3b1322', 'Karen A. Gerrish', 'Karen', 'Gerrish', true),
  ('State House District 145', '688b4846-3f37-4091-8d45-3077f4bc3a16', '3cf48377-abcc-4221-9ee8-b7c8a8937149', 'Kristin T. Davis', 'Kristin', 'Davis', true),
  ('State House District 148', '2d652817-ef96-4f81-a7ce-dd9e27a71304', '08382b8f-4882-431e-8cc4-fd84e011d9bf', 'Marissa L. Tasker', 'Marissa', 'Tasker', true),
  ('State House District 149', '279cb520-0361-4170-a30d-05919f320807', '26931a0b-1fef-4e37-9d6a-ea5a1dfeb279', 'Mallory A. Cook', 'Mallory', 'Cook', false),
  ('State House District 150', '83f9b3c6-11e6-4e68-8541-289a40ac7e2d', '38608ceb-2f97-4e42-bf13-4682dfa43517', 'Alexandros Orestis', 'Alexandros', 'Orestis', true),
  ('State Senate District 1', '0f4ca657-f581-4810-aec2-4060a203b65e', '3a5abb5e-e742-4d99-94e9-5330c32f7cf4', 'Lucien J.B. Daigle', 'Lucien', 'Daigle', false),
  ('State Senate District 3', '6244cf8f-9c53-45b2-b6b3-7a81b6f12b90', 'e7dc0018-503f-447c-8a67-7486baf6c06f', 'Joel R. Stetkis', 'Joel', 'Stetkis', true),
  ('State Senate District 4', '45fae155-817f-4b8b-9015-fb31b71fe393', '84f4f54e-6b77-4094-b6bd-d2304b919160', 'Chad Richard Perkins', 'Chad', 'Perkins', false),
  ('State Senate District 5', '45a2394b-78a1-485f-9522-f051988358d3', '80747346-be87-4d1b-9bf6-9ee80356ba7f', 'Elizabeth M. Caruso', 'Elizabeth', 'Caruso', false),
  ('State Senate District 6', '5ce0544b-131b-45ca-b008-3a4e2dfeb247', '993299cd-a7b5-4246-a8f2-57e6eb7df1b9', 'Billy Bob Faulkingham', 'Billy Bob', 'Faulkingham', false),
  ('State Senate District 9', '20511820-9fe6-4828-aa28-79699b91aada', '74eb8c85-b789-4767-bdd1-206009b7cd11', 'Amy J. Roeder', 'Amy', 'Roeder', false),
  ('State Senate District 12', '5ce32a6b-1c8c-481d-a838-525ada68f569', '0bd82de2-6f06-4775-a716-cfa6568671ef', 'Ann H. Matlack', 'Ann', 'Matlack', false),
  ('State Senate District 15', 'c60d181d-44b4-4e11-88e2-ec3977d78215', '5f407cba-c7be-4b9e-9283-0ae4484761c8', 'Amanda Ann Heath', 'Amanda', 'Heath', true),
  ('State Senate District 16', 'f72a0ac0-d9c9-47cf-b22f-3c76ad8ed0d4', '9b3aaf98-7365-4df9-a93a-cb7d48f7666e', 'Patric Aaron Moore', 'Patric', 'Moore', true),
  ('State Senate District 17', '2ae092d3-7ff1-401e-82a9-ec83d84de30b', 'b43d9033-090f-4fea-9000-7f7360dbd0e6', 'Richard G. Mason', 'Richard', 'Mason', false),
  ('State Senate District 20', 'ac6789e3-4899-4da5-813d-0a1e964b9f63', 'fd923e47-973f-4dc4-8bc4-2acea7134614', 'Michael R. Scott', 'Michael', 'Scott', true),
  ('State Senate District 21', '15b51a46-105b-4946-8c76-350c142a7703', '13c3ce86-c131-42a7-bb45-3b5faabb646d', 'Shanna Cox', 'Shanna', 'Cox', true),
  ('State Senate District 22', '719f0367-d1bf-45b0-adf3-14c571977e8e', '496cc607-2296-4a7c-b2a0-0d56210805fd', 'Kimberly J. Pomerleau', 'Kimberly', 'Pomerleau', false),
  ('State Senate District 30', '8cbeea8e-bfae-4f06-bea5-f9f61ead3aee', '24e1ccb6-7ac1-4d98-a35f-d73c347dd906', 'Sophia Bailey Warren', 'Sophia', 'Warren', false),
  ('State Senate District 34', 'ffd5659f-b094-42e9-80f0-88476e164f93', '18b11787-c861-4996-aba5-3b863ea33b1d', 'Daniel R. Sayre', 'Daniel', 'Sayre', false),
  ('State Senate District 35', 'ac78d2b8-7e47-45c3-967e-2d8e1c81b8fc', 'ee8f52bc-ad53-4abf-b136-3898ead3e41b', 'Michele Meyer', 'Michele', 'Meyer', false);
-- The 77 winner rows this file links, found through the race rather than by name.
CREATE TEMP TABLE cc0474_rc ON COMMIT DROP AS
SELECT rc.id AS race_candidate_id, pp.seat, pp.person_id, pp.create_row,
       rc.politician_id AS politician_id_before
  FROM cc0474_people pp
  JOIN essentials.races r      ON r.office_id = pp.office_id
  JOIN essentials.elections e  ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won';

CREATE TEMP TABLE cc0474_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians)     AS politicians,
       (SELECT count(*) FROM essentials.office_terms)    AS terms,
       (SELECT count(*) FROM essentials.race_candidates) AS race_candidates,
       (SELECT count(*) FROM essentials.politicians
         WHERE id = 'b07a955b-5ed5-4e85-97fa-cadd07aa6ff9')                 AS mo_chad_perkins;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly 77 winner rows, one per seat, and every one of them unlinked.
  SELECT count(*) INTO n FROM cc0474_people;
  IF n <> 77 THEN
    RAISE EXCEPTION 'P1: the file lists % people, expected 77.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0474_rc;
  IF n <> 77 THEN
    RAISE EXCEPTION 'P1: % winner rows matched the 77 seats, expected 77. The data moved under '
                    'this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0474_rc WHERE politician_id_before IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the 77 winner rows already carry a politician_id. This file would '
                    'overwrite a link it has not recorded.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0474_people WHERE create_row;
  IF n <> 59 THEN
    RAISE EXCEPTION 'P1: % rows are marked for creation, expected 59 (77 less the 18 sitting '
                    'members who already have a row).', n;
  END IF;

  -- P2 — this file has not already been applied. Asked before P3, because after an apply the 59
  -- rows exist and P3 would report "somebody beat me to these names" when what happened is that
  -- the operator ran this twice.
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0474_people pp ON pp.person_id = p.id AND pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 59 new politician ids already exist. Applied before.', n;
  END IF;

  -- P3 — 🔴 NOBODY WITH THESE NAMES IS ALREADY IN THE TABLE. The duplicate-name guard's own
  --    predicate, (first_name, last_name), run over the WHOLE table including archived rows,
  --    because an archived duplicate is still a duplicate.
  SELECT count(*) INTO n
    FROM cc0474_people pp
    JOIN essentials.politicians p ON lower(p.first_name) = lower(pp.first_name)
                                 AND lower(p.last_name)  = lower(pp.last_name)
   WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % existing politician row(s) already carry one of the 59 names. ONE ROW '
                    'PER PERSON — read the row before creating a second.', n;
  END IF;

  -- P4 — every one of the 18 link targets exists, is active, and HOLDS A MAINE SEAT. The last
  -- clause is the load-bearing one: it is what tells a sitting Maine legislator from a stranger
  -- with the same name in another state.
  SELECT count(*) INTO n
    FROM cc0474_people pp
    JOIN essentials.politicians p ON p.id = pp.person_id
   WHERE NOT pp.create_row AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices o2 ON o2.id = t.office_id
                   JOIN essentials.districts d2 ON d2.id = o2.district_id
                  WHERE t.politician_id = p.id AND lower(d2.state) = 'me');
  IF n <> 18 THEN
    RAISE EXCEPTION 'P4: only % of the 18 link targets are an active politician holding a Maine '
                    'seat, expected 18.', n;
  END IF;

  -- P5 — 🔴 THE MISSOURI CHAD PERKINS IS NOT ONE OF THEM.
  SELECT count(*) INTO n FROM cc0474_people
   WHERE person_id = 'b07a955b-5ed5-4e85-97fa-cadd07aa6ff9';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: this file would link a winner to the MISSOURI Chad Perkins.';
  END IF;

  -- P6 — no person is used twice. 77 seats, 77 distinct people.
  SELECT count(*) INTO n FROM (
    SELECT person_id FROM cc0474_people GROUP BY person_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % person id(s) appear on more than one seat.', n;
  END IF;
END $$;

-- ─── 1. The 59 people we do not hold ─────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, true,
       'Winner of the 2026-11-03 general election for ' || pp.seat || ', Maine. Identity and '
         || 'district corroborated against two Maine sources rather than AP alone: the '
         || 'Legislature''s own "133rd Maine Legislature, Orientation for Newly Elected Members" '
         || 'roster (https://legislature.maine.gov/doc/12790, read 2026-11-23), which lists each '
         || 'person as Representative-elect or Senator-elect; and the Secretary of State''s 2026 '
         || 'candidate filing list (maine.gov/sos, read 2026-11-23), matched on SURNAME AND '
         || 'DISTRICT with no first-name disagreement. Where the orientation agenda and the '
         || 'filing record disagree on spelling, the filing record is followed, because the '
         || 'agenda is a staff scheduling document rather than a published roster. The election '
         || 'result itself is AP''s, cross-read against the Secretary of State. `party` is '
         || 'deliberately NULL: no source consulted gives one. Created by CC_0474; NOT seated '
         || 'here.'
  FROM cc0474_people pp
 WHERE pp.create_row;

-- ─── 2. All 77 winner rows get their person ──────────────────────────────────────────────────
-- 🔴 GUARDED `IS NULL`, so this file cannot overwrite a link that appeared between writing and
--    applying.
UPDATE essentials.race_candidates rc
   SET politician_id = c.person_id
  FROM cc0474_rc c
 WHERE rc.id = c.race_candidate_id
   AND rc.politician_id IS NULL;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0474_before;

  -- 1. 59 people created, and exactly 59, repo-wide.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians + 59 THEN
    RAISE EXCEPTION '1: politicians went % -> %, a delta of %, expected 59.',
      b.politicians, n, n - b.politicians;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0474_people pp ON pp.person_id = p.id AND pp.create_row
   WHERE p.full_name = pp.full_name AND p.is_active AND p.source LIKE '%CC_0474%';
  IF n <> 59 THEN
    RAISE EXCEPTION '1: % of the 59 new rows read back correctly.', n;
  END IF;

  -- 2. All 77 winner rows are linked, and to the right person.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN cc0474_rc c ON c.race_candidate_id = rc.id
   WHERE rc.politician_id = c.person_id;
  IF n <> 77 THEN
    RAISE EXCEPTION '2: % of 77 winner rows carry the intended politician_id.', n;
  END IF;

  -- 3. 🔴 EXACTLY TWO CHAD PERKINS ROWS SURVIVE — Maine's and Missouri's. A name collision
  --    across states is the failure this assertion exists for: a third row would mean this file
  --    created a duplicate, and one would mean somebody merged two different people.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE lower(first_name) = 'chad' AND lower(last_name) = 'perkins';
  IF n <> 2 THEN
    RAISE EXCEPTION '3: % Chad Perkins rows exist, expected 2 (Maine and Missouri).', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'b07a955b-5ed5-4e85-97fa-cadd07aa6ff9';
  IF n <> b.mo_chad_perkins THEN
    RAISE EXCEPTION '3: the Missouri Chad Perkins row is gone.';
  END IF;

  -- 4. NOBODY WAS SEATED. This file creates people; a later wave writes terms.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms THEN
    RAISE EXCEPTION '4: office_terms moved % -> %. This file seats nobody.', b.terms, n;
  END IF;

  -- 5. No candidacy was created or removed — 77 existing rows were linked, that is all.
  SELECT count(*) INTO n FROM essentials.race_candidates;
  IF n <> b.race_candidates THEN
    RAISE EXCEPTION '5: race_candidates moved % -> %.', b.race_candidates, n;
  END IF;

  -- 6. 🔴 THE WAVE CAN NOW SEE EVERY MAINE LEGISLATIVE WINNER. This is the measurement the
  --    seating file's P5 will depend on, taken here while the pre-image is still in hand.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE lower(d.state) = 'me' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03'
     AND (win.value ->> 'id') IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % Maine legislative winner(s) still have no person record.', n;
  END IF;

  -- 7. ⚠ AND THE THREE SEATS WITH NO RECORDED RESULT ARE STILL INVISIBLE, which is correct:
  --    this file does not write a result. If this ever reads anything but 3, somebody recorded
  --    them and the seating wave's counts change.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
   WHERE lower(d.state) = 'me' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                      WHERE rc.race_id = r.id AND rc.result = 'won');
  IF n <> 3 THEN
    RAISE EXCEPTION '7: % Maine legislative race(s) have no recorded winner, expected 3 (House '
                    '86, House 96, Senate 18). The orientation roster names all three.', n;
  END IF;

  RAISE NOTICE 'CC_0474 OK: 59 politicians created, 18 linked (sitting members — 14 changing '
               'chamber under Maine''s term limits, 4 holding a local office), 77 '
               'race_candidates rows moved from NULL to a person, 0 terms written. All 183 '
               'Maine legislative winners are now visible to the wave.';
END $$;

COMMIT;
