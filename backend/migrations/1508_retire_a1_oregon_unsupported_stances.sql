-- 1508_retire_a1_oregon_unsupported_stances.sql
--
-- Retire 102 published stance answers across 60 Oregon officeholders whose cited page does not
-- contain the claim. This finishes cohort A1 of the stance re-sourcing backlog; migration 1507 took
-- the 86 that named an absent BILL, and these are the ones that named an absent policy, event or act.
--   Evidence:        data/stance-retirement/2026-07-31-a1-oregon-articlebody-audit.json
--   Rollback record: data/stance-retirement/2026-07-29-suspect-stance-backlog.csv carries
--                    politician_id, topic_id, value, write_in_text, reasoning and sources for every
--                    row deleted here, so this is fully reversible from the repo.
--
-- WHAT WAS TESTED. Each cited Ballotpedia page was fetched and only its ARTICLE BODY read
-- (#mw-content-text, script/style removed). For each row, the distinctive terms of its own reasoning
-- were searched for: multi-word capitalised phrases, hyphenated compounds and rare policy nouns.
-- Terms appearing on more than 25% of the 68-page corpus were discarded as uninformative, and so
-- were IDENTITY terms -- county, town, chamber title, alma mater -- which appear only because it is
-- that person's page. A row is here when NONE of its distinctive claim terms appear.
--
-- This judges the CITATION, not the claim. A row deleted here may still be true; it is not sourced
-- by what it cites, and an empty compass is honest where a confabulated one is a false statement
-- about a real person.
--
-- WHY THE IDENTITY FILTER IS LOAD-BEARING. Without it, 13 rows scored as supported on terms like
-- "House Majority Leader" (Fahey, three rows) and "Forest Grove" (McLain) -- the page names those
-- because of who she is, not because it documents the claim. With it, 6 rows retain support and are
-- NOT in this migration.
--
-- EVIDENCE THE TEST MEASURES SOMETHING REAL. One templated sentence, "Participated in May 2023
-- Senate Republican walkout opposing climate legislation", was applied to six different people.
-- "walkout" is present on the article body of exactly the three seated before 2023 -- Thatcher,
-- Hayden, Weber -- and absent for the three seated in 2025 -- Starr, Linthicum, Drazan. The same
-- claim, correctly separated.
--
-- Of those three false instances only TWO are retired here (Starr, Linthicum). Drazan's row also
-- names cap-and-trade, which IS on her page, so the mechanical rule scores it PARTIAL_SUPPORT and it
-- is held back. It is very likely still wrong -- a compound claim needs every clause evidenced and
-- its walkout clause is impossible, since her Senate term began 2025-10-24 -- but that is a judgement
-- the automatic test does not make. It stays live pending a human read rather than being swept in.
--
-- NOT RETIRED, and deliberately so: 27 rows carry no distinctive term to test, 9 belong to five
-- pages whose article body would not extract (Rob Wagner, James Manning, Travis Nelson, Nathan Sosa,
-- Paul Evans -- under 400 chars each, which means EXTRACTION failed, not that the terms are absent),
-- and 6 retain a genuine claim-term match. Scoring an unread page as a miss is the same false
-- negative as Ballotpedia's silent HTTP-202 empty body, and is not done here.
--
-- REPLACEMENT. Officeholders left with zero answers have last_stances_researched_at nulled, so they
-- re-enter the research queue rather than reading as already researched. Re-research must NOT use
-- Ballotpedia bios -- these rows failed precisely because those pages carry no position content.
-- The replacement source is the Oregon Legislature's own per-member roll calls (OLIS).
--
-- Idempotent: the target set is an explicit (politician_id, topic_id) list, so a re-run deletes
-- nothing. Structure follows migrations 1494 and 1507.

BEGIN;

CREATE TEMP TABLE _retire_1508 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1508 (politician_id, topic_id) VALUES
  ('402a00be-71c3-4584-b29f-bf493365bffb'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Christine Drazan · Healthcare Access · absent: government-run, market-based, medicaid
  ('402a00be-71c3-4584-b29f-bf493365bffb'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Christine Drazan · Immigration and Treatment of Immigrants · absent: sanctuary
  ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Bruce Starr · Climate Change and Environmental Protection · absent: walkout
  ('f3fb09eb-adb0-4543-b6a2-32f90003569b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Darin Harbick · Taxation and Public Spending · absent: Corporate Activity Tax, anti-tax
  ('50eab431-7b51-4a56-acaa-61af3509c298'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Diane Linthicum · Climate Change and Environmental Protection · absent: walkout
  ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Lisa Fragala · Civil Rights and Social Justice · absent: Voted YES, anti-discrimination
  ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Lisa Fragala · Healthcare Access · absent: medicaid
  ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Mari Watanabe · Civil Rights and Social Justice · absent: anti-discrimination
  ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Mari Watanabe · Healthcare Access · absent: medicaid
  ('13ce589f-756e-4968-881f-c8cc95dae404'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Noah Robinson · Climate Change and Environmental Protection · absent: cap-and-trade, walkout, quorum
  ('13ce589f-756e-4968-881f-c8cc95dae404'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Noah Robinson · Taxation and Public Spending · absent: anti-tax
  ('2b9da845-9fab-406f-97c3-1afe895c254b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Shannon Isadore · Civil Rights and Social Justice · absent: anti-discrimination, equity-focused
  ('2b9da845-9fab-406f-97c3-1afe895c254b'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Shannon Isadore · Healthcare Access · absent: medicaid
  ('86d23630-36ff-48a7-b2ac-6071a0cabd64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Todd Nash · Climate Change and Environmental Protection · absent: walkout
  ('0bffa985-c83b-41c3-8901-19b7dac86cd7'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- April Dobson · Civil Rights and Social Justice · absent: anti-discrimination
  ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Lamar Wise · Civil Rights and Social Justice · absent: anti-discrimination, equity-focused
  ('7360da53-a6df-42d9-89b4-fff76af23de6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Lesly Muñoz · Civil Rights and Social Justice · absent: anti-discrimination
  ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Sue Rieke Smith · Healthcare Access · absent: medicaid
  ('d3371858-924e-4f76-b756-f2d7bb3c9b8d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Willy Chotzen · Civil Rights and Social Justice · absent: anti-discrimination
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),  -- Dan Rayfield · Medicare / Medicaid · absent: medicaid
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),  -- Dan Rayfield · Same-Sex Marriage · absent: Respect for Marriage Act
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),  -- Dan Rayfield · School Vouchers & Public Education Funding · absent: voucher
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),  -- Dan Rayfield · State Redistricting and Gerrymandering · absent: redistricting
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Dan Rayfield · Taxation and Public Spending · absent: middle-class
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Elizabeth Steiner · Civil Rights and Social Justice · absent: anti-discrimination
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Elizabeth Steiner · Healthcare Access · absent: medicaid, parity
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Elizabeth Steiner · Immigration and Treatment of Immigrants · absent: sanctuary
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),  -- Elizabeth Steiner · Medicare / Medicaid · absent: medicaid, medicare
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),  -- Elizabeth Steiner · School Vouchers & Public Education Funding · absent: voucher
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Maxine Dexter · Criminalization of Homelessness · absent: Housing First
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),  -- Maxine Dexter · Voting Rights and Electoral Integrity · absent: same-day
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Christina Stephenson · Healthcare Access · absent: medicaid
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Christina Stephenson · Public Safety Approach · absent: community-centered
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),  -- Christina Stephenson · Same-Sex Marriage · absent: anti-discrimination
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),  -- Janelle Bynum · Same-Sex Marriage · absent: Respect for Marriage Act, same-sex, codification
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),  -- Tina Kotek · State Redistricting and Gerrymandering · absent: democratic-controlled, redistricting
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Tina Kotek · Taxation and Public Spending · absent: high-income, surtax
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Lew Frederick · Civil Rights and Social Justice · absent: anti-discrimination
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Lew Frederick · Healthcare Access · absent: Oregon Health Plan
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Lew Frederick · Immigration and Treatment of Immigrants · absent: sanctuary, profiling
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),  -- Sara Gelser Blouin · Childcare Affordability & Access · absent: childcare, subsidies
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Sara Gelser Blouin · Criminalization of Homelessness · absent: services-first, criminalization, decriminalization
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Sara Gelser Blouin · Healthcare Access · absent: Oregon Health Plan
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Sara Gelser Blouin · Immigration and Treatment of Immigrants · absent: state-level
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Andrea Salinas · Campaign Finance Reform · absent: For the People Act
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Andrea Salinas · Reproductive Rights and Abortion Access · absent: Health Protection Act
  ('24398310-8e0c-487e-a11c-253e3060f77c'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),  -- Julie Fahey · Childcare Affordability & Access · absent: childcare
  ('24398310-8e0c-487e-a11c-253e3060f77c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Julie Fahey · Civil Rights and Social Justice · absent: anti-discrimination
  ('24398310-8e0c-487e-a11c-253e3060f77c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Julie Fahey · Healthcare Access · absent: medicaid
  ('b548a0f7-5086-4124-a510-49ef8f60f515'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Kim Thatcher · Healthcare Access · absent: Opposed Oregon Health Plan, government-run
  ('b548a0f7-5086-4124-a510-49ef8f60f515'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Kim Thatcher · Public Safety Approach · absent: decriminalization
  ('94105ea6-e6f7-4629-b30c-a8fe713e1cad'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Tobias Read · Civil Rights and Social Justice · absent: anti-discrimination
  ('94105ea6-e6f7-4629-b30c-a8fe713e1cad'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Tobias Read · Climate Change and Environmental Protection · absent: divesting
  ('94105ea6-e6f7-4629-b30c-a8fe713e1cad'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Tobias Read · Healthcare Access · absent: medicaid
  ('6b107b84-afbe-4141-8951-bafb65543dda'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Fred Girod · Climate Change and Environmental Protection · absent: walkout
  ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Kate Lieber · Healthcare Access · absent: Supported Oregon Health Plan
  ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Kathleen Taylor · Civil Rights and Social Justice · absent: anti-discrimination
  ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Kathleen Taylor · Healthcare Access · absent: Voted YES, Oregon Health Plan
  ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Kathleen Taylor · Immigration and Treatment of Immigrants · absent: sanctuary
  ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Kathleen Taylor · Taxation and Public Spending · absent: Voted YES
  ('252a2adf-68a5-4b5a-9024-d5635e2fbd88'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Mike McLane · Climate Change and Environmental Protection · absent: cap-and-trade, walkout
  ('252a2adf-68a5-4b5a-9024-d5635e2fbd88'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Mike McLane · Healthcare Access · absent: government-run, medicaid
  ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Courtney Neron Misslin · Healthcare Access · absent: Voted YES, Oregon Health Plan, medicaid
  ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Courtney Neron Misslin · Taxation and Public Spending · absent: Voted YES
  ('b6f5cd9e-a9d2-44ff-9027-0d931765f378'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Floyd Prozanski · Healthcare Access · absent: Voted YES, Oregon Health Plan, medicaid
  ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),  -- Janeen Sollman · Childcare Affordability & Access · absent: childcare
  ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Janeen Sollman · Healthcare Access · absent: Supported Oregon Health Plan
  ('36db8c55-4b20-408c-bd99-b8488d0ef344'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Mark Gamba · Civil Rights and Social Justice · absent: anti-discrimination
  ('36db8c55-4b20-408c-bd99-b8488d0ef344'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Mark Gamba · Immigration and Treatment of Immigrants · absent: immigrant-protective
  ('ca404c61-11af-43d9-9563-07dde3f7b8e7'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),  -- Nancy Nathanson · Childcare Affordability & Access · absent: childcare
  ('ca404c61-11af-43d9-9563-07dde3f7b8e7'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Nancy Nathanson · Civil Rights and Social Justice · absent: anti-discrimination
  ('ca404c61-11af-43d9-9563-07dde3f7b8e7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Nancy Nathanson · Healthcare Access · absent: medicaid
  ('a5a3918c-3e24-44fa-9573-440436a05b04'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Andrea Valderrama · Immigration and Treatment of Immigrants · absent: immigrant-protective
  ('14896652-e36b-4823-afb0-e92e3338929c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Annessa Hartman · Civil Rights and Social Justice · absent: anti-discrimination
  ('14896652-e36b-4823-afb0-e92e3338929c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Annessa Hartman · Healthcare Access · absent: medicaid
  ('5e29b685-1f2e-4963-83a8-a7bde5b5250e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Ben Bowman · Civil Rights and Social Justice · absent: anti-discrimination
  ('5e29b685-1f2e-4963-83a8-a7bde5b5250e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Ben Bowman · Healthcare Access · absent: medicaid
  ('22a1e980-4f15-435d-a0c4-1a08202d6bb5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Chris Gorsek · Healthcare Access · absent: Voted YES, Oregon Health Plan
  ('0e3b9216-cfb9-411f-b80e-684ccaae593f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Court Boice · Taxation and Public Spending · absent: Corporate Activity Tax, anti-tax
  ('631cc414-8793-42ec-b883-594ed7f0b249'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Deb Patterson · Civil Rights and Social Justice · absent: anti-discrimination
  ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Dick Anderson · Climate Change and Environmental Protection · absent: walkout, quorum
  ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Ken Helm · Civil Rights and Social Justice · absent: anti-discrimination
  ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Ken Helm · Healthcare Access · absent: medicaid
  ('3778353d-cbc9-43cf-866a-a7c01397503a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Kim Wallan · Taxation and Public Spending · absent: Corporate Activity Tax
  ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Lisa Reynolds · Civil Rights and Social Justice · absent: anti-discrimination
  ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Lisa Reynolds · Immigration and Treatment of Immigrants · absent: state-level
  ('be46ed6d-363e-46f4-89d4-c95d9af67db1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Mark Meek · Healthcare Access · absent: Voted YES, Oregon Health Plan, medicaid
  ('03af5908-a069-4ab7-91db-2f388a885bf9'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Pam Marsh · Healthcare Access · absent: medicaid
  ('37247ac1-5444-4fdd-b58e-123b5db4d0fe'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Zach Hudson · Civil Rights and Social Justice · absent: anti-discrimination
  ('37247ac1-5444-4fdd-b58e-123b5db4d0fe'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Zach Hudson · Healthcare Access · absent: medicaid
  ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Cyrus Javadi · Healthcare Access · absent: medicaid
  ('c5640f05-239a-47fd-97f3-e284859c1cc9'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Dacia Grayber · Civil Rights and Social Justice · absent: anti-discrimination
  ('73519742-09c3-4204-871b-076ff1397a14'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Daniel Nguyễn · Civil Rights and Social Justice · absent: anti-discrimination
  ('00ddecfd-648a-4118-82e6-a60327068b32'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- David Gomberg · Healthcare Access · absent: medicaid
  ('62decede-7149-40a1-a68a-16e2d3eb62a6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Farrah Chaichi · Civil Rights and Social Justice · absent: anti-discrimination
  ('2e668344-f025-489a-b870-1803269c11fc'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Hai Pham · Civil Rights and Social Justice · absent: anti-discrimination
  ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- John Lively · Healthcare Access · absent: Supported Medicaid, medicaid
  ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Jules Walters · Civil Rights and Social Justice · absent: anti-discrimination
  ('a703adb5-1086-471b-ba8b-2dbeddd8102b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Kayse Jama · Taxation and Public Spending · absent: low-income
  ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Ricki Ruiz · Civil Rights and Social Justice · absent: anti-discrimination
  ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Susan McLain · Immigration and Treatment of Immigrants · absent: immigrant-supportive
  ('9ada0539-e66c-444f-b220-86a8138b5277'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid);  -- Thủy Trần · Civil Rights and Social Justice · absent: anti-discrimination

-- Politicians who will be left with no answers at all, computed BEFORE the delete.
CREATE TEMP TABLE _emptied_1508 ON COMMIT DROP AS
SELECT a.politician_id FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM _retire_1508 r
          WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c USING _retire_1508 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1508 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- A timestamp with zero answers asserts research that no longer exists, and would keep these people
-- out of the re-research queue.
UPDATE essentials.politicians p SET last_stances_researched_at = NULL
  FROM _emptied_1508 e
 WHERE p.id = e.politician_id AND p.last_stances_researched_at IS NOT NULL;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_ts   int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1508 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1508 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN
    RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx;
  END IF;

  -- Nobody may be left carrying a research timestamp with no answers behind it.
  SELECT count(*) INTO v_ts
    FROM essentials.politicians p
    JOIN _emptied_1508 e ON e.politician_id = p.id
   WHERE p.last_stances_researched_at IS NOT NULL;
  IF v_ts <> 0 THEN
    RAISE EXCEPTION '% emptied politicians still carry a research timestamp', v_ts;
  END IF;
END $$;

COMMIT;
