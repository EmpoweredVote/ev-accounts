-- 1698_resource_md_pass6_generic_only_stances.sql
-- Maryland PASS 6 -- re-source GENERIC-ONLY stances to the instruments they already name.
--
-- WHY THIS COHORT EXISTS: passes 1-5 selected work POLITICIAN-level (distinct source sets = 1 AND
-- >= 5 rows). That test excludes anyone who has ANY row with a specific citation, so as passes 4/5
-- fixed some of a politician's rows, that politician dropped OUT of the queue carrying their
-- remaining defective rows with them. Re-measured ROW-level, the real defect population is 1,241
-- rows across 154 politicians, of which 618 rows had never been audited at all.
--
-- EVIDENCE. Each row's named instrument was resolved against a local corpus of 73,232 MD bills
-- (2013RS-2026RS) rebuilt from the MGA session indexes, then either:
--   SPONSOR  -- the legislator's OWN mgaleg slug appears in that bill's "Sponsored by" list AND the
--               bill title carries the named act at the year the reasoning states; or
--   ROLLCALL -- a PASSAGE floor-vote PDF names the member and the direction matches the claim.
--
-- SCOPE: 124 rows across 39 legislators. CITATIONS ONLY -- no stance value, no
-- reasoning, no deletions. Corpus row count must be UNCHANGED by this migration.
--
-- DELIBERATELY NOT INCLUDED (each needs a human; none is a delete list):
--   46 rows whose every candidate citation is suspect (act ambiguous across sessions 22, bare bill
--      number resolving to another session 15, stated year stale 7, no title fit 2)
--   70 roll calls UNRESOLVED, 15 VOID_WRONG_BILL (vote real but on an unrelated bill)
--    1 CONTRADICTED  -- Anne Healey / abortion: prose says "voted for" the ACAA, parse says NAY on
--                       2022RS HB0937. Read the PDF and confirm surname identity before acting.
--   21 PRE_TENURE verdicts that are CONTAMINATED -- the tenure screen judged against wrong-session
--      bills (Mark Edelson screened on 2013RS bills though his instruments are 2024-2026).
--   10 surname-only matches, 3 tenure-unknown, and 937 rows naming no instrument at all.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-pass6-resource-rollback.json
--
BEGIN
;

-- Snapshot BEFORE any write, inside the transaction. Guard 2 compares against this.
-- ⚠ Taking the "before" count in the same statement as the "after" count compares a value to
-- itself and passes unconditionally -- a guard that cannot fail is not a guard.
CREATE TEMP TABLE pass6_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]
WHERE politician_id = 'b389687f-817b-4fda-8770-a888029f4629'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] April Miller / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]
WHERE politician_id = 'b389687f-817b-4fda-8770-a888029f4629'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] April Miller / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]
WHERE politician_id = 'b389687f-817b-4fda-8770-a888029f4629'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] April Miller / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]
WHERE politician_id = 'b389687f-817b-4fda-8770-a888029f4629'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] April Miller / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] April Rose / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1633?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [SPONSOR] April Rose / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] April Rose / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] April Rose / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] April Rose / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]
WHERE politician_id = '5967c703-2583-466f-a438-c3ac182111d5'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] April Rose / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]
WHERE politician_id = '00a1eaeb-157c-42f8-a6e5-9a9d02decbe9'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Barrie S. Ciliberti / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]
WHERE politician_id = '00a1eaeb-157c-42f8-a6e5-9a9d02decbe9'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Barrie S. Ciliberti / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]
WHERE politician_id = 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- [SPONSOR] Barry Beauchamp / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]
WHERE politician_id = 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Barry Beauchamp / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]
WHERE politician_id = 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Barry Beauchamp / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]
WHERE politician_id = 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] Barry Beauchamp / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01','https://ballotpedia.org/Barry_Beauchamp']::text[]
WHERE politician_id = 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Barry Beauchamp / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0760?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS']::text[]
WHERE politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- [SPONSOR] Brian J. Feldman / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0931?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS','https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]
WHERE politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714'::uuid AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid
;  -- [SPONSOR] Brian J. Feldman / Environmental Protection vs. Development

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0205?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]
WHERE politician_id = '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Chris Tomlinson / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]
WHERE politician_id = '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Chris Tomlinson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]
WHERE politician_id = '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Chris Tomlinson / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]
WHERE politician_id = '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] Chris Tomlinson / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]
WHERE politician_id = '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Chris Tomlinson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0205?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]
WHERE politician_id = 'c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Christopher Eric Bouchat / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]
WHERE politician_id = 'c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [SPONSOR] Christopher Eric Bouchat / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]
WHERE politician_id = 'c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Christopher Eric Bouchat / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]
WHERE politician_id = 'c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Christopher Eric Bouchat / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]
WHERE politician_id = '1eada938-f28c-46b9-bd21-df241656cd2b'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Christopher T. Adams / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]
WHERE politician_id = '1eada938-f28c-46b9-bd21-df241656cd2b'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Christopher T. Adams / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]
WHERE politician_id = '1eada938-f28c-46b9-bd21-df241656cd2b'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Christopher T. Adams / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01','https://ballotpedia.org/Christopher_Adams_(Maryland)']::text[]
WHERE politician_id = '1eada938-f28c-46b9-bd21-df241656cd2b'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Christopher T. Adams / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0314?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]
WHERE politician_id = 'fc23b939-0dfd-4968-ab19-fc1e7745e997'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- [SPONSOR] Clarence K. Lam / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0943?ys=2025RS','https://en.wikipedia.org/wiki/Craig_Zucker','https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]
WHERE politician_id = '82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Craig J. Zucker / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0342?ys=2025RS','https://en.wikipedia.org/wiki/Craig_Zucker','https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]
WHERE politician_id = '82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Craig J. Zucker / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0039?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]
WHERE politician_id = 'a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [SPONSOR] Deni Taveras / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]
WHERE politician_id = 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- [SPONSOR] Gabriel Acevero / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0562?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]
WHERE politician_id = 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- [SPONSOR] Gabriel Acevero / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]
WHERE politician_id = 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [SPONSOR] Gabriel Acevero / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]
WHERE politician_id = 'd17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] H. Kevin Anderson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]
WHERE politician_id = 'd17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] H. Kevin Anderson / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01','https://ballotpedia.org/Kevin_Anderson_(Maryland_politician)']::text[]
WHERE politician_id = 'd17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] H. Kevin Anderson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]
WHERE politician_id = '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- [SPONSOR] Jason C. Buckel / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]
WHERE politician_id = '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Jason C. Buckel / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]
WHERE politician_id = '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Jason C. Buckel / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]
WHERE politician_id = '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] Jason C. Buckel / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]
WHERE politician_id = '5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Jason C. Buckel / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]
WHERE politician_id = '8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Jay A. Jacobs / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]
WHERE politician_id = '8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Jay A. Jacobs / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]
WHERE politician_id = '8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Jay A. Jacobs / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j','https://ballotpedia.org/Jay_Jacobs_(Maryland)']::text[]
WHERE politician_id = '8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Jay A. Jacobs / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0074?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- [SPONSOR] Jeff Waldstreicher / Police Accountability

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]
WHERE politician_id = 'eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Jefferson L. Ghrist / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]
WHERE politician_id = 'eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Jefferson L. Ghrist / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01','https://ballotpedia.org/Jefferson_Ghrist']::text[]
WHERE politician_id = 'eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Jefferson L. Ghrist / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Jesse T. Pippy / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1633?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [SPONSOR] Jesse T. Pippy / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Jesse T. Pippy / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Jesse T. Pippy / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] Jesse T. Pippy / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]
WHERE politician_id = 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Jesse T. Pippy / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]
WHERE politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- [SPONSOR] Jim Hinebaugh, Jr. / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]
WHERE politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Jim Hinebaugh, Jr. / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]
WHERE politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Jim Hinebaugh, Jr. / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]
WHERE politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Jim Hinebaugh, Jr. / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]
WHERE politician_id = '96a6d696-50fd-4393-a0f6-19e69dc15716'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- [SPONSOR] Kevin B. Hornberger / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01','https://ballotpedia.org/Kevin_Hornberger']::text[]
WHERE politician_id = '96a6d696-50fd-4393-a0f6-19e69dc15716'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Kevin B. Hornberger / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1536?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]
WHERE politician_id = '2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- [SPONSOR] Lesley J. Lopez / Deportation Priorities

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]
WHERE politician_id = '2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- [SPONSOR] Lesley J. Lopez / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1536?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]
WHERE politician_id = '2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- [SPONSOR] Lesley J. Lopez / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]
WHERE politician_id = '62bed8b6-beb2-4c41-b234-dc6427bfc9c0'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [SPONSOR] Marlon Amprey / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]
WHERE politician_id = '62bed8b6-beb2-4c41-b234-dc6427bfc9c0'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [SPONSOR] Marlon Amprey / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]
WHERE politician_id = '0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Mike Griffith / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]
WHERE politician_id = '0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Mike Griffith / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]
WHERE politician_id = '0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Mike Griffith / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]
WHERE politician_id = 'eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [SPONSOR] Robert B. Long / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]
WHERE politician_id = 'eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Robert B. Long / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]
WHERE politician_id = 'eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Robert B. Long / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]
WHERE politician_id = 'eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Robert B. Long / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0514?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]
WHERE politician_id = '36eecaff-4677-441a-b36e-a323e87d9158'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid
;  -- [SPONSOR] Samuel I. Rosenberg / Campaign Finance Reform

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0327?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]
WHERE politician_id = '3089c813-f0a8-46af-9a7b-1699129037e9'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- [SPONSOR] Shelly Hettleman / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0432?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS','https://en.wikipedia.org/wiki/Shelly_L._Hettleman']::text[]
WHERE politician_id = '3089c813-f0a8-46af-9a7b-1699129037e9'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Shelly Hettleman / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0431?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS','https://ballotpedia.org/Shelly_Hettleman']::text[]
WHERE politician_id = '3089c813-f0a8-46af-9a7b-1699129037e9'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- [SPONSOR] Shelly Hettleman / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0943?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]
WHERE politician_id = '3089c813-f0a8-46af-9a7b-1699129037e9'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- [SPONSOR] Shelly Hettleman / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0071?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01','https://ballotpedia.org/Sheree_Sample-Hughes']::text[]
WHERE politician_id = 'a1c2b55c-df7d-487c-ad90-7f7e2c2e6951'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- [SPONSOR] Sheree Sample-Hughes / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]
WHERE politician_id = 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Steven J. Arentz / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]
WHERE politician_id = 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Steven J. Arentz / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]
WHERE politician_id = 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Steven J. Arentz / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01','https://ballotpedia.org/Steven_Arentz']::text[]
WHERE politician_id = 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Steven J. Arentz / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]
WHERE politician_id = '58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Susan K. McComas / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]
WHERE politician_id = '58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- [SPONSOR] Susan K. McComas / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]
WHERE politician_id = '58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Susan K. McComas / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]
WHERE politician_id = '58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Susan K. McComas / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]
WHERE politician_id = '547841f2-3476-4e83-9344-0cac984d44e8'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Teresa E. Reilly / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]
WHERE politician_id = '547841f2-3476-4e83-9344-0cac984d44e8'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Teresa E. Reilly / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]
WHERE politician_id = '547841f2-3476-4e83-9344-0cac984d44e8'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Teresa E. Reilly / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01','https://ballotpedia.org/Teresa_Reilly_(Maryland)']::text[]
WHERE politician_id = '547841f2-3476-4e83-9344-0cac984d44e8'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Teresa E. Reilly / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]
WHERE politician_id = 'fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Thomas S. Hutchinson / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]
WHERE politician_id = 'fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Thomas S. Hutchinson / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01','https://ballotpedia.org/Thomas_Hutchinson_(Maryland)']::text[]
WHERE politician_id = 'fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Thomas S. Hutchinson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0622?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]
WHERE politician_id = '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- [SPONSOR] Wayne A. Hartman / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0455?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]
WHERE politician_id = '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [SPONSOR] Wayne A. Hartman / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]
WHERE politician_id = '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] Wayne A. Hartman / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]
WHERE politician_id = '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [SPONSOR] Wayne A. Hartman / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01','https://ballotpedia.org/Wayne_Hartman']::text[]
WHERE politician_id = '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] Wayne A. Hartman / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0074?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0599?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0600?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- [SPONSOR] William C. Smith, Jr. / Police Accountability

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]
WHERE politician_id = 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [SPONSOR] William J. Wivell / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]
WHERE politician_id = 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- [SPONSOR] William J. Wivell / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]
WHERE politician_id = 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- [SPONSOR] William J. Wivell / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [ROLLCALL] Anne Healey / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [ROLLCALL] Anne Healey / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/house/0685.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [ROLLCALL] Anne Healey / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [ROLLCALL] Ben Barnes / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- [ROLLCALL] Jeff Waldstreicher / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [ROLLCALL] Marvin E. Holmes, Jr. / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- [ROLLCALL] Marvin E. Holmes, Jr. / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/house/0685.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [ROLLCALL] Marvin E. Holmes, Jr. / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2022RS-legislation']::text[]
WHERE politician_id = '251a2047-372b-480e-aa09-231f9a5edeca'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [ROLLCALL] Mary A. Lehman / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2022RS-legislation']::text[]
WHERE politician_id = '251a2047-372b-480e-aa09-231f9a5edeca'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- [ROLLCALL] Mary A. Lehman / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- [ROLLCALL] Nicole A. Williams / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/house/0685.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [ROLLCALL] Nicole A. Williams / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/senate/0749.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- [ROLLCALL] William C. Smith, Jr. / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/senate/0749.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- [ROLLCALL] William C. Smith, Jr. / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/senate/0749.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- [ROLLCALL] William C. Smith, Jr. / Taxation and Public Spending

-- Guard 1: every touched row must now carry a specific citation (a bill page or a vote sheet).
-- ⚠ Scoped to the rows this migration touches. A scoped guard CANNOT answer a corpus-wide question
-- (that is why mig 1691 had to exist) -- the corpus-wide check is run separately after applying.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('b389687f-817b-4fda-8770-a888029f4629'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('b389687f-817b-4fda-8770-a888029f4629'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b389687f-817b-4fda-8770-a888029f4629'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('b389687f-817b-4fda-8770-a888029f4629'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('d423151e-8477-470d-8f73-ba7d2092f714'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('d423151e-8477-470d-8f73-ba7d2092f714'::uuid,'1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid),
    ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('fc23b939-0dfd-4968-ab19-fc1e7745e997'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('d17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('d17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('96a6d696-50fd-4393-a0f6-19e69dc15716'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('96a6d696-50fd-4393-a0f6-19e69dc15716'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('2fa68ca4-00b5-4518-a692-d12447d7fec3'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('36eecaff-4677-441a-b36e-a323e87d9158'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('3089c813-f0a8-46af-9a7b-1699129037e9'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3089c813-f0a8-46af-9a7b-1699129037e9'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('3089c813-f0a8-46af-9a7b-1699129037e9'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('3089c813-f0a8-46af-9a7b-1699129037e9'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('251a2047-372b-480e-aa09-231f9a5edeca'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('251a2047-372b-480e-aa09-231f9a5edeca'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(c.sources) s
    WHERE s LIKE '%Legislation/Details/%' OR s LIKE '%/votes/%'
  );
  IF missing > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % row(s) lack a specific citation', missing;
  END IF;
END
$$;

-- Guard 2: this migration must not delete or create anything. Deltas are asserted against a
-- snapshot taken INSIDE the transaction, never against a hard-coded corpus total.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM pass6_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans
  FROM inform.politician_answers a
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
  );
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 2 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 2 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % answer(s) without context', orphans;
  END IF;
  RAISE NOTICE 'pass6 ok: context=% (unchanged) answers=% (unchanged) orphans=%',
    ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
