-- 1504_civicpatch_ca_contacts.sql
--
-- Backfill office contacts for 136 municipal officials we ALREADY HOLD, from the
-- vendored CC0 CivicPatch snapshot 928579c0 (backend/data/civicpatch/).
-- Approved scope: .planning/decisions/2026-07-30-civicpatch-api-decision.md
--
-- ENRICHMENT ONLY. Creates no politician and no office. Every row below is an EXACT 1:1
-- normalised-name match against a CURRENT officeholder in the same place. Near-matches
-- (the "Ben"/"Benjamin" shape) were held back for human review and are NOT here.
--
-- ADDITIVE ONLY. Each insert is guarded on the politician having no contact_type='office'
-- row at all, so nothing we already hold is overwritten. Re-running is a no-op.
--
-- WHY THEIR STALENESS DOES NOT LEAK IN. Candidates are drawn ONLY from
-- essentials.office_current_holder, so a record naming someone who has left office matches
-- nobody and is absent here by construction. 6 of their 150 records for this batch
-- did exactly that. Matching against current holders IS the incumbency check the decision
-- doc asked for — staleness costs MISSes, never bad writes. Do not "fix" the matcher to
-- rescue them: a MISS is usually someone who left office. 8 near-matches were also
-- held back for human adjudication and are not included.

BEGIN;

-- ca/place:berkeley · Adena Ishii · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '965de422-660e-4e24-9fe6-717cc0313403'::uuid, 'civicpatch:928579c0', 'mayor@berkeleyca.gov', '(510) 981-7100', 'https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '965de422-660e-4e24-9fe6-717cc0313403'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Rashi Kesarwani · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd2013613-769f-4374-809e-a018dbc1e683'::uuid, 'civicpatch:928579c0', 'rkesarwani@berkeleyca.gov', '(510) 981-7110', 'https://berkeleyca.gov/your-government/city-council/council-roster/rashi-kesarwani', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd2013613-769f-4374-809e-a018dbc1e683'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Terry Taplin · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, 'civicpatch:928579c0', 'ttaplin@berkeleyca.gov', '(510) 981-7120', 'https://berkeleyca.gov/your-government/city-council/council-roster/terry-taplin', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Ben Bartlett · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid, 'civicpatch:928579c0', 'bbartlett@berkeleyca.gov', '(510) 981-7130', 'https://berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Igor Tregub · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid, 'civicpatch:928579c0', 'itregub@berkeleyca.gov', '(510) 981-7140', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Shoshana O'Keefe · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8cc1c412-fe14-4bc6-b1e2-02d95997fd47'::uuid, 'civicpatch:928579c0', 'sokeefe@berkeleyca.gov', '(510) 981-7150', 'https://berkeleyca.gov/your-government/city-council/council-roster/shoshana-o-keefe', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8cc1c412-fe14-4bc6-b1e2-02d95997fd47'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Brent Blackaby · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '424eb63b-9976-4059-8049-365c09719cc6'::uuid, 'civicpatch:928579c0', 'bblackaby@berkeleyca.gov', '(510) 981-7160', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '424eb63b-9976-4059-8049-365c09719cc6'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Cecilia Lunaparra · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '116aace8-9440-498b-bf1d-ebb196727c85'::uuid, 'civicpatch:928579c0', 'clunaparra@berkeleyca.gov', '(510) 981-7170', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '116aace8-9440-498b-bf1d-ebb196727c85'::uuid AND c.contact_type = 'office');

-- ca/place:berkeley · Mark Humbert · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7833be90-c693-40b8-a309-61ee77b4ba03'::uuid, 'civicpatch:928579c0', 'mhumbert@berkeleyca.gov', '(510) 981-7180', 'https://berkeleyca.gov/your-government/city-council/council-roster/mark-humbert', 'office', '2025-07-17T19:35:42+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7833be90-c693-40b8-a309-61ee77b4ba03'::uuid AND c.contact_type = 'office');

-- ca/place:burbank · Nikki Perez · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '96f91743-def6-436c-9537-a4b836c1b3eb'::uuid, 'civicpatch:928579c0', 'citycouncil@burbankca.gov', '(818) 238-5750', 'https://www.burbankca.gov/nikki-perez', 'office', '2025-07-18T20:18:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '96f91743-def6-436c-9537-a4b836c1b3eb'::uuid AND c.contact_type = 'office');

-- ca/place:burbank · Tamala Takahashi · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'::uuid, 'civicpatch:928579c0', 'citycouncil@burbankca.gov', '(818) 238-5750', 'https://www.burbankca.gov/tamala-takahashi', 'office', '2025-07-18T20:18:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'::uuid AND c.contact_type = 'office');

-- ca/place:burbank · Christopher John Rizzotti · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349'::uuid, 'civicpatch:928579c0', 'citycouncil@burbankca.gov', '(818) 238-5750', 'https://www.burbankca.gov/christopher-rizzotti', 'office', '2025-07-18T20:18:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349'::uuid AND c.contact_type = 'office');

-- ca/place:burbank · Konstantine Anthony · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'::uuid, 'civicpatch:928579c0', 'citycouncil@burbankca.gov', '(818) 238-5750', 'https://www.burbankca.gov/konstantine-anthony', 'office', '2025-07-18T20:18:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'::uuid AND c.contact_type = 'office');

-- ca/place:burbank · Zizette Mullins · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f933bd87-d397-4ef1-873b-57559b629000'::uuid, 'civicpatch:928579c0', 'citycouncil@burbankca.gov', '(818) 238-5750', 'https://www.burbankca.gov/zizette-mullins', 'office', '2025-07-18T20:18:58+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f933bd87-d397-4ef1-873b-57559b629000'::uuid AND c.contact_type = 'office');

-- ca/place:carson · Lula Davis-Holmes · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e'::uuid, 'civicpatch:928579c0', 'ldavis-holmes@carsonca.gov', '(310) 952-1700', 'https://carsonca.gov/government/elected_officials/mayor.php', 'office', '2025-07-18T21:09:36+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e'::uuid AND c.contact_type = 'office');

-- ca/place:carson · Jawane Hilton · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd1b1bc73-575f-444e-a2f8-46c04b07d3f8'::uuid, 'civicpatch:928579c0', 'jhilton@carsonca.gov', '(310) 952-1700', 'https://carsonca.gov/government/elected_officials/hiltonbio.php', 'office', '2025-07-18T21:09:36+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd1b1bc73-575f-444e-a2f8-46c04b07d3f8'::uuid AND c.contact_type = 'office');

-- ca/place:carson · Cedric L. Hicks Sr. · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5'::uuid, 'civicpatch:928579c0', 'chicks@carsonca.gov', '(310) 952-1700 ext. 1712', 'https://carsonca.gov/government/elected_officials/CedricHicksBio.php', 'office', '2025-07-18T21:09:36+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5'::uuid AND c.contact_type = 'office');

-- ca/place:carson · Jim Dear · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '1581974b-2a8c-4439-acae-377bc06e1788'::uuid, 'civicpatch:928579c0', 'jdear@carsonca.gov', '(310) 952-1700', 'https://carsonca.gov/government/elected_officials/jimdearbio.php', 'office', '2025-07-18T21:09:36+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '1581974b-2a8c-4439-acae-377bc06e1788'::uuid AND c.contact_type = 'office');

-- ca/place:compton · Emma Sharif · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '174f3f47-e4ee-4775-ab6f-f1039d608098'::uuid, 'civicpatch:928579c0', 'esharif@comptoncity.org', '(310) 605-5500', 'https://www.comptoncity.org/our-city/elected-officials/mayor-emma-sharif', 'office', '2025-07-18T21:05:41+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '174f3f47-e4ee-4775-ab6f-f1039d608098'::uuid AND c.contact_type = 'office');

-- ca/place:compton · Deidre Duhart · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a5db6e7d-2146-4dde-a778-05fa40566ac0'::uuid, 'civicpatch:928579c0', 'dduhart@comptoncity.org', NULL, 'https://www.comptoncity.org/our-city/elected-officials/district-1-deidre-duhart', 'office', '2025-07-18T21:05:41+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a5db6e7d-2146-4dde-a778-05fa40566ac0'::uuid AND c.contact_type = 'office');

-- ca/place:compton · Andre Spicer · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f63d8129-c569-4ea5-bd77-5cda877b2185'::uuid, 'civicpatch:928579c0', 'aspicer@comptoncity.org', NULL, 'https://www.comptoncity.org/our-city/elected-officials/district-2-andre-spicer', 'office', '2025-07-18T21:05:41+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f63d8129-c569-4ea5-bd77-5cda877b2185'::uuid AND c.contact_type = 'office');

-- ca/place:compton · Jonathan Bowers · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9a37b6e4-13bc-48c0-97b3-22aaa253c054'::uuid, 'civicpatch:928579c0', 'jbowers@comptoncity.org', NULL, 'https://www.comptoncity.org/our-city/elected-officials/district-3-jonathan-bowers', 'office', '2025-07-18T21:05:41+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9a37b6e4-13bc-48c0-97b3-22aaa253c054'::uuid AND c.contact_type = 'office');

-- ca/place:downey · Hector Sosa · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '92d68971-8cc2-480b-8e29-9938f7a280f1'::uuid, 'civicpatch:928579c0', 'hsosa@downeyca.org', '(562) 904-7274', 'https://www.downeyca.org/our-city/mayor-city-council/hector-sosa-district-2', 'office', '2025-07-18T20:08:18+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '92d68971-8cc2-480b-8e29-9938f7a280f1'::uuid AND c.contact_type = 'office');

-- ca/place:downey · Dorothy Pemberton · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '71c35909-e5b5-40ca-883f-21af5c287b5e'::uuid, 'civicpatch:928579c0', 'dpemberton@downeyca.org', '(562) 904-7274', 'https://www.downeyca.org/our-city/mayor-city-council/vacant-district-3', 'office', '2025-07-18T20:08:18+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '71c35909-e5b5-40ca-883f-21af5c287b5e'::uuid AND c.contact_type = 'office');

-- ca/place:downey · Horacio Ortiz · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '13dc32dd-fac5-440d-9f10-f1f1892acf68'::uuid, 'civicpatch:928579c0', 'hortizjr@downeyca.org', '(562) 904-7274', 'https://www.downeyca.org/our-city/mayor-city-council/timonthy-horn-district-1', 'office', '2025-07-18T20:08:18+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '13dc32dd-fac5-440d-9f10-f1f1892acf68'::uuid AND c.contact_type = 'office');

-- ca/place:downey · Claudia M. Frometa · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '4967617f-5919-4816-8661-a675f05e8b66'::uuid, 'civicpatch:928579c0', 'cfrometa@downeyca.org', '(562) 904-7274', 'https://www.downeyca.org/our-city/mayor-city-council/claudia-m-frometa-of-district-4', 'office', '2025-07-18T20:08:18+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '4967617f-5919-4816-8661-a675f05e8b66'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Raj Salwan · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '71124b00-549d-460c-8f84-41a01d99e037'::uuid, 'civicpatch:928579c0', 'rsalwan@fremont.gov', '(510) 284-4082', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '71124b00-549d-460c-8f84-41a01d99e037'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Teresa Keng · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff'::uuid, 'civicpatch:928579c0', 'tkeng@fremont.gov', '(510) 284-4012', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Desrie Campbell · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '28839e39-6db1-4253-94a4-94ae234c241e'::uuid, 'civicpatch:928579c0', 'dcampbell@fremont.gov', '(510) 284-4008', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '28839e39-6db1-4253-94a4-94ae234c241e'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Kathy Kimberlin · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f886f6da-d08f-4294-81bc-faf4a1eaad4d'::uuid, 'civicpatch:928579c0', 'kkimberlin@fremont.gov', '(510) 284-4095', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f886f6da-d08f-4294-81bc-faf4a1eaad4d'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Yang Shao · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7db82a3d-5aa2-4150-996e-b170b50b47fe'::uuid, 'civicpatch:928579c0', 'yshao@fremont.gov', '(510) 284-4019', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7db82a3d-5aa2-4150-996e-b170b50b47fe'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Yajing Zhang · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd6d492b6-cbaf-4398-9301-4fbd10da571f'::uuid, 'civicpatch:928579c0', 'yazhang@fremont.gov', '(510) 284-4083', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd6d492b6-cbaf-4398-9301-4fbd10da571f'::uuid AND c.contact_type = 'office');

-- ca/place:fremont · Raymond Liu · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '42e95c4c-4e02-4d60-805c-6a3d857dd95a'::uuid, 'civicpatch:928579c0', 'rliu@fremont.gov', '(510) 284-4097', 'https://www.fremont.gov/government/mayor-city-council', 'office', '2025-07-17T17:17:43+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '42e95c4c-4e02-4d60-805c-6a3d857dd95a'::uuid AND c.contact_type = 'office');

-- ca/place:glendale · Elen Asatryan · Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '84eebb94-9163-40ec-8cc2-1391a00e636e'::uuid, 'civicpatch:928579c0', 'EAsatryan@GlendaleCA.gov', NULL, 'https://www.glendaleca.gov/government/city-council/mayor-elen-asatryan', 'office', '2025-07-17T17:29:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '84eebb94-9163-40ec-8cc2-1391a00e636e'::uuid AND c.contact_type = 'office');

-- ca/place:glendale · Vartan Gharpetian · Vice Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a223d51d-7077-4d9d-98b0-bcfafabbbc71'::uuid, 'civicpatch:928579c0', 'VGharpetian@GlendaleCA.gov', NULL, 'https://www.glendaleca.gov/government/city-council/councilmember-vartan-gharpetian', 'office', '2025-07-17T17:29:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a223d51d-7077-4d9d-98b0-bcfafabbbc71'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Pat Burns · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'deea52f0-0422-4fc8-971a-27a2471e14f2'::uuid, 'civicpatch:928579c0', 'Pat.Burns@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'deea52f0-0422-4fc8-971a-27a2471e14f2'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Casey McKeon · Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e7a155f4-eb21-4e0f-b901-695f64ccb5cb'::uuid, 'civicpatch:928579c0', 'Casey.McKeon@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e7a155f4-eb21-4e0f-b901-695f64ccb5cb'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Andrew Gruel · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7dff1af1-993e-4d8f-8901-e4f96b93f11d'::uuid, 'civicpatch:928579c0', 'Andrew.Gruel@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7dff1af1-993e-4d8f-8901-e4f96b93f11d'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Butch Twining · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f75231e6-b6e4-4b1b-8ce5-d275c3f4bb7f'::uuid, 'civicpatch:928579c0', 'Butch.Twining@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f75231e6-b6e4-4b1b-8ce5-d275c3f4bb7f'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Chad Williams · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '86ceb1d5-b225-4a1b-9eb0-bb708532eea8'::uuid, 'civicpatch:928579c0', 'Chad.Williams@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '86ceb1d5-b225-4a1b-9eb0-bb708532eea8'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Don Kennedy · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '01f9f586-aac2-4c17-8f1c-faf031f7de29'::uuid, 'civicpatch:928579c0', 'Don.Kennedy@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '01f9f586-aac2-4c17-8f1c-faf031f7de29'::uuid AND c.contact_type = 'office');

-- ca/place:huntington_beach · Gracey Van Der Mark · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a5595064-ce36-4b12-8eca-a2d796759d53'::uuid, 'civicpatch:928579c0', 'Gracey.VanDerMark@surfcity-hb.org', NULL, 'https://www.huntingtonbeachca.gov/government/city_council/index.php', 'office', '2025-07-17T18:46:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a5595064-ce36-4b12-8eca-a2d796759d53'::uuid AND c.contact_type = 'office');

-- ca/place:inglewood · Alex Padilla · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid, 'civicpatch:928579c0', 'APadilla@cityofinglewood.org', '(310) 412-8601', 'https://www.cityofinglewood.org/directory.aspx?EID=103', 'office', '2025-07-18T20:16:11+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid AND c.contact_type = 'office');

-- ca/place:inglewood · Eloy Morales · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6ed19c10-7b34-47f0-8705-0d154271e362'::uuid, 'civicpatch:928579c0', 'EMorales@CityofInglewood.org', '(310) 412-8603', 'https://www.cityofinglewood.org/directory.aspx?EID=104', 'office', '2025-07-18T20:16:11+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6ed19c10-7b34-47f0-8705-0d154271e362'::uuid AND c.contact_type = 'office');

-- ca/place:inglewood · Dionne Faulk · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '729bc539-3175-4e5d-96ba-c18768890e1e'::uuid, 'civicpatch:928579c0', 'dfaulk@cityofinglewood.org', '(310) 412-8605', 'https://www.cityofinglewood.org/directory.aspx?EID=306', 'office', '2025-07-18T20:16:11+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '729bc539-3175-4e5d-96ba-c18768890e1e'::uuid AND c.contact_type = 'office');

-- ca/place:lancaster · R. Rex Parris · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '87546d4d-78ee-4aae-82cb-89ae805e10b4'::uuid, 'civicpatch:928579c0', 'rrparris@cityoflancasterca.gov', '(661) 723-6019', 'https://www.cityoflancasterca.org/government/city-officials/city-council/mayor-r-rex-parris', 'office', '2025-07-17T18:49:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '87546d4d-78ee-4aae-82cb-89ae805e10b4'::uuid AND c.contact_type = 'office');

-- ca/place:lancaster · Ken Mann · Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7a600b15-32ff-4c13-90e5-d4ee5f627bb5'::uuid, 'civicpatch:928579c0', 'kmann@cityoflancasterca.gov', '(661) 723-6019', 'https://www.cityoflancasterca.org/government/city-officials/city-council/council-member-mann', 'office', '2025-07-17T18:49:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7a600b15-32ff-4c13-90e5-d4ee5f627bb5'::uuid AND c.contact_type = 'office');

-- ca/place:lancaster · Lauren Hughes-Leslie · Deputy Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '007074c6-6fbe-429f-9e06-8d7251198d8a'::uuid, 'civicpatch:928579c0', 'lhughes-leslie@cityoflancasterca.gov', '(661) 723-6019', 'https://www.cityoflancasterca.org/government/commissions-appointments/deputy-mayor-lauren-hughes-leslie', 'office', '2025-07-17T18:49:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '007074c6-6fbe-429f-9e06-8d7251198d8a'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Rex Richardson · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '4c9d7584-4e07-46f7-8f8c-770afc8dce94'::uuid, 'civicpatch:928579c0', 'mayor@longbeach.gov', '(562) 570-6801', 'https://www.longbeach.gov/mayor', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '4c9d7584-4e07-46f7-8f8c-770afc8dce94'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Cindy Allen · Chair - Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a6893dff-7151-4dd2-8b5f-fb9124ee3c96'::uuid, 'civicpatch:928579c0', 'district2@longbeach.gov', '(562) 570-2222', 'https://www.longbeach.gov/district2', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a6893dff-7151-4dd2-8b5f-fb9124ee3c96'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Suely Saro · Chair - Vice Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b13891ed-faa2-481b-b773-7d0f0c2f6bbf'::uuid, 'civicpatch:928579c0', 'district6@longbeach.gov', '(562) 570-6816', 'https://www.longbeach.gov/district6', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b13891ed-faa2-481b-b773-7d0f0c2f6bbf'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Roberto Uranga · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '43534230-24b1-432a-9901-f1c666ed009e'::uuid, 'civicpatch:928579c0', 'district7@longbeach.gov', '(562) 570-7777', 'https://www.longbeach.gov/district7', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '43534230-24b1-432a-9901-f1c666ed009e'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Mary Zendejas · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '895b104d-b2d4-4c7c-a543-e3464774326d'::uuid, 'civicpatch:928579c0', 'district1@longbeach.gov', '(562) 570-6919', 'https://www.longbeach.gov/district1', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '895b104d-b2d4-4c7c-a543-e3464774326d'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Kristina Duggan · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '601fbd52-628a-4d50-8cb4-99890f056aa2'::uuid, 'civicpatch:928579c0', 'district3@longbeach.gov', '(562) 570-6300', 'https://www.longbeach.gov/district3', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '601fbd52-628a-4d50-8cb4-99890f056aa2'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Daryl Supernaw · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '296d94c3-756b-466a-9971-24a9bbce5776'::uuid, 'civicpatch:928579c0', 'district4@longbeach.gov', '(562) 570-4444', 'https://www.longbeach.gov/district4', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '296d94c3-756b-466a-9971-24a9bbce5776'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Megan Kerr · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6f3b9ac9-afde-4bef-9a18-31b8bef485da'::uuid, 'civicpatch:928579c0', 'district5@longbeach.gov', '(562) 570-5555', 'https://www.longbeach.gov/district5', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6f3b9ac9-afde-4bef-9a18-31b8bef485da'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Tunua Thrash-Ntuk · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '61aa19c9-4896-49f2-b68b-3192372cf001'::uuid, 'civicpatch:928579c0', 'district8@longbeach.gov', '(562) 570-6685', 'https://www.longbeach.gov/district8', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '61aa19c9-4896-49f2-b68b-3192372cf001'::uuid AND c.contact_type = 'office');

-- ca/place:long_beach · Joni Ricks-Oddie · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '780ddbc3-396e-44c2-8f4b-4a05a6a53ada'::uuid, 'civicpatch:928579c0', 'district9@longbeach.gov', '(562) 570-6137', 'https://www.longbeach.gov/district9', 'office', '2025-07-17T03:25:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '780ddbc3-396e-44c2-8f4b-4a05a6a53ada'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Eunisses Hernandez · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, 'civicpatch:928579c0', 'councilmember.hernandez@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Heather Hutt · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '29a8c85b-2572-463c-8034-8986615d7717'::uuid, 'civicpatch:928579c0', 'cd10@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '29a8c85b-2572-463c-8034-8986615d7717'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Traci Park · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd0977350-df68-4cfe-822e-816ba13f9213'::uuid, 'civicpatch:928579c0', 'councilmember.park@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd0977350-df68-4cfe-822e-816ba13f9213'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · John Lee · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9'::uuid, 'civicpatch:928579c0', 'councilmember.Lee@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Hugo Soto-Martinez · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, 'civicpatch:928579c0', 'councilmember.soto-martinez@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Tim McOsker · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '5cf02835-9024-4a00-80f7-bc2dcc3165df'::uuid, 'civicpatch:928579c0', 'councilmember.mcosker@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '5cf02835-9024-4a00-80f7-bc2dcc3165df'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Adrin Nazarian · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e30ddde5-a722-477b-837b-056fdc7e2d6b'::uuid, 'civicpatch:928579c0', 'Councilmember.Nazarian@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e30ddde5-a722-477b-837b-056fdc7e2d6b'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Bob Blumenfield · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0379cbef-05d8-4fd7-ba51-92b7661a4bbc'::uuid, 'civicpatch:928579c0', 'councilmember.blumenfield@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0379cbef-05d8-4fd7-ba51-92b7661a4bbc'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Nithya Raman · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, 'civicpatch:928579c0', 'contactCD4@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Katy Yaroslavsky · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'civicpatch:928579c0', 'councilmember.yaroslavsky@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '10678016-146d-4543-941c-00414b4c4ad2'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Imelda Padilla · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'::uuid, 'civicpatch:928579c0', 'councilmember.padilla@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Monica Rodriguez · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid, 'civicpatch:928579c0', 'councilmember.rodriguez@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Marqueece Harris-Dawson · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ece32bfa-26de-4177-9bb3-cea506870747'::uuid, 'civicpatch:928579c0', 'councilmember.harris-dawson@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ece32bfa-26de-4177-9bb3-cea506870747'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · Curren D. Price Jr. · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b'::uuid, 'civicpatch:928579c0', 'councilmember.price@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b'::uuid AND c.contact_type = 'office');

-- ca/place:palmdale · Richard J. Loa · Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6e5d3005-07e5-4c57-a3e0-033a2b17bbdc'::uuid, 'civicpatch:928579c0', 'rloa@cityofpalmdaleca.gov', NULL, 'https://cityofpalmdale.org/518/Councilmember-Richard-J-Loa', 'office', '2025-07-17T18:51:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6e5d3005-07e5-4c57-a3e0-033a2b17bbdc'::uuid AND c.contact_type = 'office');

-- ca/place:palmdale · Laura Bettencourt · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '362f1ec5-20aa-4e7a-a00d-7f626ae70138'::uuid, 'civicpatch:928579c0', 'lbettencourt@cityofpalmdaleca.gov', NULL, 'https://cityofpalmdale.org/305/Mayor-Pro-Tem-Laura-Bettencourt', 'office', '2025-07-17T18:51:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '362f1ec5-20aa-4e7a-a00d-7f626ae70138'::uuid AND c.contact_type = 'office');

-- ca/place:palmdale · Andrea Alarcón · Vice Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '579fb5f2-2313-4423-a412-b4ae101c6e8e'::uuid, 'civicpatch:928579c0', 'aalarcon@cityofpalmdaleca.gov', NULL, 'https://cityofpalmdale.org/308/Councilmember-Andrea-Alarcon', 'office', '2025-07-17T18:51:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '579fb5f2-2313-4423-a412-b4ae101c6e8e'::uuid AND c.contact_type = 'office');

-- ca/place:palmdale · Austin Bishop · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '475b846d-bce8-43e0-bac8-bd65d58d9c46'::uuid, 'civicpatch:928579c0', 'abishop@cityofpalmdaleca.gov', NULL, 'https://cityofpalmdale.org/306/Councilmember-Austin-Bishop', 'office', '2025-07-17T18:51:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '475b846d-bce8-43e0-bac8-bd65d58d9c46'::uuid AND c.contact_type = 'office');

-- ca/place:palmdale · Eric Ohlsen · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e024113e-ab16-4af6-aa75-d6ce89690a19'::uuid, 'civicpatch:928579c0', 'eohlsen@cityofpalmdaleca.gov', NULL, 'https://cityofpalmdale.org/307/Councilmember-Eric-Ohlsen', 'office', '2025-07-17T18:51:29+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e024113e-ab16-4af6-aa75-d6ce89690a19'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Victor M. Gordo · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '447ef220-cb9e-4ade-aba8-9dea87ed9931'::uuid, 'civicpatch:928579c0', 'vgordo@cityofpasadena.net', '(626) 744-4111', 'https://www.cityofpasadena.net/mayor/mayor-victor-gordo', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '447ef220-cb9e-4ade-aba8-9dea87ed9931'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Jess Rivas · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '07147263-4b98-415e-828d-70b5916946a9'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district5/bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '07147263-4b98-415e-828d-70b5916946a9'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Tyron Hampton · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f7826942-64bb-41bf-9588-407a2bc11e31'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district1/bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f7826942-64bb-41bf-9588-407a2bc11e31'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Rick Cole · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9f07a6d3-ecce-4105-be1d-23fb69d288c8'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district2', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9f07a6d3-ecce-4105-be1d-23fb69d288c8'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Justin Jones · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '59b781ad-22f8-46c9-b536-e19971e47fc1'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district3/bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '59b781ad-22f8-46c9-b536-e19971e47fc1'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Gene Masuda · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '39426238-e6c2-47d3-bc54-93b8559c9f6b'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district4/gene-masuda-bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '39426238-e6c2-47d3-bc54-93b8559c9f6b'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Steve Madison · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e2ce84d2-ee0b-4851-b1d8-168a2f54a82b'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district6/bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e2ce84d2-ee0b-4851-b1d8-168a2f54a82b'::uuid AND c.contact_type = 'office');

-- ca/place:pasadena · Jason Lyon · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0d3f6eaf-8f8e-4ec3-a2e7-a8e67487450e'::uuid, 'civicpatch:928579c0', NULL, NULL, 'https://www.cityofpasadena.net/district7/about/bio', 'office', '2025-07-17T19:23:07+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0d3f6eaf-8f8e-4ec3-a2e7-a8e67487450e'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Tim Sandoval · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '48f36a82-cb26-4701-ba08-5566533982cb'::uuid, 'civicpatch:928579c0', 'tim.sandoval@pomonaca.gov', '(909) 620-2053', 'https://www.pomonaca.gov/government/mayor-city-council/mayor-sandoval', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '48f36a82-cb26-4701-ba08-5566533982cb'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Victor Preciado · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '56cecf7c-6de0-440f-b8e2-34945ec52333'::uuid, 'civicpatch:928579c0', 'Victor.Preciado@pomonaca.gov', '(909) 630-3125', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-victor-preciado', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '56cecf7c-6de0-440f-b8e2-34945ec52333'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Steve Lustro · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '07e0311b-5013-49ac-849e-7aeaa3402ea2'::uuid, 'civicpatch:928579c0', 'steve.lustro@pomonaca.gov', '(909) 671-6114', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-steve-lustro', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '07e0311b-5013-49ac-849e-7aeaa3402ea2'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Debra Martin · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'db853cfa-ab6d-4a30-bfbc-fb05b3956970'::uuid, 'civicpatch:928579c0', 'debra.martin@pomonaca.gov', '(909) 298-3011', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-debra-martin', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'db853cfa-ab6d-4a30-bfbc-fb05b3956970'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Nora Garcia · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6fa28860-c3d6-45bf-8aad-eac353dc4559'::uuid, 'civicpatch:928579c0', 'Nora.Garcia@pomonaca.gov', '(909) 630-3378', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-nora-garcia', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6fa28860-c3d6-45bf-8aad-eac353dc4559'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Elizabeth Ontiveros-Cole · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9'::uuid, 'civicpatch:928579c0', 'Elizabeth.Ontiveros-Cole@pomonaca.gov', '(909) 837-8677', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-elizabeth-ontiveros-cole', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9'::uuid AND c.contact_type = 'office');

-- ca/place:pomona · Lorraine Canales · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3a578edc-56ad-43cf-ac8f-68d05fd5d7a8'::uuid, 'civicpatch:928579c0', 'Lorraine.Canales@pomonaca.gov', '(909) 298-3012', 'https://www.pomonaca.gov/government/mayor-city-council/councilmember-lorraine-canales', 'office', '2025-07-17T19:19:34+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3a578edc-56ad-43cf-ac8f-68d05fd5d7a8'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Kevin McCarty · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'b89b09f0-6a9f-46e5-9193-8a9de99867b0'::uuid, 'civicpatch:928579c0', 'mayor@cityofsacramento.org', '(916) 808-5300', 'https://www.cityofsacramento.gov/mayor-council/mayor/biography-of-mayor-mccarty', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'b89b09f0-6a9f-46e5-9193-8a9de99867b0'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Eric Guerra · Mayor Pro Tempore - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3b3b6525-7a40-4d01-a1cb-3270ed166919'::uuid, 'civicpatch:928579c0', 'eguerra@cityofsacramento.org', '(916) 808-7006', 'https://www.cityofsacramento.gov/mayor-council/district-6', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Karina Talamantes · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'cf2c7616-eb16-4830-be50-6d6096de44dd'::uuid, 'civicpatch:928579c0', 'District3@cityofsacramento.org', '(916) 808-7003', 'https://www.cityofsacramento.gov/mayor-council/district-3', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'cf2c7616-eb16-4830-be50-6d6096de44dd'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Lisa Kaplan · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6f8a1527-f8a4-4a2a-8270-9f0e1863826f'::uuid, 'civicpatch:928579c0', 'District1@cityofsacramento.org', '(916) 808-7001', 'https://www.cityofsacramento.gov/mayor-council/district-1', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6f8a1527-f8a4-4a2a-8270-9f0e1863826f'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Roger Dickinson · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8bb3b17a-334b-48e2-987a-090024c793b8'::uuid, 'civicpatch:928579c0', 'District2@cityofsacramento.org', '(916) 808-7002', 'https://www.cityofsacramento.gov/mayor-council/district-2', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8bb3b17a-334b-48e2-987a-090024c793b8'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Phil Pluckebaum · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '659de81d-ba74-4adf-98a2-dcb64de0f134'::uuid, 'civicpatch:928579c0', 'district4@cityofsacramento.org', '(916) 808-7004', 'https://www.cityofsacramento.gov/mayor-council/district-4', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '659de81d-ba74-4adf-98a2-dcb64de0f134'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Caity Maple · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '10758208-c20b-4729-8cea-4340caf8243c'::uuid, 'civicpatch:928579c0', 'District5@cityofsacramento.org', '(916) 808-7005', 'https://www.cityofsacramento.gov/mayor-council/district-5', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '10758208-c20b-4729-8cea-4340caf8243c'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Rick Jennings II · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f20601e0-0728-4c33-803c-28c88e170286'::uuid, 'civicpatch:928579c0', 'rjennings@cityofsacramento.org', '(916) 808-7007', 'https://www.cityofsacramento.gov/mayor-council/district-7', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f20601e0-0728-4c33-803c-28c88e170286'::uuid AND c.contact_type = 'office');

-- ca/place:sacramento · Mai Vang · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7'::uuid, 'civicpatch:928579c0', 'district8@cityofsacramento.org', NULL, 'https://www.cityofsacramento.gov/mayor-council/district-8', 'office', '2025-07-17T03:18:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Todd Gloria · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6330', 'https://www.sandiego.gov/mayor', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Jennifer Campbell · Chair - Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6622', 'https://www.sandiego.gov/citycouncil/cd2', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Marni von Wilpert · Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'::uuid, 'civicpatch:928579c0', 'marnivonwilpert@sandiego.gov', '(619) 236-6655', 'https://www.sandiego.gov/citycouncil/cd5', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Vivian Moreno · Chair - Vice Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid, 'civicpatch:928579c0', 'vivianmoreno@sandiego.gov', '(619) 236-6688', 'https://www.sandiego.gov/citycouncil/cd8', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Joe LaCava · Council President - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '1e93b635-3706-4268-91e2-97abae0c54a0'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6611', 'https://www.sandiego.gov/citycouncil/cd1', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '1e93b635-3706-4268-91e2-97abae0c54a0'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Kent Lee · Council President Pro Tem
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3fb56c85-f8b7-4732-88e1-f79b56750428'::uuid, 'civicpatch:928579c0', 'KentLee@sandiego.gov', '(619) 236-6616', 'https://www.sandiego.gov/citycouncil/cd6', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3fb56c85-f8b7-4732-88e1-f79b56750428'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Stephen Whitburn · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f86591f9-4341-4e3a-a9cb-f284887ccf74'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6633', 'https://www.sandiego.gov/citycouncil/cd3', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f86591f9-4341-4e3a-a9cb-f284887ccf74'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Raul Campillo · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6677', 'https://www.sandiego.gov/citycouncil/cd7', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · Sean Elo-Rivera · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, 'civicpatch:928579c0', NULL, '(619) 236-6699', 'https://www.sandiego.gov/citycouncil/cd9', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Daniel Lurie · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'civicpatch:928579c0', 'daniel.lurie@sfgov.org', NULL, 'https://www.sf.gov/profile--daniel-lurie', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Connie Chan · Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9'::uuid, 'civicpatch:928579c0', 'ChanStaff@sfgov.org', '(415) 554-7410', 'https://www.sf.gov/profile--connie-chan', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Shamann Walton · Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'eab7b830-c831-45f9-bca8-11b079f42680'::uuid, 'civicpatch:928579c0', 'waltonstaff@sfgov.org', '(415) 554-7670', 'https://www.sf.gov/profile--shamann-walton', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'eab7b830-c831-45f9-bca8-11b079f42680'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Matt Dorsey · Chair - Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '68845df3-7103-45d9-8429-7ef51ee6ada3'::uuid, 'civicpatch:928579c0', 'DorseyStaff@sfgov.org', '(415) 554-7970', 'https://www.sf.gov/profile--matt-dorsey', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '68845df3-7103-45d9-8429-7ef51ee6ada3'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Myrna Melgar · Chair - Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996'::uuid, 'civicpatch:928579c0', 'MelgarStaff@sfgov.org', '(415) 554-6516', 'https://www.sf.gov/profile--myrna-melgar', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Rafael Mandelman · Chair - Vice Chair - Council President - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd2596e4d-f491-449e-b112-40be13418112'::uuid, 'civicpatch:928579c0', 'mandelmanstaff@sfgov.org', '(415) 554-6968', 'https://www.sf.gov/profile--rafael-mandelman', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd2596e4d-f491-449e-b112-40be13418112'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Jackie Fielder · Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, 'civicpatch:928579c0', 'FielderStaff@sfgov.org', '(415) 554-5144', 'https://www.sf.gov/profile--jackie-fielder', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Chyanne Chen · Vice Chair - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, 'civicpatch:928579c0', 'ChenStaff@sfgov.org', '(415) 554-6975', 'https://www.sf.gov/profile--chyanne-chen', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Stephen Sherrill · Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '54e564e7-4788-4913-b75e-95382896d509'::uuid, 'civicpatch:928579c0', 'SherrillStaff@sfgov.org', '(415) 554-7752', 'https://www.sf.gov/profile--stephen-sherrill', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '54e564e7-4788-4913-b75e-95382896d509'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Danny Sauter · Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd1a320a9-39e9-4152-85a0-11cab602fdc9'::uuid, 'civicpatch:928579c0', 'SauterStaff@sfgov.org', '(415) 554-7450', 'https://www.sf.gov/profile--danny-sauter', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd1a320a9-39e9-4152-85a0-11cab602fdc9'::uuid AND c.contact_type = 'office');

-- ca/place:san_francisco · Bilal Mahmood · Vice Chair - Board Member - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'd3c5004c-9ca0-444e-96d9-107d4315abcb'::uuid, 'civicpatch:928579c0', 'MahmoodStaff@sfgov.org', '(415) 554-7630', 'https://www.sf.gov/profile--bilal-mahmood', 'office', '2025-07-17T03:13:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'd3c5004c-9ca0-444e-96d9-107d4315abcb'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Matt Mahan · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '41949a2b-563a-4608-91c6-951c63252a91'::uuid, 'civicpatch:928579c0', NULL, '(408) 535-4800', NULL, 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '41949a2b-563a-4608-91c6-951c63252a91'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Pam Foley · Vice Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab'::uuid, 'civicpatch:928579c0', 'district9@sanjoseca.gov', '(408) 535-4909', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Rosemary Kamei · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7921e8f3-2e6f-47f8-bc2b-95b81bab6516'::uuid, 'civicpatch:928579c0', NULL, '(408) 535-4901', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7921e8f3-2e6f-47f8-bc2b-95b81bab6516'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · George Casey · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f0d4ce8b-4ed7-45ec-b08e-439dded83313'::uuid, 'civicpatch:928579c0', 'district10@sanjoseca.gov', '(408) 535-4910', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-10', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f0d4ce8b-4ed7-45ec-b08e-439dded83313'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Pamela Campos · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '104cca89-3420-457b-a35d-b446be2d72ab'::uuid, 'civicpatch:928579c0', 'district2@sanjoseca.gov', '(408) 535-4902', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2/councilmember-pamela-campos-biography', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '104cca89-3420-457b-a35d-b446be2d72ab'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · David Cohen · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '83292881-92b3-4257-b291-4b02509a167c'::uuid, 'civicpatch:928579c0', 'District4@sanjoseca.gov', '(408) 535-4904', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-4', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '83292881-92b3-4257-b291-4b02509a167c'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Peter Ortiz · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a464cef9-de7f-45a3-8ff3-9bab20275db4'::uuid, 'civicpatch:928579c0', 'district5@sanjoseca.gov', '(408) 535-4905', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5/peter-ortiz-biography', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a464cef9-de7f-45a3-8ff3-9bab20275db4'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Michael Mulcahy · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a05e1faa-c780-4a65-b01f-cca7e6f0210b'::uuid, 'civicpatch:928579c0', 'district6@sanjoseca.gov', '(408) 535-4906', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a05e1faa-c780-4a65-b01f-cca7e6f0210b'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Bien Doan · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'e4ac6674-1fa3-422a-857f-570873b86da3'::uuid, 'civicpatch:928579c0', NULL, '(408) 535-4907', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-7', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'e4ac6674-1fa3-422a-857f-570873b86da3'::uuid AND c.contact_type = 'office');

-- ca/place:san_jose · Domingo Candelas · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'ab7cf49d-73af-4391-9a15-ebe0522e5bc5'::uuid, 'civicpatch:928579c0', 'district8@sanjoseca.gov', '(408) 535-4908', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-8', 'office', '2025-07-17T03:13:35+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'ab7cf49d-73af-4391-9a15-ebe0522e5bc5'::uuid AND c.contact_type = 'office');

-- ca/place:santa_clarita · Bill Miranda · Mayor
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9'::uuid, 'civicpatch:928579c0', NULL, '(661) 259-2489', 'https://santaclarita.gov/city-council/bill-miranda', 'office', '2025-07-17T17:22:01+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9'::uuid AND c.contact_type = 'office');

-- ca/place:santa_clarita · Jason Gibbs · Mayor - Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '434cd9b0-ce80-42fd-b71d-f221349e33f5'::uuid, 'civicpatch:928579c0', NULL, '(661) 259-2489', 'https://santaclarita.gov/city-council/jason-gibbs', 'office', '2025-07-17T17:22:01+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '434cd9b0-ce80-42fd-b71d-f221349e33f5'::uuid AND c.contact_type = 'office');

-- ca/place:santa_clarita · Laurene Weste · Mayor Pro Tempore
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '6854ec39-d6e2-44c4-8c60-0d809234f935'::uuid, 'civicpatch:928579c0', NULL, '(661) 259-2489', 'https://santaclarita.gov/city-council/laurene-weste', 'office', '2025-07-17T17:22:01+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '6854ec39-d6e2-44c4-8c60-0d809234f935'::uuid AND c.contact_type = 'office');

-- ca/place:santa_clarita · Marsha McLean · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9476ec1c-9e60-4dae-b398-c81c63f6f670'::uuid, 'civicpatch:928579c0', NULL, '(661) 259-2489', 'https://santaclarita.gov/city-council/marsha-mclean', 'office', '2025-07-17T17:22:01+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9476ec1c-9e60-4dae-b398-c81c63f6f670'::uuid AND c.contact_type = 'office');

-- ca/place:santa_clarita · Patsy Ayala · Council Member
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '3dab8dca-2ce0-403b-8f4f-d6137e11731d'::uuid, 'civicpatch:928579c0', NULL, '(661) 259-2489', 'https://santaclarita.gov/city-council/patsy-ayala', 'office', '2025-07-17T17:22:01+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '3dab8dca-2ce0-403b-8f4f-d6137e11731d'::uuid AND c.contact_type = 'office');

-- Post-verify gate: every intended politician must now carry an 'office' contact, and this
-- migration must not have created a second one for anybody.
DO $$
DECLARE
  expected int := 136;
  covered  int;
  dupes    int;
BEGIN
  SELECT count(*) INTO covered
    FROM essentials.politician_contacts
   WHERE contact_type = 'office'
     AND politician_id IN ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, 'd2013613-769f-4374-809e-a018dbc1e683'::uuid, 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid, '9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid, '8cc1c412-fe14-4bc6-b1e2-02d95997fd47'::uuid, '424eb63b-9976-4059-8049-365c09719cc6'::uuid, '116aace8-9440-498b-bf1d-ebb196727c85'::uuid, '7833be90-c693-40b8-a309-61ee77b4ba03'::uuid, '96f91743-def6-436c-9537-a4b836c1b3eb'::uuid, 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'::uuid, 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349'::uuid, '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'::uuid, 'f933bd87-d397-4ef1-873b-57559b629000'::uuid, '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e'::uuid, 'd1b1bc73-575f-444e-a2f8-46c04b07d3f8'::uuid, '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5'::uuid, '1581974b-2a8c-4439-acae-377bc06e1788'::uuid, '174f3f47-e4ee-4775-ab6f-f1039d608098'::uuid, 'a5db6e7d-2146-4dde-a778-05fa40566ac0'::uuid, 'f63d8129-c569-4ea5-bd77-5cda877b2185'::uuid, '9a37b6e4-13bc-48c0-97b3-22aaa253c054'::uuid, '92d68971-8cc2-480b-8e29-9938f7a280f1'::uuid, '71c35909-e5b5-40ca-883f-21af5c287b5e'::uuid, '13dc32dd-fac5-440d-9f10-f1f1892acf68'::uuid, '4967617f-5919-4816-8661-a675f05e8b66'::uuid, '71124b00-549d-460c-8f84-41a01d99e037'::uuid, 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff'::uuid, '28839e39-6db1-4253-94a4-94ae234c241e'::uuid, 'f886f6da-d08f-4294-81bc-faf4a1eaad4d'::uuid, '7db82a3d-5aa2-4150-996e-b170b50b47fe'::uuid, 'd6d492b6-cbaf-4398-9301-4fbd10da571f'::uuid, '42e95c4c-4e02-4d60-805c-6a3d857dd95a'::uuid, '84eebb94-9163-40ec-8cc2-1391a00e636e'::uuid, 'a223d51d-7077-4d9d-98b0-bcfafabbbc71'::uuid, 'deea52f0-0422-4fc8-971a-27a2471e14f2'::uuid, 'e7a155f4-eb21-4e0f-b901-695f64ccb5cb'::uuid, '7dff1af1-993e-4d8f-8901-e4f96b93f11d'::uuid, 'f75231e6-b6e4-4b1b-8ce5-d275c3f4bb7f'::uuid, '86ceb1d5-b225-4a1b-9eb0-bb708532eea8'::uuid, '01f9f586-aac2-4c17-8f1c-faf031f7de29'::uuid, 'a5595064-ce36-4b12-8eca-a2d796759d53'::uuid, '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid, '6ed19c10-7b34-47f0-8705-0d154271e362'::uuid, '729bc539-3175-4e5d-96ba-c18768890e1e'::uuid, '87546d4d-78ee-4aae-82cb-89ae805e10b4'::uuid, '7a600b15-32ff-4c13-90e5-d4ee5f627bb5'::uuid, '007074c6-6fbe-429f-9e06-8d7251198d8a'::uuid, '4c9d7584-4e07-46f7-8f8c-770afc8dce94'::uuid, 'a6893dff-7151-4dd2-8b5f-fb9124ee3c96'::uuid, 'b13891ed-faa2-481b-b773-7d0f0c2f6bbf'::uuid, '43534230-24b1-432a-9901-f1c666ed009e'::uuid, '895b104d-b2d4-4c7c-a543-e3464774326d'::uuid, '601fbd52-628a-4d50-8cb4-99890f056aa2'::uuid, '296d94c3-756b-466a-9971-24a9bbce5776'::uuid, '6f3b9ac9-afde-4bef-9a18-31b8bef485da'::uuid, '61aa19c9-4896-49f2-b68b-3192372cf001'::uuid, '780ddbc3-396e-44c2-8f4b-4a05a6a53ada'::uuid, '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '29a8c85b-2572-463c-8034-8986615d7717'::uuid, 'd0977350-df68-4cfe-822e-816ba13f9213'::uuid, 'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9'::uuid, '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '5cf02835-9024-4a00-80f7-bc2dcc3165df'::uuid, 'e30ddde5-a722-477b-837b-056fdc7e2d6b'::uuid, '0379cbef-05d8-4fd7-ba51-92b7661a4bbc'::uuid, '26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'::uuid, '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid, 'ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '725d4081-e820-4064-83dc-3f8470bd7c2b'::uuid, '6e5d3005-07e5-4c57-a3e0-033a2b17bbdc'::uuid, '362f1ec5-20aa-4e7a-a00d-7f626ae70138'::uuid, '579fb5f2-2313-4423-a412-b4ae101c6e8e'::uuid, '475b846d-bce8-43e0-bac8-bd65d58d9c46'::uuid, 'e024113e-ab16-4af6-aa75-d6ce89690a19'::uuid, '447ef220-cb9e-4ade-aba8-9dea87ed9931'::uuid, '07147263-4b98-415e-828d-70b5916946a9'::uuid, 'f7826942-64bb-41bf-9588-407a2bc11e31'::uuid, '9f07a6d3-ecce-4105-be1d-23fb69d288c8'::uuid, '59b781ad-22f8-46c9-b536-e19971e47fc1'::uuid, '39426238-e6c2-47d3-bc54-93b8559c9f6b'::uuid, 'e2ce84d2-ee0b-4851-b1d8-168a2f54a82b'::uuid, '0d3f6eaf-8f8e-4ec3-a2e7-a8e67487450e'::uuid, '48f36a82-cb26-4701-ba08-5566533982cb'::uuid, '56cecf7c-6de0-440f-b8e2-34945ec52333'::uuid, '07e0311b-5013-49ac-849e-7aeaa3402ea2'::uuid, 'db853cfa-ab6d-4a30-bfbc-fb05b3956970'::uuid, '6fa28860-c3d6-45bf-8aad-eac353dc4559'::uuid, 'b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9'::uuid, '3a578edc-56ad-43cf-ac8f-68d05fd5d7a8'::uuid, 'b89b09f0-6a9f-46e5-9193-8a9de99867b0'::uuid, '3b3b6525-7a40-4d01-a1cb-3270ed166919'::uuid, 'cf2c7616-eb16-4830-be50-6d6096de44dd'::uuid, '6f8a1527-f8a4-4a2a-8270-9f0e1863826f'::uuid, '8bb3b17a-334b-48e2-987a-090024c793b8'::uuid, '659de81d-ba74-4adf-98a2-dcb64de0f134'::uuid, '10758208-c20b-4729-8cea-4340caf8243c'::uuid, 'f20601e0-0728-4c33-803c-28c88e170286'::uuid, 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7'::uuid, 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'::uuid, 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'::uuid, '0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid, '1e93b635-3706-4268-91e2-97abae0c54a0'::uuid, '3fb56c85-f8b7-4732-88e1-f79b56750428'::uuid, 'f86591f9-4341-4e3a-a9cb-f284887ccf74'::uuid, '84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9'::uuid, 'eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '68845df3-7103-45d9-8429-7ef51ee6ada3'::uuid, '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996'::uuid, 'd2596e4d-f491-449e-b112-40be13418112'::uuid, '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, '54e564e7-4788-4913-b75e-95382896d509'::uuid, 'd1a320a9-39e9-4152-85a0-11cab602fdc9'::uuid, 'd3c5004c-9ca0-444e-96d9-107d4315abcb'::uuid, '41949a2b-563a-4608-91c6-951c63252a91'::uuid, '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab'::uuid, '7921e8f3-2e6f-47f8-bc2b-95b81bab6516'::uuid, 'f0d4ce8b-4ed7-45ec-b08e-439dded83313'::uuid, '104cca89-3420-457b-a35d-b446be2d72ab'::uuid, '83292881-92b3-4257-b291-4b02509a167c'::uuid, 'a464cef9-de7f-45a3-8ff3-9bab20275db4'::uuid, 'a05e1faa-c780-4a65-b01f-cca7e6f0210b'::uuid, 'e4ac6674-1fa3-422a-857f-570873b86da3'::uuid, 'ab7cf49d-73af-4391-9a15-ebe0522e5bc5'::uuid, '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9'::uuid, '434cd9b0-ce80-42fd-b71d-f221349e33f5'::uuid, '6854ec39-d6e2-44c4-8c60-0d809234f935'::uuid, '9476ec1c-9e60-4dae-b398-c81c63f6f670'::uuid, '3dab8dca-2ce0-403b-8f4f-d6137e11731d'::uuid);
  IF covered <> expected THEN
    RAISE EXCEPTION 'expected % politicians with an office contact, found %', expected, covered;
  END IF;

  -- Scoped to THIS batch: prod may hold unrelated duplicate office contacts elsewhere,
  -- and this gate must fail only on damage we caused.
  SELECT count(*) INTO dupes FROM (
    SELECT politician_id FROM essentials.politician_contacts
     WHERE contact_type = 'office'
       AND politician_id IN ('965de422-660e-4e24-9fe6-717cc0313403'::uuid, 'd2013613-769f-4374-809e-a018dbc1e683'::uuid, 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid, '9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid, '8cc1c412-fe14-4bc6-b1e2-02d95997fd47'::uuid, '424eb63b-9976-4059-8049-365c09719cc6'::uuid, '116aace8-9440-498b-bf1d-ebb196727c85'::uuid, '7833be90-c693-40b8-a309-61ee77b4ba03'::uuid, '96f91743-def6-436c-9537-a4b836c1b3eb'::uuid, 'ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'::uuid, 'a83a63a8-3e0f-4a2e-9226-8c0cd26a1349'::uuid, '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'::uuid, 'f933bd87-d397-4ef1-873b-57559b629000'::uuid, '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e'::uuid, 'd1b1bc73-575f-444e-a2f8-46c04b07d3f8'::uuid, '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5'::uuid, '1581974b-2a8c-4439-acae-377bc06e1788'::uuid, '174f3f47-e4ee-4775-ab6f-f1039d608098'::uuid, 'a5db6e7d-2146-4dde-a778-05fa40566ac0'::uuid, 'f63d8129-c569-4ea5-bd77-5cda877b2185'::uuid, '9a37b6e4-13bc-48c0-97b3-22aaa253c054'::uuid, '92d68971-8cc2-480b-8e29-9938f7a280f1'::uuid, '71c35909-e5b5-40ca-883f-21af5c287b5e'::uuid, '13dc32dd-fac5-440d-9f10-f1f1892acf68'::uuid, '4967617f-5919-4816-8661-a675f05e8b66'::uuid, '71124b00-549d-460c-8f84-41a01d99e037'::uuid, 'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff'::uuid, '28839e39-6db1-4253-94a4-94ae234c241e'::uuid, 'f886f6da-d08f-4294-81bc-faf4a1eaad4d'::uuid, '7db82a3d-5aa2-4150-996e-b170b50b47fe'::uuid, 'd6d492b6-cbaf-4398-9301-4fbd10da571f'::uuid, '42e95c4c-4e02-4d60-805c-6a3d857dd95a'::uuid, '84eebb94-9163-40ec-8cc2-1391a00e636e'::uuid, 'a223d51d-7077-4d9d-98b0-bcfafabbbc71'::uuid, 'deea52f0-0422-4fc8-971a-27a2471e14f2'::uuid, 'e7a155f4-eb21-4e0f-b901-695f64ccb5cb'::uuid, '7dff1af1-993e-4d8f-8901-e4f96b93f11d'::uuid, 'f75231e6-b6e4-4b1b-8ce5-d275c3f4bb7f'::uuid, '86ceb1d5-b225-4a1b-9eb0-bb708532eea8'::uuid, '01f9f586-aac2-4c17-8f1c-faf031f7de29'::uuid, 'a5595064-ce36-4b12-8eca-a2d796759d53'::uuid, '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid, '6ed19c10-7b34-47f0-8705-0d154271e362'::uuid, '729bc539-3175-4e5d-96ba-c18768890e1e'::uuid, '87546d4d-78ee-4aae-82cb-89ae805e10b4'::uuid, '7a600b15-32ff-4c13-90e5-d4ee5f627bb5'::uuid, '007074c6-6fbe-429f-9e06-8d7251198d8a'::uuid, '4c9d7584-4e07-46f7-8f8c-770afc8dce94'::uuid, 'a6893dff-7151-4dd2-8b5f-fb9124ee3c96'::uuid, 'b13891ed-faa2-481b-b773-7d0f0c2f6bbf'::uuid, '43534230-24b1-432a-9901-f1c666ed009e'::uuid, '895b104d-b2d4-4c7c-a543-e3464774326d'::uuid, '601fbd52-628a-4d50-8cb4-99890f056aa2'::uuid, '296d94c3-756b-466a-9971-24a9bbce5776'::uuid, '6f3b9ac9-afde-4bef-9a18-31b8bef485da'::uuid, '61aa19c9-4896-49f2-b68b-3192372cf001'::uuid, '780ddbc3-396e-44c2-8f4b-4a05a6a53ada'::uuid, '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid, '29a8c85b-2572-463c-8034-8986615d7717'::uuid, 'd0977350-df68-4cfe-822e-816ba13f9213'::uuid, 'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9'::uuid, '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '5cf02835-9024-4a00-80f7-bc2dcc3165df'::uuid, 'e30ddde5-a722-477b-837b-056fdc7e2d6b'::uuid, '0379cbef-05d8-4fd7-ba51-92b7661a4bbc'::uuid, '26dbe16a-9dff-42c0-939f-5b5e529063ca'::uuid, '10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'::uuid, '7c0d3bdd-a363-4d97-93a9-67034c6a0ead'::uuid, 'ece32bfa-26de-4177-9bb3-cea506870747'::uuid, '725d4081-e820-4064-83dc-3f8470bd7c2b'::uuid, '6e5d3005-07e5-4c57-a3e0-033a2b17bbdc'::uuid, '362f1ec5-20aa-4e7a-a00d-7f626ae70138'::uuid, '579fb5f2-2313-4423-a412-b4ae101c6e8e'::uuid, '475b846d-bce8-43e0-bac8-bd65d58d9c46'::uuid, 'e024113e-ab16-4af6-aa75-d6ce89690a19'::uuid, '447ef220-cb9e-4ade-aba8-9dea87ed9931'::uuid, '07147263-4b98-415e-828d-70b5916946a9'::uuid, 'f7826942-64bb-41bf-9588-407a2bc11e31'::uuid, '9f07a6d3-ecce-4105-be1d-23fb69d288c8'::uuid, '59b781ad-22f8-46c9-b536-e19971e47fc1'::uuid, '39426238-e6c2-47d3-bc54-93b8559c9f6b'::uuid, 'e2ce84d2-ee0b-4851-b1d8-168a2f54a82b'::uuid, '0d3f6eaf-8f8e-4ec3-a2e7-a8e67487450e'::uuid, '48f36a82-cb26-4701-ba08-5566533982cb'::uuid, '56cecf7c-6de0-440f-b8e2-34945ec52333'::uuid, '07e0311b-5013-49ac-849e-7aeaa3402ea2'::uuid, 'db853cfa-ab6d-4a30-bfbc-fb05b3956970'::uuid, '6fa28860-c3d6-45bf-8aad-eac353dc4559'::uuid, 'b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9'::uuid, '3a578edc-56ad-43cf-ac8f-68d05fd5d7a8'::uuid, 'b89b09f0-6a9f-46e5-9193-8a9de99867b0'::uuid, '3b3b6525-7a40-4d01-a1cb-3270ed166919'::uuid, 'cf2c7616-eb16-4830-be50-6d6096de44dd'::uuid, '6f8a1527-f8a4-4a2a-8270-9f0e1863826f'::uuid, '8bb3b17a-334b-48e2-987a-090024c793b8'::uuid, '659de81d-ba74-4adf-98a2-dcb64de0f134'::uuid, '10758208-c20b-4729-8cea-4340caf8243c'::uuid, 'f20601e0-0728-4c33-803c-28c88e170286'::uuid, 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7'::uuid, 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'::uuid, 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'::uuid, '0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid, '1e93b635-3706-4268-91e2-97abae0c54a0'::uuid, '3fb56c85-f8b7-4732-88e1-f79b56750428'::uuid, 'f86591f9-4341-4e3a-a9cb-f284887ccf74'::uuid, '84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, 'dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, '708db738-2bf1-4a6f-b8a5-7ac23d171b33'::uuid, 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9'::uuid, 'eab7b830-c831-45f9-bca8-11b079f42680'::uuid, '68845df3-7103-45d9-8429-7ef51ee6ada3'::uuid, '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996'::uuid, 'd2596e4d-f491-449e-b112-40be13418112'::uuid, '02f88a57-ccf5-4fe1-a693-7fc949321fb1'::uuid, '8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid, '54e564e7-4788-4913-b75e-95382896d509'::uuid, 'd1a320a9-39e9-4152-85a0-11cab602fdc9'::uuid, 'd3c5004c-9ca0-444e-96d9-107d4315abcb'::uuid, '41949a2b-563a-4608-91c6-951c63252a91'::uuid, '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab'::uuid, '7921e8f3-2e6f-47f8-bc2b-95b81bab6516'::uuid, 'f0d4ce8b-4ed7-45ec-b08e-439dded83313'::uuid, '104cca89-3420-457b-a35d-b446be2d72ab'::uuid, '83292881-92b3-4257-b291-4b02509a167c'::uuid, 'a464cef9-de7f-45a3-8ff3-9bab20275db4'::uuid, 'a05e1faa-c780-4a65-b01f-cca7e6f0210b'::uuid, 'e4ac6674-1fa3-422a-857f-570873b86da3'::uuid, 'ab7cf49d-73af-4391-9a15-ebe0522e5bc5'::uuid, '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9'::uuid, '434cd9b0-ce80-42fd-b71d-f221349e33f5'::uuid, '6854ec39-d6e2-44c4-8c60-0d809234f935'::uuid, '9476ec1c-9e60-4dae-b398-c81c63f6f670'::uuid, '3dab8dca-2ce0-403b-8f4f-d6137e11731d'::uuid)
     GROUP BY politician_id HAVING count(*) > 1) d;
  IF dupes > 0 THEN
    RAISE EXCEPTION 'duplicate office contacts for % politicians', dupes;
  END IF;
END $$;

COMMIT;
