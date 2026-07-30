-- 1503_civicpatch_tx_ma_contacts.sql
--
-- Backfill office contacts for 145 municipal officials we ALREADY HOLD, from the
-- vendored CC0 CivicPatch snapshot 928579c0 (backend/data/civicpatch/).
-- Approved scope: .planning/decisions/2026-07-30-civicpatch-api-decision.md
--
-- ENRICHMENT ONLY. Creates no politician and no office. Every row below is an EXACT 1:1
-- normalised-name match against a CURRENT officeholder in the same place; 4 near-matches
-- (the "Ben"/"Benjamin" shape) were held back for human review and are NOT here.
--
-- ADDITIVE ONLY. Each insert is guarded on the politician having no contact_type='office'
-- row at all, so nothing we already hold is overwritten. Re-running is a no-op.
--
-- WHY THEIR STALENESS DOES NOT LEAK IN. Their TX rows were scraped 2026-03/04, which
-- predates the May 2026 Texas uniform election (and Frisco's June runoff — Mark Hill was
-- sworn in 2026-07-07, while their file still names Jeff Cheney). 20 of their 169 records
-- name officials who have since left office. Those records match nobody in our current
-- roster and are therefore absent from this migration by construction: matching against
-- current holders IS the incumbency check. Do not "fix" the matcher to catch them.

BEGIN;

-- ma/place:springfield · Domenic J. Sarno · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd8449201-38b4-4851-b8a7-40b1bcf40161'::uuid, 'civicpatch:928579c0', NULL, '(413) 736-3111', 'https://www.springfield-ma.gov/cos/mayor', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd8449201-38b4-4851-b8a7-40b1bcf40161'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Michael A. Fenton · Council President - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'fc17d6ea-c967-4d0d-a636-41b1d136765f'::uuid, 'civicpatch:928579c0', 'mfenton@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'fc17d6ea-c967-4d0d-a636-41b1d136765f'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Melvin A. Edwards · Council Vice President - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7d024231-0fa3-4787-8cc0-92fa6903711c'::uuid, 'civicpatch:928579c0', 'melvinspeaks@msn.com', '(413) 348-8036', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7d024231-0fa3-4787-8cc0-92fa6903711c'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Maria Perez · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f9dfe8ab-8b7e-427f-933f-be4ecbb1168d'::uuid, 'civicpatch:928579c0', 'mariaperezcitycouncil@gmail.com', '(413) 219-1038', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f9dfe8ab-8b7e-427f-933f-be4ecbb1168d'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Malo L. Brown · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3da0fc8c-35d5-4c14-a53b-89f7c6a7bdd2'::uuid, 'civicpatch:928579c0', 'malomiajane@yahoo.com', '(413) 316-4743', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3da0fc8c-35d5-4c14-a53b-89f7c6a7bdd2'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Lavar Click-Bruce · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b0df471c-db3a-4f10-8817-f14c7e611593'::uuid, 'civicpatch:928579c0', 'lclick-bruce@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b0df471c-db3a-4f10-8817-f14c7e611593'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Gerry Martin · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'de39ab94-3663-4b2e-be14-222e79a87638'::uuid, 'civicpatch:928579c0', 'gmartin@springfieldcityhall.com', '(413) 342-6537', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'de39ab94-3663-4b2e-be14-222e79a87638'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Zaida Govan · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '1b987aa5-fba6-4ce5-a926-8cb957b43410'::uuid, 'civicpatch:928579c0', 'zaida.govan@yahoo.com', '(413) 301-2533', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '1b987aa5-fba6-4ce5-a926-8cb957b43410'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Justin Hurst · Council Member - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '91e24565-79b3-4473-9d7b-3ca72beceed2'::uuid, 'civicpatch:928579c0', 'jhurst@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '91e24565-79b3-4473-9d7b-3ca72beceed2'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Jose Delgado · Council Member - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a265eb66-0b1e-45e5-9d55-f5565e0540f8'::uuid, 'civicpatch:928579c0', 'jdelgado@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a265eb66-0b1e-45e5-9d55-f5565e0540f8'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Kateri Walsh · Council Member - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6db2abd4-86ce-414a-ba80-6565e6e3b23d'::uuid, 'civicpatch:928579c0', 'kwalsh@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6db2abd4-86ce-414a-ba80-6565e6e3b23d'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Tracye Whitfield · Council Member - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8f7f44a0-2580-4e32-97a1-e8341c6b155f'::uuid, 'civicpatch:928579c0', 'twhitfield@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8f7f44a0-2580-4e32-97a1-e8341c6b155f'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · Brian Santaniello · Council Member - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd19a9e26-2ba1-4ea0-8bfe-ab69447ed769'::uuid, 'civicpatch:928579c0', 'bsantaniello@springfieldcityhall.com', '(413) 787-6170', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd19a9e26-2ba1-4ea0-8bfe-ab69447ed769'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Ben Trahan · Council Member - Mayor Pro Tempore - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0c983f9c-b510-4c70-a6b3-dc328b68b1f5'::uuid, 'civicpatch:928579c0', 'ben.trahan@allentx.gov', '(214) 509-4126', 'https://www.cityofallen.org/business_detail_T4_R86.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0c983f9c-b510-4c70-a6b3-dc328b68b1f5'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Michael Schaeffer · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c7a0ecf6-b416-474b-9647-a25e404f4bc4'::uuid, 'civicpatch:928579c0', 'michael.schaeffer@allentx.gov', '(214) 509-4121', 'https://www.cityofallen.org/business_detail_T4_R21.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c7a0ecf6-b416-474b-9647-a25e404f4bc4'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Tommy Baril · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3b15d821-fc1e-4e7b-bda0-13a669a77a27'::uuid, 'civicpatch:928579c0', 'tommy.baril@allentx.gov', '(214) 509-4122', 'https://www.cityofallen.org/business_detail_T4_R78.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3b15d821-fc1e-4e7b-bda0-13a669a77a27'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Ken Cook · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8626a6f8-88c9-456e-b484-499ac8849441'::uuid, 'civicpatch:928579c0', 'ken.cook@allentx.gov', '(214) 509-4123', 'https://www.cityofallen.org/business_detail_T4_R82.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8626a6f8-88c9-456e-b484-499ac8849441'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Amy Gnadt · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08'::uuid, 'civicpatch:928579c0', 'amy.gnadt@allentx.gov', '(214) 509-4124', 'https://www.cityofallen.org/business_detail_T4_R83.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08'::uuid AND c.contact_type = 'office');

-- tx/place:allen · Carl Clemencich · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f72c8a0c-61dd-4a86-a205-171e331fcaee'::uuid, 'civicpatch:928579c0', 'carl.clemencich@allentx.gov', '(214) 509-4125', 'https://www.cityofallen.org/business_detail_T4_R92.php', 'office', '2026-03-19T04:29:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f72c8a0c-61dd-4a86-a205-171e331fcaee'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Pete Cain · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd9710a3e-4679-44a5-8bfe-ddbb7b376ab5'::uuid, 'civicpatch:928579c0', 'pcain@annatexas.gov', '(972) 924-3325', 'https://annatexas.gov/1354/pete-cain', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd9710a3e-4679-44a5-8bfe-ddbb7b376ab5'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Kevin Toten · Mayor Pro Tempore - Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d'::uuid, 'civicpatch:928579c0', 'ktoten@annatexas.gov', NULL, 'https://annatexas.gov/1072/kevin-toten', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Nathan Bryan · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '94d3e41c-60b6-4803-b937-1877aeae84df'::uuid, 'civicpatch:928579c0', 'ntbryan@annatexas.gov', NULL, 'https://annatexas.gov/1612/nathan-bryan', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '94d3e41c-60b6-4803-b937-1877aeae84df'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Kelly Patterson-Herndon · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6a08be1a-2535-487c-a17c-f2f38263d504'::uuid, 'civicpatch:928579c0', 'kherndon@annatexas.gov', NULL, 'https://annatexas.gov/1562/kelly-patterson-herndon', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6a08be1a-2535-487c-a17c-f2f38263d504'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Elden Baker · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3842838e-2015-4136-95d2-97f4f20366b1'::uuid, 'civicpatch:928579c0', 'ebaker@annatexas.gov', NULL, 'https://annatexas.gov/1426/elden-baker', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3842838e-2015-4136-95d2-97f4f20366b1'::uuid AND c.contact_type = 'office');

-- tx/place:anna · Manny Singh · Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f920ca1a-8263-4662-aa21-1f5964dfa61d'::uuid, 'civicpatch:928579c0', 'msingh@annatexas.gov', NULL, 'https://annatexas.gov/1607/manny-singh', 'office', '2026-03-21T15:47:24+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f920ca1a-8263-4662-aa21-1f5964dfa61d'::uuid AND c.contact_type = 'office');

-- tx/place:blue_ridge · Rhonda Williams · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a9db2052-5fbd-4370-9f78-f8ba07b6e452'::uuid, 'civicpatch:928579c0', 'jlawrence@blueridgecity.com', '(972) 752-5791', 'https://blueridgecity.com/council', 'office', '2026-04-04T03:28:32+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a9db2052-5fbd-4370-9f78-f8ba07b6e452'::uuid AND c.contact_type = 'office');

-- tx/place:blue_ridge · Linda Braly · Council Member - Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c7bfdeff-ba51-479c-b956-331a6562c21b'::uuid, 'civicpatch:928579c0', 'council2@blueridgecity.com', '(972) 752-5791', 'https://blueridgecity.com/council', 'office', '2026-04-04T03:28:32+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c7bfdeff-ba51-479c-b956-331a6562c21b'::uuid AND c.contact_type = 'office');

-- tx/place:blue_ridge · Trenton Sissom · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b85c7a20-744d-4065-b240-530aceda65bc'::uuid, 'civicpatch:928579c0', 'jlawrence@blueridgecity.com', '(972) 752-5791', 'https://blueridgecity.com/council', 'office', '2026-04-04T03:28:32+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b85c7a20-744d-4065-b240-530aceda65bc'::uuid AND c.contact_type = 'office');

-- tx/place:blue_ridge · Wendy Mattingly · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ff6a17d4-7067-4566-9241-17aaf9f45b34'::uuid, 'civicpatch:928579c0', 'jlawrence@blueridgecity.com', '(972) 752-5791', 'https://blueridgecity.com/council', 'office', '2026-04-04T03:28:32+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ff6a17d4-7067-4566-9241-17aaf9f45b34'::uuid AND c.contact_type = 'office');

-- tx/place:blue_ridge · David Apple · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '831ce2c9-bc43-487a-a0d6-a0b9c776e7d2'::uuid, 'civicpatch:928579c0', 'jlawrence@blueridgecity.com', '(972) 752-5791', 'https://blueridgecity.com/council', 'office', '2026-04-04T03:28:32+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '831ce2c9-bc43-487a-a0d6-a0b9c776e7d2'::uuid AND c.contact_type = 'office');

-- tx/place:celina · Ryan Tubbs · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'cb9d6924-77d1-49c9-ab3d-778b0201e623'::uuid, 'civicpatch:928579c0', 'rtubbs@celina-tx.gov', '(972) 382-2682', 'https://celina-tx.gov/295/office-of-the-mayor', 'office', '2026-03-28T18:44:05+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'cb9d6924-77d1-49c9-ab3d-778b0201e623'::uuid AND c.contact_type = 'office');

-- tx/place:celina · Eddie Cawlfield · Council Member - Mayor Pro Tempore - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '780b7f22-755a-4a92-8bd3-78978edbc564'::uuid, 'civicpatch:928579c0', 'ecawlfield@celina-tx.gov', NULL, 'https://celina-tx.gov/directory.aspx?EID=311', 'office', '2026-03-28T18:44:05+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '780b7f22-755a-4a92-8bd3-78978edbc564'::uuid AND c.contact_type = 'office');

-- tx/place:celina · Brandon Grumbles · Deputy Mayor Pro Tempore - Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b167c501-2c43-48b3-8922-e00e060985b3'::uuid, 'civicpatch:928579c0', 'bgrumbles@celina-tx.gov', NULL, 'https://celina-tx.gov/directory.aspx?EID=310', 'office', '2026-03-28T18:44:05+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b167c501-2c43-48b3-8922-e00e060985b3'::uuid AND c.contact_type = 'office');

-- tx/place:celina · Philip Ferguson · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7395cbed-4d2b-42f4-aeff-04b7427b0bc0'::uuid, 'civicpatch:928579c0', 'pferguson@celina-tx.gov', NULL, 'https://celina-tx.gov/directory.aspx?EID=7', 'office', '2026-03-28T18:44:05+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7395cbed-4d2b-42f4-aeff-04b7427b0bc0'::uuid AND c.contact_type = 'office');

-- tx/place:celina · Andy Hopkins · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c36e6f78-4828-49cd-9010-988c8a7c7be4'::uuid, 'civicpatch:928579c0', 'ahopkins@celina-tx.gov', NULL, 'https://celina-tx.gov/directory.aspx?EID=3', 'office', '2026-03-28T18:44:05+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c36e6f78-4828-49cd-9010-988c8a7c7be4'::uuid AND c.contact_type = 'office');

-- tx/place:fairview · John Hubbard · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '72b80f6a-82b3-4872-a10f-e95e2cd3f90f'::uuid, 'civicpatch:928579c0', 'mayor@fairviewtexas.org', '(972) 562-0522', 'https://www.fairviewtexas.org/government/town-council.html', 'office', '2026-04-01T01:28:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '72b80f6a-82b3-4872-a10f-e95e2cd3f90f'::uuid AND c.contact_type = 'office');

-- tx/place:fairview · Rich Connelly · Council Member - Seat 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9e2aa590-23e2-4217-84b7-418ba9dc1414'::uuid, 'civicpatch:928579c0', 'rconnelly@fairviewtexas.org', '(972) 562-0522', 'https://www.fairviewtexas.org/government/town-council.html', 'office', '2026-04-01T01:28:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9e2aa590-23e2-4217-84b7-418ba9dc1414'::uuid AND c.contact_type = 'office');

-- tx/place:fairview · Jill Hawkins · Council Member - Seat 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'::uuid, 'civicpatch:928579c0', 'jhawkins@fairviewtexas.org', '(972) 562-0522', 'https://www.fairviewtexas.org/government/town-council.html', 'office', '2026-04-01T01:28:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'::uuid AND c.contact_type = 'office');

-- tx/place:fairview · Pat Sheehan · Council Member - Seat 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '38e20826-63c9-4eef-a4e1-ea77aa6892e2'::uuid, 'civicpatch:928579c0', 'psheehan@fairviewtexas.org', '(972) 562-0522', 'https://www.fairviewtexas.org/government/town-council.html', 'office', '2026-04-01T01:28:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '38e20826-63c9-4eef-a4e1-ea77aa6892e2'::uuid AND c.contact_type = 'office');

-- tx/place:fairview · Lakia Works · Council Member - Seat 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9e80fff4-8b89-4c38-b33e-a1a0fff7e080'::uuid, 'civicpatch:928579c0', 'lworks@fairviewtexas.org', '(972) 562-0522', 'https://www.fairviewtexas.org/government/town-council.html', 'office', '2026-04-01T01:28:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9e80fff4-8b89-4c38-b33e-a1a0fff7e080'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Craig Overstreet · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e7f04a34-b8e7-4978-87d6-60ece59ced92'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/mayor-council/directory-listing/craig-overstreet', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e7f04a34-b8e7-4978-87d6-60ece59ced92'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Mike Henry · Council Member - Mayor Pro Tempore - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5712d682-ffd5-4e6d-afa8-9707613fd838'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/city-council/directory-listing/mike-henry', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5712d682-ffd5-4e6d-afa8-9707613fd838'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Coleman Strickland · Council Member - Deputy Mayor Pro Tempore - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '94252f68-40d6-4e82-8f10-1015a85fa403'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/city-council/directory-listing/coleman-strickland', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '94252f68-40d6-4e82-8f10-1015a85fa403'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Russell Chandler · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eb6c2d0f-ea9f-420c-81bb-eb3d6287214d'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/mayor-council/directory-listing/russell-chandler', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eb6c2d0f-ea9f-420c-81bb-eb3d6287214d'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Kristi Mondy · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'fae40714-a182-4e37-9bac-1afe754b4561'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/city-council/directory-listing/kristi-mondy', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'fae40714-a182-4e37-9bac-1afe754b4561'::uuid AND c.contact_type = 'office');

-- tx/place:farmersville · Tonya Fox · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eab3bbe2-4103-49a2-a0bf-d45acc9d54e0'::uuid, 'civicpatch:928579c0', NULL, '(972) 782-6151', 'https://farmersvilletx.com/city-council/directory-listing/tonya-fox', 'office', '2026-03-28T04:51:45+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eab3bbe2-4103-49a2-a0bf-d45acc9d54e0'::uuid AND c.contact_type = 'office');

-- tx/place:frisco · Angelia Pelham · Mayor Pro Tempore - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5b346b19-d6ee-47e2-acbf-5780ca423264'::uuid, 'civicpatch:928579c0', 'apelham@friscotexas.gov', '(972) 292-5053', 'https://www.friscotexas.gov/directory.aspx?EID=683', 'office', '2026-03-12T02:50:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5b346b19-d6ee-47e2-acbf-5780ca423264'::uuid AND c.contact_type = 'office');

-- tx/place:frisco · Laura Rummel · Deputy Mayor Pro Tempore - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '76c3fa35-a286-4fa1-b6da-40300d91f33e'::uuid, 'civicpatch:928579c0', 'lrummel@friscotexas.gov', '(972) 292-5055', 'https://www.friscotexas.gov/directory.aspx?EID=189', 'office', '2026-03-12T02:50:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '76c3fa35-a286-4fa1-b6da-40300d91f33e'::uuid AND c.contact_type = 'office');

-- tx/place:frisco · Ann Anderson · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'da010ea4-257d-4582-98cb-ee90063aa31d'::uuid, 'civicpatch:928579c0', 'aanderson@friscotexas.gov', '(972) 292-5051', 'https://www.friscotexas.gov/directory.aspx?EID=925', 'office', '2026-03-12T02:50:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'da010ea4-257d-4582-98cb-ee90063aa31d'::uuid AND c.contact_type = 'office');

-- tx/place:frisco · Burt Thakur · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c11bf372-8190-4b45-b80a-cbd0fb2ba401'::uuid, 'civicpatch:928579c0', 'bthakur@friscotexas.gov', '(972) 292-5052', 'https://www.friscotexas.gov/directory.aspx?EID=888', 'office', '2026-03-12T02:50:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c11bf372-8190-4b45-b80a-cbd0fb2ba401'::uuid AND c.contact_type = 'office');

-- tx/place:frisco · Jared Elad · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5d8acfc7-5643-418b-a474-3d87898f4e17'::uuid, 'civicpatch:928579c0', 'jelad@friscotexas.gov', '(972) 292-5054', 'https://www.friscotexas.gov/directory.aspx?EID=190', 'office', '2026-03-12T02:50:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5d8acfc7-5643-418b-a474-3d87898f4e17'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · Jason Turney · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f3eb38f1-a044-4c75-82c8-80750f40543e'::uuid, 'civicpatch:928579c0', 'jturney@cityofjosephinetx.com', '(214) 326-4908', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f3eb38f1-a044-4c75-82c8-80750f40543e'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · April Aurand · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c5411e93-3b1c-42e3-a0c8-00491804cada'::uuid, 'civicpatch:928579c0', 'aaurand@cityofjosephinetx.com', '(945) 220-2066', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c5411e93-3b1c-42e3-a0c8-00491804cada'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · Jane Ridgway · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b6bf2154-78d1-4d12-8881-5f83640beee2'::uuid, 'civicpatch:928579c0', 'jridgway@cityofjosephinetx.com', '(214) 842-1428', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b6bf2154-78d1-4d12-8881-5f83640beee2'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · Alex Esquivel · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '215618d2-17ac-4946-a511-c0e9a95164b6'::uuid, 'civicpatch:928579c0', 'aesquivel@cityofjosephinetx.com', '(214) 901-3682', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '215618d2-17ac-4946-a511-c0e9a95164b6'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · Pam Sardo · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f90a82e8-24db-433c-a8dd-6b5098f0a20e'::uuid, 'civicpatch:928579c0', 'psardo@cityofjosephinetx.com', '(214) 620-5742', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f90a82e8-24db-433c-a8dd-6b5098f0a20e'::uuid AND c.contact_type = 'office');

-- tx/place:josephine · Gary Chappell · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b48179c3-8e73-47a8-9e05-f9a8a24d4ab7'::uuid, 'civicpatch:928579c0', 'gchappell@cityofjosephinetx.com', '(214) 449-3827', 'https://cityofjosephinetx.com/government/city-council', 'office', '2026-03-28T04:55:14+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b48179c3-8e73-47a8-9e05-f9a8a24d4ab7'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Vicki Sanson · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3ae0e255-7dca-486d-abbf-f8d2ebd5e7be'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3ae0e255-7dca-486d-abbf-f8d2ebd5e7be'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Mike Shepard · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e8df1e64-e5c3-4417-bccd-fb176be11f39'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e8df1e64-e5c3-4417-bccd-fb176be11f39'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Mike Cook · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f4ee71a6-8a14-4727-aa39-716fae402f60'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f4ee71a6-8a14-4727-aa39-716fae402f60'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Travis Jacob · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd53f9122-face-4b22-a5b1-66ca6dc49997'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd53f9122-face-4b22-a5b1-66ca6dc49997'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Rachel Dumas · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '62d609ff-284a-493e-a2ba-70c11bf87619'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '62d609ff-284a-493e-a2ba-70c11bf87619'::uuid AND c.contact_type = 'office');

-- tx/place:lavon · Lindsey Hedge · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0997e0f6-24ed-4d7e-964a-bd1069479352'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://lavontx.gov/city-council/', 'office', '2026-03-28T04:51:13+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0997e0f6-24ed-4d7e-964a-bd1069479352'::uuid AND c.contact_type = 'office');

-- tx/place:longview · Kristen Ishihara · Mayor - At-Large
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://www.longviewtexas.gov/mayor', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0'::uuid AND c.contact_type = 'office');

-- tx/place:longview · Derrick Conley · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c723b079-c7db-4376-b8d3-72ac896fefe2'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://www.longviewtexas.gov/2201/District-1', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c723b079-c7db-4376-b8d3-72ac896fefe2'::uuid AND c.contact_type = 'office');

-- tx/place:longview · Shannon Moore · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd55159ff-7c27-4313-b464-722f653fd7b7'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://www.longviewtexas.gov/2203/District-2---Shannon-Moore', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd55159ff-7c27-4313-b464-722f653fd7b7'::uuid AND c.contact_type = 'office');

-- tx/place:longview · John Nustad · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '94957758-20db-4590-8cc9-ce54c24e2449'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://longviewtexas.gov/2205/District-4---Kristen-Ishihara', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '94957758-20db-4590-8cc9-ce54c24e2449'::uuid AND c.contact_type = 'office');

-- tx/place:longview · Jody Berryhill · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'feb872f2-cd11-42bc-8a83-22e12dbc6207'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://www.longviewtexas.gov/2206/District-5---Jody-Berryhill', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'feb872f2-cd11-42bc-8a83-22e12dbc6207'::uuid AND c.contact_type = 'office');

-- tx/place:longview · Sidney Allen · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '2baab241-b3c5-48e9-b9a6-fd29b7b77beb'::uuid, 'civicpatch:928579c0', NULL, '(903) 237-1021', 'https://www.longviewtexas.gov/2207/District-6---Sidney-Allen', 'office', '2026-03-19T17:13:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '2baab241-b3c5-48e9-b9a6-fd29b7b77beb'::uuid AND c.contact_type = 'office');

-- tx/place:lowry_crossing · Pat Kelly · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6f199ec9-ba4a-4c0d-b6e3-bae97e0da847'::uuid, 'civicpatch:928579c0', 'pkelly@lowrycrossingtexas.org', NULL, 'https://www.lowrycrossingtexas.org/operations/city_council.php', 'office', '2026-03-28T21:39:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6f199ec9-ba4a-4c0d-b6e3-bae97e0da847'::uuid AND c.contact_type = 'office');

-- tx/place:lowry_crossing · Scott Pitchure · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e84f56af-ad73-4bec-8e4c-efccb8854cb1'::uuid, 'civicpatch:928579c0', 'spitchure@lowrycrossingtexas.org', NULL, 'https://www.lowrycrossingtexas.org/operations/city_council.php', 'office', '2026-03-28T21:39:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e84f56af-ad73-4bec-8e4c-efccb8854cb1'::uuid AND c.contact_type = 'office');

-- tx/place:lowry_crossing · Tammy Hodges · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eb142dfb-2208-4d3c-afe7-d2b64708129b'::uuid, 'civicpatch:928579c0', 'thodges@lowrycrossingtexas.org', NULL, 'https://www.lowrycrossingtexas.org/operations/city_council.php', 'office', '2026-03-28T21:39:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eb142dfb-2208-4d3c-afe7-d2b64708129b'::uuid AND c.contact_type = 'office');

-- tx/place:lucas · Dusty Kuykendall · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0ea8bc33-1629-41b4-8ae9-da74c3e2b44c'::uuid, 'civicpatch:928579c0', 'dkuykendall@lucastexas.us', '(972) 912-1211', 'https://lucastexas.us/417/a-message-from-the-mayor', 'office', '2026-03-23T21:28:22+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0ea8bc33-1629-41b4-8ae9-da74c3e2b44c'::uuid AND c.contact_type = 'office');

-- tx/place:lucas · Debbie Fisher · Council Member - Mayor Pro Tempore - Seat 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8d24cdb6-64d1-4597-a66e-71bc723391d7'::uuid, 'civicpatch:928579c0', 'dfisher@lucastexas.us', '(972) 912-1211', 'https://lucastexas.us/directory.aspx?EID=11', 'office', '2026-03-23T21:28:22+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8d24cdb6-64d1-4597-a66e-71bc723391d7'::uuid AND c.contact_type = 'office');

-- tx/place:lucas · Chris Bierman · Council Member - Seat 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ada1526e-32a3-47b2-9535-c4988e8db633'::uuid, 'civicpatch:928579c0', 'cbierman@lucastexas.us', '(972) 912-1211', 'https://lucastexas.us/directory.aspx?EID=14', 'office', '2026-03-23T21:28:22+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ada1526e-32a3-47b2-9535-c4988e8db633'::uuid AND c.contact_type = 'office');

-- tx/place:lucas · Phil Lawrence · Council Member - Seat 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bf1f8150-ae29-42ef-8b50-b2619e8d46ca'::uuid, 'civicpatch:928579c0', 'plawrence@lucastexas.us', '(972) 912-1211', 'https://lucastexas.us/directory.aspx?EID=15', 'office', '2026-03-23T21:28:22+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bf1f8150-ae29-42ef-8b50-b2619e8d46ca'::uuid AND c.contact_type = 'office');

-- tx/place:lucas · Neil Peterson · Council Member - Seat 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '72c0de8c-38b0-4470-a0d0-9d7a71986be0'::uuid, 'civicpatch:928579c0', 'npeterson@lucastexas.us', '(972) 912-1211', 'https://lucastexas.us/directory.aspx?EID=16', 'office', '2026-03-23T21:28:22+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '72c0de8c-38b0-4470-a0d0-9d7a71986be0'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Bill Cox · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '1c31b159-d4c1-4756-ba81-a247dbf0af8f'::uuid, 'civicpatch:928579c0', 'mayor@mckinneytexas.org', '(972) 547-7507', 'https://www.mckinneytexas.org/1167/Council-Members#Mayor', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '1c31b159-d4c1-4756-ba81-a247dbf0af8f'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Geré Feltus · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '23ba75d2-6eed-4b71-9669-78ab3bb82e98'::uuid, 'civicpatch:928579c0', 'district3@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#District3', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Justin Beller · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723'::uuid, 'civicpatch:928579c0', 'district1@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#District1', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Patrick Cloutier · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '27578980-2e6c-4639-879a-70b510566d0f'::uuid, 'civicpatch:928579c0', 'district2@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#District2', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '27578980-2e6c-4639-879a-70b510566d0f'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Rick Franklin · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6ee726c1-79af-4fef-abb8-fa7f4208ae14'::uuid, 'civicpatch:928579c0', 'district4@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#District4', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Ernest Lynch · Council Member - At-Large 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e'::uuid, 'civicpatch:928579c0', 'atlarge1@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#AtLarge1', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e'::uuid AND c.contact_type = 'office');

-- tx/place:mckinney · Michael Jones · Council Member - At-Large 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '09dbafc2-9252-40e4-9a1c-afda5b069f2e'::uuid, 'civicpatch:928579c0', 'atlarge2@mckinneytexas.org', NULL, 'https://www.mckinneytexas.org/1167/Council-Members#AtLarge2', 'office', '2026-03-12T02:51:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '09dbafc2-9252-40e4-9a1c-afda5b069f2e'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Jay Northcut · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b8d0cef2-3787-4074-9d85-81a9d27aaef8'::uuid, 'civicpatch:928579c0', 'mayor@cityofmelissa.com', NULL, 'https://cityofmelissa.com/Archive.aspx?AMID=50', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b8d0cef2-3787-4074-9d85-81a9d27aaef8'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Preston Taylor · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3e377dbe-2c37-41ed-a65d-664de75318ae'::uuid, 'civicpatch:928579c0', 'place1@cityofmelissa.com', NULL, 'https://cityofmelissa.com/Archive.aspx?AMID=50', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3e377dbe-2c37-41ed-a65d-664de75318ae'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Rendell Hendrickson · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'af2697d7-f766-4ddd-8b61-65e5d0c2df70'::uuid, 'civicpatch:928579c0', 'place2@cityofmelissa.com', NULL, 'https://cityofmelissa.com/202/City-Council', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'af2697d7-f766-4ddd-8b61-65e5d0c2df70'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Dana Conklin · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '30680496-7464-495c-a9bc-eb44cc6b84b8'::uuid, 'civicpatch:928579c0', 'place3@cityofmelissa.com', NULL, 'https://cityofmelissa.com/202/City-Council', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '30680496-7464-495c-a9bc-eb44cc6b84b8'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Joseph Armstrong · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '12d3560f-3b07-4fe7-b8c4-c2466c13e7eb'::uuid, 'civicpatch:928579c0', 'place4@cityofmelissa.com', NULL, 'https://cityofmelissa.com/Archive.aspx?AMID=50', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '12d3560f-3b07-4fe7-b8c4-c2466c13e7eb'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Craig Ackerman · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c5d9869d-6e7b-448d-bb48-43c2cd795d9a'::uuid, 'civicpatch:928579c0', 'cackerman@cityofmelissa.com', NULL, 'https://cityofmelissa.com/Archive.aspx?AMID=50', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c5d9869d-6e7b-448d-bb48-43c2cd795d9a'::uuid AND c.contact_type = 'office');

-- tx/place:melissa · Sean Lehr · Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b3602d0c-9af7-4baf-a96c-a15be063c272'::uuid, 'civicpatch:928579c0', 'place6@cityofmelissa.com', NULL, 'https://cityofmelissa.com/Archive.aspx?AMID=50', 'office', '2026-03-19T19:02:37+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b3602d0c-9af7-4baf-a96c-a15be063c272'::uuid AND c.contact_type = 'office');

-- tx/place:murphy · Scott Bradley · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e8841ac4-bcae-4783-b24a-e6fb82f46da7'::uuid, 'civicpatch:928579c0', 'sbradley@murphytx.org', '(972) 468-4000', 'https://murphytx.org/directory.aspx?EID=6', 'office', '2026-03-28T18:33:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e8841ac4-bcae-4783-b24a-e6fb82f46da7'::uuid AND c.contact_type = 'office');

-- tx/place:murphy · Elizabeth Abraham · Mayor Pro Tempore - Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '094da72b-3f17-4ce8-9c2a-747acd125086'::uuid, 'civicpatch:928579c0', 'eabraham@murphytx.org', '(972) 468-4000', 'https://murphytx.org/directory.aspx?EID=7', 'office', '2026-03-28T18:33:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '094da72b-3f17-4ce8-9c2a-747acd125086'::uuid AND c.contact_type = 'office');

-- tx/place:murphy · Jené Butler · Deputy Mayor Pro Tempore - Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c0bf5333-e271-46db-a5f8-84ced3177b6b'::uuid, 'civicpatch:928579c0', 'jbutler@murphytx.org', NULL, 'https://murphytx.org/directory.aspx?EID=12', 'office', '2026-03-28T18:33:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c0bf5333-e271-46db-a5f8-84ced3177b6b'::uuid AND c.contact_type = 'office');

-- tx/place:murphy · Scott Smith · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bcd556db-a139-4b87-8887-a1bad73726ea'::uuid, 'civicpatch:928579c0', 'ssmith@murphytx.org', '(972) 468-4000', 'https://murphytx.org/directory.aspx?DID=5', 'office', '2026-03-28T18:33:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bcd556db-a139-4b87-8887-a1bad73726ea'::uuid AND c.contact_type = 'office');

-- tx/place:murphy · Ken Oltmann · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '965000e5-54b5-40d4-9bae-6f70519536db'::uuid, 'civicpatch:928579c0', 'koltmann@murphytx.org', NULL, 'https://murphytx.org/directory.aspx?EID=9', 'office', '2026-03-28T18:33:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '965000e5-54b5-40d4-9bae-6f70519536db'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Donald Deering · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '47a5349c-ea03-4fcf-8719-948c259a3753'::uuid, 'civicpatch:928579c0', 'mayor@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '47a5349c-ea03-4fcf-8719-948c259a3753'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Amanda Wilson · Council Member - Mayor Pro Tempore - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c41886b8-f4ad-4f06-a579-5140c8951c91'::uuid, 'civicpatch:928579c0', 'councilman3@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c41886b8-f4ad-4f06-a579-5140c8951c91'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Mike Laye · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f138261a-4e0b-4c53-b30a-18e30b76e614'::uuid, 'civicpatch:928579c0', 'councilman1@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f138261a-4e0b-4c53-b30a-18e30b76e614'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Paul Baker · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '988e1851-7b35-4bce-81ff-955412f8670b'::uuid, 'civicpatch:928579c0', 'councilman2@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '988e1851-7b35-4bce-81ff-955412f8670b'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Clayton Laughter · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6c1dc476-507b-43a8-9061-bdaf9eafec58'::uuid, 'civicpatch:928579c0', 'councilman4@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6c1dc476-507b-43a8-9061-bdaf9eafec58'::uuid AND c.contact_type = 'office');

-- tx/place:nevada · Derrick Little · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '51c0d0db-b3e6-4e71-960e-4809ad680e25'::uuid, 'civicpatch:928579c0', 'councilman5@cityofnevadatx.org', '(972) 853-0027', 'https://cityofnevadatx.org/government/city_council.php', 'office', '2026-04-01T18:31:17+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '51c0d0db-b3e6-4e71-960e-4809ad680e25'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Lee Pettle · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '61f73b44-c46d-4f1b-91a7-0d35c83feecb'::uuid, 'civicpatch:928579c0', 'lpettle@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '61f73b44-c46d-4f1b-91a7-0d35c83feecb'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Buddy Pilgrim · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '812359f8-3ea5-4815-91ca-7e5a4ba2ba0a'::uuid, 'civicpatch:928579c0', 'bpilgrim@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '812359f8-3ea5-4815-91ca-7e5a4ba2ba0a'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Roxanne Bogdan · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a32e8631-404d-49bd-a914-8b05febe9df5'::uuid, 'civicpatch:928579c0', 'rbogdan@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a32e8631-404d-49bd-a914-8b05febe9df5'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Colleen Halbert · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'fc09e53a-723c-4c34-97ab-9e0b692104a0'::uuid, 'civicpatch:928579c0', 'chalbert@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'fc09e53a-723c-4c34-97ab-9e0b692104a0'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Darrel Sharpe · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'aba6f016-e35d-4977-99e6-a2cfc079ad75'::uuid, 'civicpatch:928579c0', 'dsharpe@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'aba6f016-e35d-4977-99e6-a2cfc079ad75'::uuid AND c.contact_type = 'office');

-- tx/place:parker · Billy Barron · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e136a517-1772-4f16-9bd5-785828f524e8'::uuid, 'civicpatch:928579c0', 'bbarron@parkertexas.us', NULL, 'http://www.parkertexas.us/76/city-council', 'office', '2026-03-27T21:26:59+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e136a517-1772-4f16-9bd5-785828f524e8'::uuid AND c.contact_type = 'office');

-- tx/place:plano · John B. Muns · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5584e869-4a54-4a68-a3c8-c14db45a71c5'::uuid, 'civicpatch:928579c0', 'mayor@plano.gov', '(972) 941-7000', 'https://plano.gov/1349/mayor-john-b-muns', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Maria Tu · Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799'::uuid, 'civicpatch:928579c0', 'mariatu@plano.gov', '(972) 941-7107', 'https://plano.gov/1355/mayor-pro-tem-maria-tu', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Rick Horne · Deputy Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bc4a88d7-2f56-48fd-85db-fa1fd4f8547e'::uuid, 'civicpatch:928579c0', 'rickhorne@plano.gov', '(972) 941-7107', 'https://plano.gov/1356/deputy-mayor-pro-tem-rick-horne', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bc4a88d7-2f56-48fd-85db-fa1fd4f8547e'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Bob Kehr · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'de037c5c-9c00-40c5-ade2-3d322b4a0349'::uuid, 'civicpatch:928579c0', 'bobkehr@plano.gov', '(972) 941-7107', 'https://plano.gov/1354/councilmember-bob-kehr', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'de037c5c-9c00-40c5-ade2-3d322b4a0349'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Chris Krupa Downs · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '127b8e69-3900-438c-8361-2cfe24b6c6cf'::uuid, 'civicpatch:928579c0', 'chrisdowns@plano.gov', '(972) 941-7107', 'https://plano.gov/1353/councilmember-chris-krupa-downs', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '127b8e69-3900-438c-8361-2cfe24b6c6cf'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Steve Lavine · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ecef0481-27c7-4955-b822-83d64c7ef63f'::uuid, 'civicpatch:928579c0', 'stevelavine@plano.gov', '(972) 941-7107', 'https://plano.gov/1357/councilmember-steve-lavine', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ecef0481-27c7-4955-b822-83d64c7ef63f'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Shun Thomas · Council Member - Place 7
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '4272e5cb-40cf-42d9-a493-ae5ca04301bb'::uuid, 'civicpatch:928579c0', 'shunthomas@plano.gov', '(972) 941-7107', 'https://plano.gov/1358/councilmember-shun-thomas', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb'::uuid AND c.contact_type = 'office');

-- tx/place:plano · Vidal Quintanilla · Council Member - Place 8
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f'::uuid, 'civicpatch:928579c0', 'vidalquintanilla@plano.gov', '(972) 941-7107', 'https://plano.gov/1359/councilmember-vidal-quintanilla', 'office', '2026-03-27T21:19:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Eugene Escobar Jr. · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '08cf69c5-1bd4-484f-88c8-8edd05a1b821'::uuid, 'civicpatch:928579c0', 'eescobar@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/directory.aspx?EID=43', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '08cf69c5-1bd4-484f-88c8-8edd05a1b821'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Bryan Washington · Mayor Pro Tempore - Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e40be594-2239-4c28-a8ac-d4f86c6d4180'::uuid, 'civicpatch:928579c0', 'bwashington@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/directory.aspx?EID=46', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e40be594-2239-4c28-a8ac-d4f86c6d4180'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Steven Deffibaugh · Mayor Pro Tempore - Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7ccb8074-3d74-4493-9eb9-528ac48fea47'::uuid, 'civicpatch:928579c0', 'sdeffibaugh@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/736/steven-deffibaugh', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7ccb8074-3d74-4493-9eb9-528ac48fea47'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Terrance Johnson · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eb9f2322-ec6b-42f0-9939-e58cd0b843a9'::uuid, 'civicpatch:928579c0', 'tjohnson@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/732/terrance-johnson', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eb9f2322-ec6b-42f0-9939-e58cd0b843a9'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Cristina Todd · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid, 'civicpatch:928579c0', 'ctodd@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/733/cristina-todd', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Ben Long · Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ec68cd34-0756-4c12-89b9-d1b483cf08e8'::uuid, 'civicpatch:928579c0', 'blong@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/directory.aspx?EID=159', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ec68cd34-0756-4c12-89b9-d1b483cf08e8'::uuid AND c.contact_type = 'office');

-- tx/place:princeton · Carolyn David-Graves · Council Member - Place 7
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a'::uuid, 'civicpatch:928579c0', 'cgraves@princetontx.us', '(972) 736-2416', 'https://princetontx.gov/directory.aspx?EID=160', 'office', '2026-03-30T21:53:00+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · David F. Bristol · Mayor - Place 0
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd65e3760-95f3-4ad5-ba29-be01a76ae23b'::uuid, 'civicpatch:928579c0', 'dbristol@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?eid=63', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd65e3760-95f3-4ad5-ba29-be01a76ae23b'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · Amy Bartley · Council Member - Mayor Pro Tempore - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3631dd31-cb1a-46e1-ae2d-da54ea911411'::uuid, 'civicpatch:928579c0', 'abartley@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?eid=66', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3631dd31-cb1a-46e1-ae2d-da54ea911411'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · Chris Kern · Council Member - Deputy Mayor Pro Tempore - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0b5356c6-178b-4898-afd9-9883d2bce114'::uuid, 'civicpatch:928579c0', 'ckern@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?EID=67', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0b5356c6-178b-4898-afd9-9883d2bce114'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · Marcus E. Ray · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e89206d9-e960-472f-8402-691dc498355e'::uuid, 'civicpatch:928579c0', 'mray@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?eid=64', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e89206d9-e960-472f-8402-691dc498355e'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · Craig Andres · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e4e763ca-14f6-4e19-98e7-6ab2d2c972bf'::uuid, 'civicpatch:928579c0', 'craig_andres@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?eid=65', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e4e763ca-14f6-4e19-98e7-6ab2d2c972bf'::uuid AND c.contact_type = 'office');

-- tx/place:prosper · Cameron Reeves · Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ab366066-cb11-46db-9d87-6506048389f6'::uuid, 'civicpatch:928579c0', 'creeves@prospertx.gov', '(972) 569-1073', 'https://www.prospertx.gov/directory.aspx?eid=69', 'office', '2026-03-19T17:08:56+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ab366066-cb11-46db-9d87-6506048389f6'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Amir Omar · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e9b9877d-c4dc-482e-b52a-cd015a4a6850'::uuid, 'civicpatch:928579c0', 'amir.omar@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/amir-omar', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e9b9877d-c4dc-482e-b52a-cd015a4a6850'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Ken Hutchenrider · Mayor Pro Tempore - Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b0ebf2ca-f1f7-4809-b8eb-94a384dab164'::uuid, 'civicpatch:928579c0', 'ken.hutchenrider@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/ken-hutchenrider', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b0ebf2ca-f1f7-4809-b8eb-94a384dab164'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Curtis Dorian · Council Member - Place 1
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6b512b29-d3c1-4709-829f-df78664ffee1'::uuid, 'civicpatch:928579c0', 'curtis.dorian@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/curtis-dorian', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6b512b29-d3c1-4709-829f-df78664ffee1'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Jennifer Justice · Council Member - Place 2
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd85ff139-293d-49ac-a7a9-3b6681040e98'::uuid, 'civicpatch:928579c0', 'jennifer.justice@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/jennifer-justice', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd85ff139-293d-49ac-a7a9-3b6681040e98'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Dan Barrios · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e8c863a7-d116-480e-a81f-47d26f45e264'::uuid, 'civicpatch:928579c0', 'dan.barrios@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/dan-barrios', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Joe Corcoran · Council Member - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ccd0e6c7-f77c-45d7-bfae-d43125b8133d'::uuid, 'civicpatch:928579c0', 'joe.corcoran@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/joe-corcoran', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ccd0e6c7-f77c-45d7-bfae-d43125b8133d'::uuid AND c.contact_type = 'office');

-- tx/place:richardson · Arefin Shamsul · Council Member - Place 6
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9f93ae55-9228-478d-84a9-971cf4686649'::uuid, 'civicpatch:928579c0', 'arefin.shamsul@cor.gov', NULL, 'https://www.cor.net/government/city-council/who-are-our-city-council-members/arefin-shamsul', 'office', '2026-03-19T00:44:08+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9f93ae55-9228-478d-84a9-971cf4686649'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · Jim Atchison · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '4e7bc81e-1b24-4113-a839-3d87a2637df1'::uuid, 'civicpatch:928579c0', 'mayor@cityofvanalstyne.us', '(903) 482-5426', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '4e7bc81e-1b24-4113-a839-3d87a2637df1'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · Lee Thomas · Council Member - Mayor Pro Tempore - Place 4
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '4089111f-35dc-4e92-911e-17dfcce50d0b'::uuid, 'civicpatch:928579c0', 'c_thomas1775@hotmail.com', '(817) 313-1076', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '4089111f-35dc-4e92-911e-17dfcce50d0b'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · Dusty Williams · Council Member - Place 3
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c09ee8f2-1bd1-4ff9-92e9-f35a1de2735d'::uuid, 'civicpatch:928579c0', 'aldermanplace3@cityofvanalstyne.us', '(903) 482-5426', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c09ee8f2-1bd1-4ff9-92e9-f35a1de2735d'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · Katrina Arsenault · Council Member - Place 5
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '84bd50df-a548-49b4-8c9e-19fcfa59ff90'::uuid, 'civicpatch:928579c0', 'aldermanplace5@cityofvanalstyne.us', '(903) 482-5426', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '84bd50df-a548-49b4-8c9e-19fcfa59ff90'::uuid AND c.contact_type = 'office');

-- tx/place:weston · Matthew Marchiori · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '42462d85-a9c8-4aef-9f62-21b11803d06b'::uuid, 'civicpatch:928579c0', 'mmarchiori@westontexas.com', '(972) 382-1001', 'https://www.westontexas.com/page/Mayor_Aldermen', 'office', '2026-04-04T03:23:31+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '42462d85-a9c8-4aef-9f62-21b11803d06b'::uuid AND c.contact_type = 'office');

-- tx/place:weston · Jeff Metzger · Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bd1727af-4222-448a-839c-8fc79e8abdb9'::uuid, 'civicpatch:928579c0', 'jmetzger@westontexas.com', '(972) 382-1001', 'https://www.westontexas.com/page/Mayor_Aldermen', 'office', '2026-04-04T03:23:31+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bd1727af-4222-448a-839c-8fc79e8abdb9'::uuid AND c.contact_type = 'office');

-- tx/place:weston · Patti Harrington · Alderperson
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '34d011da-2352-4d91-b3f2-b3970ccbaefd'::uuid, 'civicpatch:928579c0', 'pharrington@westontexas.com', '(972) 382-1001', 'https://www.westontexas.com/page/Mayor_Aldermen', 'office', '2026-04-04T03:23:31+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '34d011da-2352-4d91-b3f2-b3970ccbaefd'::uuid AND c.contact_type = 'office');

-- tx/place:weston · Brian M. Roach · Alderperson
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ec61ea47-5631-4203-a6b6-a09fbdb7837d'::uuid, 'civicpatch:928579c0', 'broach@westontexas.com', '(972) 382-1001', 'https://www.westontexas.com/page/Mayor_Aldermen', 'office', '2026-04-04T03:23:31+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ec61ea47-5631-4203-a6b6-a09fbdb7837d'::uuid AND c.contact_type = 'office');

-- tx/place:weston · Mike Hill · Alderperson
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'de080c23-2e85-4b08-b7f7-780bebcde9b8'::uuid, 'civicpatch:928579c0', 'mhill@westontexas.com', '(972) 382-1001', 'https://www.westontexas.com/page/Mayor_Aldermen', 'office', '2026-04-04T03:23:31+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'de080c23-2e85-4b08-b7f7-780bebcde9b8'::uuid AND c.contact_type = 'office');

-- Post-verify gate: every intended politician must now carry an 'office' contact, and this
-- migration must not have created a second one for anybody.
DO $$
DECLARE
  expected int := 145;
  covered  int;
  dupes    int;
BEGIN
  SELECT count(*) INTO covered
    FROM essentials.politician_contacts
   WHERE contact_type = 'office'
     AND politician_id IN ('d8449201-38b4-4851-b8a7-40b1bcf40161'::uuid, 'fc17d6ea-c967-4d0d-a636-41b1d136765f'::uuid, '7d024231-0fa3-4787-8cc0-92fa6903711c'::uuid, 'f9dfe8ab-8b7e-427f-933f-be4ecbb1168d'::uuid, '3da0fc8c-35d5-4c14-a53b-89f7c6a7bdd2'::uuid, 'b0df471c-db3a-4f10-8817-f14c7e611593'::uuid, 'de39ab94-3663-4b2e-be14-222e79a87638'::uuid, '1b987aa5-fba6-4ce5-a926-8cb957b43410'::uuid, '91e24565-79b3-4473-9d7b-3ca72beceed2'::uuid, 'a265eb66-0b1e-45e5-9d55-f5565e0540f8'::uuid, '6db2abd4-86ce-414a-ba80-6565e6e3b23d'::uuid, '8f7f44a0-2580-4e32-97a1-e8341c6b155f'::uuid, 'd19a9e26-2ba1-4ea0-8bfe-ab69447ed769'::uuid, '0c983f9c-b510-4c70-a6b3-dc328b68b1f5'::uuid, 'c7a0ecf6-b416-474b-9647-a25e404f4bc4'::uuid, '3b15d821-fc1e-4e7b-bda0-13a669a77a27'::uuid, '8626a6f8-88c9-456e-b484-499ac8849441'::uuid, 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08'::uuid, 'f72c8a0c-61dd-4a86-a205-171e331fcaee'::uuid, 'd9710a3e-4679-44a5-8bfe-ddbb7b376ab5'::uuid, '38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d'::uuid, '94d3e41c-60b6-4803-b937-1877aeae84df'::uuid, '6a08be1a-2535-487c-a17c-f2f38263d504'::uuid, '3842838e-2015-4136-95d2-97f4f20366b1'::uuid, 'f920ca1a-8263-4662-aa21-1f5964dfa61d'::uuid, 'a9db2052-5fbd-4370-9f78-f8ba07b6e452'::uuid, 'c7bfdeff-ba51-479c-b956-331a6562c21b'::uuid, 'b85c7a20-744d-4065-b240-530aceda65bc'::uuid, 'ff6a17d4-7067-4566-9241-17aaf9f45b34'::uuid, '831ce2c9-bc43-487a-a0d6-a0b9c776e7d2'::uuid, 'cb9d6924-77d1-49c9-ab3d-778b0201e623'::uuid, '780b7f22-755a-4a92-8bd3-78978edbc564'::uuid, 'b167c501-2c43-48b3-8922-e00e060985b3'::uuid, '7395cbed-4d2b-42f4-aeff-04b7427b0bc0'::uuid, 'c36e6f78-4828-49cd-9010-988c8a7c7be4'::uuid, '72b80f6a-82b3-4872-a10f-e95e2cd3f90f'::uuid, '9e2aa590-23e2-4217-84b7-418ba9dc1414'::uuid, 'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'::uuid, '38e20826-63c9-4eef-a4e1-ea77aa6892e2'::uuid, '9e80fff4-8b89-4c38-b33e-a1a0fff7e080'::uuid, 'e7f04a34-b8e7-4978-87d6-60ece59ced92'::uuid, '5712d682-ffd5-4e6d-afa8-9707613fd838'::uuid, '94252f68-40d6-4e82-8f10-1015a85fa403'::uuid, 'eb6c2d0f-ea9f-420c-81bb-eb3d6287214d'::uuid, 'fae40714-a182-4e37-9bac-1afe754b4561'::uuid, 'eab3bbe2-4103-49a2-a0bf-d45acc9d54e0'::uuid, '5b346b19-d6ee-47e2-acbf-5780ca423264'::uuid, '76c3fa35-a286-4fa1-b6da-40300d91f33e'::uuid, 'da010ea4-257d-4582-98cb-ee90063aa31d'::uuid, 'c11bf372-8190-4b45-b80a-cbd0fb2ba401'::uuid, '5d8acfc7-5643-418b-a474-3d87898f4e17'::uuid, 'f3eb38f1-a044-4c75-82c8-80750f40543e'::uuid, 'c5411e93-3b1c-42e3-a0c8-00491804cada'::uuid, 'b6bf2154-78d1-4d12-8881-5f83640beee2'::uuid, '215618d2-17ac-4946-a511-c0e9a95164b6'::uuid, 'f90a82e8-24db-433c-a8dd-6b5098f0a20e'::uuid, 'b48179c3-8e73-47a8-9e05-f9a8a24d4ab7'::uuid, '3ae0e255-7dca-486d-abbf-f8d2ebd5e7be'::uuid, 'e8df1e64-e5c3-4417-bccd-fb176be11f39'::uuid, 'f4ee71a6-8a14-4727-aa39-716fae402f60'::uuid, 'd53f9122-face-4b22-a5b1-66ca6dc49997'::uuid, '62d609ff-284a-493e-a2ba-70c11bf87619'::uuid, '0997e0f6-24ed-4d7e-964a-bd1069479352'::uuid, '5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0'::uuid, 'c723b079-c7db-4376-b8d3-72ac896fefe2'::uuid, 'd55159ff-7c27-4313-b464-722f653fd7b7'::uuid, '94957758-20db-4590-8cc9-ce54c24e2449'::uuid, 'feb872f2-cd11-42bc-8a83-22e12dbc6207'::uuid, '2baab241-b3c5-48e9-b9a6-fd29b7b77beb'::uuid, '6f199ec9-ba4a-4c0d-b6e3-bae97e0da847'::uuid, 'e84f56af-ad73-4bec-8e4c-efccb8854cb1'::uuid, 'eb142dfb-2208-4d3c-afe7-d2b64708129b'::uuid, '0ea8bc33-1629-41b4-8ae9-da74c3e2b44c'::uuid, '8d24cdb6-64d1-4597-a66e-71bc723391d7'::uuid, 'ada1526e-32a3-47b2-9535-c4988e8db633'::uuid, 'bf1f8150-ae29-42ef-8b50-b2619e8d46ca'::uuid, '72c0de8c-38b0-4470-a0d0-9d7a71986be0'::uuid, '1c31b159-d4c1-4756-ba81-a247dbf0af8f'::uuid, '23ba75d2-6eed-4b71-9669-78ab3bb82e98'::uuid, 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723'::uuid, '27578980-2e6c-4639-879a-70b510566d0f'::uuid, '6ee726c1-79af-4fef-abb8-fa7f4208ae14'::uuid, 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e'::uuid, '09dbafc2-9252-40e4-9a1c-afda5b069f2e'::uuid, 'b8d0cef2-3787-4074-9d85-81a9d27aaef8'::uuid, '3e377dbe-2c37-41ed-a65d-664de75318ae'::uuid, 'af2697d7-f766-4ddd-8b61-65e5d0c2df70'::uuid, '30680496-7464-495c-a9bc-eb44cc6b84b8'::uuid, '12d3560f-3b07-4fe7-b8c4-c2466c13e7eb'::uuid, 'c5d9869d-6e7b-448d-bb48-43c2cd795d9a'::uuid, 'b3602d0c-9af7-4baf-a96c-a15be063c272'::uuid, 'e8841ac4-bcae-4783-b24a-e6fb82f46da7'::uuid, '094da72b-3f17-4ce8-9c2a-747acd125086'::uuid, 'c0bf5333-e271-46db-a5f8-84ced3177b6b'::uuid, 'bcd556db-a139-4b87-8887-a1bad73726ea'::uuid, '965000e5-54b5-40d4-9bae-6f70519536db'::uuid, '47a5349c-ea03-4fcf-8719-948c259a3753'::uuid, 'c41886b8-f4ad-4f06-a579-5140c8951c91'::uuid, 'f138261a-4e0b-4c53-b30a-18e30b76e614'::uuid, '988e1851-7b35-4bce-81ff-955412f8670b'::uuid, '6c1dc476-507b-43a8-9061-bdaf9eafec58'::uuid, '51c0d0db-b3e6-4e71-960e-4809ad680e25'::uuid, '61f73b44-c46d-4f1b-91a7-0d35c83feecb'::uuid, '812359f8-3ea5-4815-91ca-7e5a4ba2ba0a'::uuid, 'a32e8631-404d-49bd-a914-8b05febe9df5'::uuid, 'fc09e53a-723c-4c34-97ab-9e0b692104a0'::uuid, 'aba6f016-e35d-4977-99e6-a2cfc079ad75'::uuid, 'e136a517-1772-4f16-9bd5-785828f524e8'::uuid, '5584e869-4a54-4a68-a3c8-c14db45a71c5'::uuid, 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799'::uuid, 'bc4a88d7-2f56-48fd-85db-fa1fd4f8547e'::uuid, 'de037c5c-9c00-40c5-ade2-3d322b4a0349'::uuid, '127b8e69-3900-438c-8361-2cfe24b6c6cf'::uuid, 'ecef0481-27c7-4955-b822-83d64c7ef63f'::uuid, '4272e5cb-40cf-42d9-a493-ae5ca04301bb'::uuid, '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f'::uuid, '08cf69c5-1bd4-484f-88c8-8edd05a1b821'::uuid, 'e40be594-2239-4c28-a8ac-d4f86c6d4180'::uuid, '7ccb8074-3d74-4493-9eb9-528ac48fea47'::uuid, 'eb9f2322-ec6b-42f0-9939-e58cd0b843a9'::uuid, '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid, 'ec68cd34-0756-4c12-89b9-d1b483cf08e8'::uuid, '2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a'::uuid, 'd65e3760-95f3-4ad5-ba29-be01a76ae23b'::uuid, '3631dd31-cb1a-46e1-ae2d-da54ea911411'::uuid, '0b5356c6-178b-4898-afd9-9883d2bce114'::uuid, 'e89206d9-e960-472f-8402-691dc498355e'::uuid, 'e4e763ca-14f6-4e19-98e7-6ab2d2c972bf'::uuid, 'ab366066-cb11-46db-9d87-6506048389f6'::uuid, 'e9b9877d-c4dc-482e-b52a-cd015a4a6850'::uuid, 'b0ebf2ca-f1f7-4809-b8eb-94a384dab164'::uuid, '6b512b29-d3c1-4709-829f-df78664ffee1'::uuid, 'd85ff139-293d-49ac-a7a9-3b6681040e98'::uuid, 'e8c863a7-d116-480e-a81f-47d26f45e264'::uuid, 'ccd0e6c7-f77c-45d7-bfae-d43125b8133d'::uuid, '9f93ae55-9228-478d-84a9-971cf4686649'::uuid, '4e7bc81e-1b24-4113-a839-3d87a2637df1'::uuid, '4089111f-35dc-4e92-911e-17dfcce50d0b'::uuid, 'c09ee8f2-1bd1-4ff9-92e9-f35a1de2735d'::uuid, '84bd50df-a548-49b4-8c9e-19fcfa59ff90'::uuid, '42462d85-a9c8-4aef-9f62-21b11803d06b'::uuid, 'bd1727af-4222-448a-839c-8fc79e8abdb9'::uuid, '34d011da-2352-4d91-b3f2-b3970ccbaefd'::uuid, 'ec61ea47-5631-4203-a6b6-a09fbdb7837d'::uuid, 'de080c23-2e85-4b08-b7f7-780bebcde9b8'::uuid);
  IF covered <> expected THEN
    RAISE EXCEPTION 'expected % politicians with an office contact, found %', expected, covered;
  END IF;

  -- Scoped to THIS batch: prod may hold unrelated duplicate office contacts elsewhere,
  -- and this gate must fail only on damage we caused.
  SELECT count(*) INTO dupes FROM (
    SELECT politician_id FROM essentials.politician_contacts
     WHERE contact_type = 'office'
       AND politician_id IN ('d8449201-38b4-4851-b8a7-40b1bcf40161'::uuid, 'fc17d6ea-c967-4d0d-a636-41b1d136765f'::uuid, '7d024231-0fa3-4787-8cc0-92fa6903711c'::uuid, 'f9dfe8ab-8b7e-427f-933f-be4ecbb1168d'::uuid, '3da0fc8c-35d5-4c14-a53b-89f7c6a7bdd2'::uuid, 'b0df471c-db3a-4f10-8817-f14c7e611593'::uuid, 'de39ab94-3663-4b2e-be14-222e79a87638'::uuid, '1b987aa5-fba6-4ce5-a926-8cb957b43410'::uuid, '91e24565-79b3-4473-9d7b-3ca72beceed2'::uuid, 'a265eb66-0b1e-45e5-9d55-f5565e0540f8'::uuid, '6db2abd4-86ce-414a-ba80-6565e6e3b23d'::uuid, '8f7f44a0-2580-4e32-97a1-e8341c6b155f'::uuid, 'd19a9e26-2ba1-4ea0-8bfe-ab69447ed769'::uuid, '0c983f9c-b510-4c70-a6b3-dc328b68b1f5'::uuid, 'c7a0ecf6-b416-474b-9647-a25e404f4bc4'::uuid, '3b15d821-fc1e-4e7b-bda0-13a669a77a27'::uuid, '8626a6f8-88c9-456e-b484-499ac8849441'::uuid, 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08'::uuid, 'f72c8a0c-61dd-4a86-a205-171e331fcaee'::uuid, 'd9710a3e-4679-44a5-8bfe-ddbb7b376ab5'::uuid, '38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d'::uuid, '94d3e41c-60b6-4803-b937-1877aeae84df'::uuid, '6a08be1a-2535-487c-a17c-f2f38263d504'::uuid, '3842838e-2015-4136-95d2-97f4f20366b1'::uuid, 'f920ca1a-8263-4662-aa21-1f5964dfa61d'::uuid, 'a9db2052-5fbd-4370-9f78-f8ba07b6e452'::uuid, 'c7bfdeff-ba51-479c-b956-331a6562c21b'::uuid, 'b85c7a20-744d-4065-b240-530aceda65bc'::uuid, 'ff6a17d4-7067-4566-9241-17aaf9f45b34'::uuid, '831ce2c9-bc43-487a-a0d6-a0b9c776e7d2'::uuid, 'cb9d6924-77d1-49c9-ab3d-778b0201e623'::uuid, '780b7f22-755a-4a92-8bd3-78978edbc564'::uuid, 'b167c501-2c43-48b3-8922-e00e060985b3'::uuid, '7395cbed-4d2b-42f4-aeff-04b7427b0bc0'::uuid, 'c36e6f78-4828-49cd-9010-988c8a7c7be4'::uuid, '72b80f6a-82b3-4872-a10f-e95e2cd3f90f'::uuid, '9e2aa590-23e2-4217-84b7-418ba9dc1414'::uuid, 'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'::uuid, '38e20826-63c9-4eef-a4e1-ea77aa6892e2'::uuid, '9e80fff4-8b89-4c38-b33e-a1a0fff7e080'::uuid, 'e7f04a34-b8e7-4978-87d6-60ece59ced92'::uuid, '5712d682-ffd5-4e6d-afa8-9707613fd838'::uuid, '94252f68-40d6-4e82-8f10-1015a85fa403'::uuid, 'eb6c2d0f-ea9f-420c-81bb-eb3d6287214d'::uuid, 'fae40714-a182-4e37-9bac-1afe754b4561'::uuid, 'eab3bbe2-4103-49a2-a0bf-d45acc9d54e0'::uuid, '5b346b19-d6ee-47e2-acbf-5780ca423264'::uuid, '76c3fa35-a286-4fa1-b6da-40300d91f33e'::uuid, 'da010ea4-257d-4582-98cb-ee90063aa31d'::uuid, 'c11bf372-8190-4b45-b80a-cbd0fb2ba401'::uuid, '5d8acfc7-5643-418b-a474-3d87898f4e17'::uuid, 'f3eb38f1-a044-4c75-82c8-80750f40543e'::uuid, 'c5411e93-3b1c-42e3-a0c8-00491804cada'::uuid, 'b6bf2154-78d1-4d12-8881-5f83640beee2'::uuid, '215618d2-17ac-4946-a511-c0e9a95164b6'::uuid, 'f90a82e8-24db-433c-a8dd-6b5098f0a20e'::uuid, 'b48179c3-8e73-47a8-9e05-f9a8a24d4ab7'::uuid, '3ae0e255-7dca-486d-abbf-f8d2ebd5e7be'::uuid, 'e8df1e64-e5c3-4417-bccd-fb176be11f39'::uuid, 'f4ee71a6-8a14-4727-aa39-716fae402f60'::uuid, 'd53f9122-face-4b22-a5b1-66ca6dc49997'::uuid, '62d609ff-284a-493e-a2ba-70c11bf87619'::uuid, '0997e0f6-24ed-4d7e-964a-bd1069479352'::uuid, '5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0'::uuid, 'c723b079-c7db-4376-b8d3-72ac896fefe2'::uuid, 'd55159ff-7c27-4313-b464-722f653fd7b7'::uuid, '94957758-20db-4590-8cc9-ce54c24e2449'::uuid, 'feb872f2-cd11-42bc-8a83-22e12dbc6207'::uuid, '2baab241-b3c5-48e9-b9a6-fd29b7b77beb'::uuid, '6f199ec9-ba4a-4c0d-b6e3-bae97e0da847'::uuid, 'e84f56af-ad73-4bec-8e4c-efccb8854cb1'::uuid, 'eb142dfb-2208-4d3c-afe7-d2b64708129b'::uuid, '0ea8bc33-1629-41b4-8ae9-da74c3e2b44c'::uuid, '8d24cdb6-64d1-4597-a66e-71bc723391d7'::uuid, 'ada1526e-32a3-47b2-9535-c4988e8db633'::uuid, 'bf1f8150-ae29-42ef-8b50-b2619e8d46ca'::uuid, '72c0de8c-38b0-4470-a0d0-9d7a71986be0'::uuid, '1c31b159-d4c1-4756-ba81-a247dbf0af8f'::uuid, '23ba75d2-6eed-4b71-9669-78ab3bb82e98'::uuid, 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723'::uuid, '27578980-2e6c-4639-879a-70b510566d0f'::uuid, '6ee726c1-79af-4fef-abb8-fa7f4208ae14'::uuid, 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e'::uuid, '09dbafc2-9252-40e4-9a1c-afda5b069f2e'::uuid, 'b8d0cef2-3787-4074-9d85-81a9d27aaef8'::uuid, '3e377dbe-2c37-41ed-a65d-664de75318ae'::uuid, 'af2697d7-f766-4ddd-8b61-65e5d0c2df70'::uuid, '30680496-7464-495c-a9bc-eb44cc6b84b8'::uuid, '12d3560f-3b07-4fe7-b8c4-c2466c13e7eb'::uuid, 'c5d9869d-6e7b-448d-bb48-43c2cd795d9a'::uuid, 'b3602d0c-9af7-4baf-a96c-a15be063c272'::uuid, 'e8841ac4-bcae-4783-b24a-e6fb82f46da7'::uuid, '094da72b-3f17-4ce8-9c2a-747acd125086'::uuid, 'c0bf5333-e271-46db-a5f8-84ced3177b6b'::uuid, 'bcd556db-a139-4b87-8887-a1bad73726ea'::uuid, '965000e5-54b5-40d4-9bae-6f70519536db'::uuid, '47a5349c-ea03-4fcf-8719-948c259a3753'::uuid, 'c41886b8-f4ad-4f06-a579-5140c8951c91'::uuid, 'f138261a-4e0b-4c53-b30a-18e30b76e614'::uuid, '988e1851-7b35-4bce-81ff-955412f8670b'::uuid, '6c1dc476-507b-43a8-9061-bdaf9eafec58'::uuid, '51c0d0db-b3e6-4e71-960e-4809ad680e25'::uuid, '61f73b44-c46d-4f1b-91a7-0d35c83feecb'::uuid, '812359f8-3ea5-4815-91ca-7e5a4ba2ba0a'::uuid, 'a32e8631-404d-49bd-a914-8b05febe9df5'::uuid, 'fc09e53a-723c-4c34-97ab-9e0b692104a0'::uuid, 'aba6f016-e35d-4977-99e6-a2cfc079ad75'::uuid, 'e136a517-1772-4f16-9bd5-785828f524e8'::uuid, '5584e869-4a54-4a68-a3c8-c14db45a71c5'::uuid, 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799'::uuid, 'bc4a88d7-2f56-48fd-85db-fa1fd4f8547e'::uuid, 'de037c5c-9c00-40c5-ade2-3d322b4a0349'::uuid, '127b8e69-3900-438c-8361-2cfe24b6c6cf'::uuid, 'ecef0481-27c7-4955-b822-83d64c7ef63f'::uuid, '4272e5cb-40cf-42d9-a493-ae5ca04301bb'::uuid, '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f'::uuid, '08cf69c5-1bd4-484f-88c8-8edd05a1b821'::uuid, 'e40be594-2239-4c28-a8ac-d4f86c6d4180'::uuid, '7ccb8074-3d74-4493-9eb9-528ac48fea47'::uuid, 'eb9f2322-ec6b-42f0-9939-e58cd0b843a9'::uuid, '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid, 'ec68cd34-0756-4c12-89b9-d1b483cf08e8'::uuid, '2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a'::uuid, 'd65e3760-95f3-4ad5-ba29-be01a76ae23b'::uuid, '3631dd31-cb1a-46e1-ae2d-da54ea911411'::uuid, '0b5356c6-178b-4898-afd9-9883d2bce114'::uuid, 'e89206d9-e960-472f-8402-691dc498355e'::uuid, 'e4e763ca-14f6-4e19-98e7-6ab2d2c972bf'::uuid, 'ab366066-cb11-46db-9d87-6506048389f6'::uuid, 'e9b9877d-c4dc-482e-b52a-cd015a4a6850'::uuid, 'b0ebf2ca-f1f7-4809-b8eb-94a384dab164'::uuid, '6b512b29-d3c1-4709-829f-df78664ffee1'::uuid, 'd85ff139-293d-49ac-a7a9-3b6681040e98'::uuid, 'e8c863a7-d116-480e-a81f-47d26f45e264'::uuid, 'ccd0e6c7-f77c-45d7-bfae-d43125b8133d'::uuid, '9f93ae55-9228-478d-84a9-971cf4686649'::uuid, '4e7bc81e-1b24-4113-a839-3d87a2637df1'::uuid, '4089111f-35dc-4e92-911e-17dfcce50d0b'::uuid, 'c09ee8f2-1bd1-4ff9-92e9-f35a1de2735d'::uuid, '84bd50df-a548-49b4-8c9e-19fcfa59ff90'::uuid, '42462d85-a9c8-4aef-9f62-21b11803d06b'::uuid, 'bd1727af-4222-448a-839c-8fc79e8abdb9'::uuid, '34d011da-2352-4d91-b3f2-b3970ccbaefd'::uuid, 'ec61ea47-5631-4203-a6b6-a09fbdb7837d'::uuid, 'de080c23-2e85-4b08-b7f7-780bebcde9b8'::uuid)
     GROUP BY politician_id HAVING count(*) > 1) d;
  IF dupes > 0 THEN
    RAISE EXCEPTION 'duplicate office contacts for % politicians', dupes;
  END IF;
END $$;

COMMIT;
