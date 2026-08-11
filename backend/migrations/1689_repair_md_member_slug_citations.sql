-- 1689_repair_md_member_slug_citations.sql
--
-- Every Maryland stance whose cited mgaleg MEMBER page is dead or belongs to a DIFFERENT POLITICIAN.
--
-- 🔴 THE DEFECT: a member-page citation can name the wrong person and pass every previous check --
-- the URL returns 200, it is a real member page, and it carries the right surname. Nothing keyed on
-- 404s, topic vocabulary, or source count could see it.
--   Adrienne A. Jones cited jones01 = "another member"
--   Courtney Watson cited watson04 = "another member"
--   Matthew Morgan cited morgan03 = "another member"
-- The rest cite pages that do not exist at all (mgaleg answers 200 and redirects to /Error/NotFound,
-- so status code alone never revealed them).
--
-- HOW EACH REPLACEMENT WAS ESTABLISHED -- and it is not by guessing a suffix, which is what created
-- this mess in the first place:
--   1. candidate slugs came from the MGA roster (current members) or enumeration (former members)
--   2. every candidate was FETCHED IN THE EXACT FORM IT WILL BE STORED and its page title read
--   3. only a page titled with this politician's own name was accepted
-- ⚠ Slugs may contain SPACES ("jacobs j", "miller a", "davis d") -- a [A-Za-z0-9]+ pattern truncates
--   them into a DIFFERENT member's slug. That bug briefly turned Jay A. Jacobs into Nancy Jacobs.
-- ⚠ Former members resolve only with a session: those URLs keep ?ys=, because the citation must work
--   as stored, not merely in principle.
--
-- SCOPE: 300 rows across 33 politicians. Citations only -- NO stance value is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-member-slug-repair-1689-rollback.json
--
BEGIN
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Adrienne A. Jones / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid
;  -- Adrienne A. Jones / Campaign Finance Reform

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Adrienne A. Jones / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Adrienne A. Jones / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Adrienne A. Jones / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Adrienne A. Jones / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid
;  -- Adrienne A. Jones / Medicare / Medicaid

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Adrienne A. Jones / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Adrienne A. Jones / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Adrienne A. Jones / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Adrienne A. Jones / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Andrew C. Pruski / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Andrew C. Pruski / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Andrew C. Pruski / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Andrew C. Pruski / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Andrew C. Pruski / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Andrew C. Pruski / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Andrew C. Pruski / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01','https://ballotpedia.org/Andrew_Pruski']::text[]
WHERE politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Andrew C. Pruski / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Anne Healey / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Anne Healey / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Anne Healey / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Anne Healey / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Anne Healey / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Anne Healey / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Anne Healey / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Anne Healey / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Anne Healey / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Anne Healey / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Anne Healey / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Anne Healey / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]
WHERE politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Anne Healey / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Aruna Miller / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Aruna Miller / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Aruna Miller / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Aruna Miller / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Aruna Miller / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Aruna Miller / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Aruna Miller / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Aruna Miller / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Aruna Miller / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Aruna Miller / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller','https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS']::text[]
WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Aruna Miller / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Ben Barnes / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid
;  -- Ben Barnes / Campaign Finance Reform

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Ben Barnes / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Ben Barnes / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Ben Barnes / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Ben Barnes / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Ben Barnes / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Ben Barnes / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Ben Barnes / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid
;  -- Ben Barnes / Medicare / Medicaid

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Ben Barnes / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Ben Barnes / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Ben Barnes / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Ben Barnes / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Ben Barnes / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]
WHERE politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Ben Barnes / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Bill Ferguson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid
;  -- Bill Ferguson / Campaign Finance Reform

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Bill Ferguson / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Bill Ferguson / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson','https://marylandmatters.org/2022/04/09/senate-president-bill-ferguson/']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Bill Ferguson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- Bill Ferguson / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson','https://marylandmatters.org/2024/01/20/fergusons-economic-agenda/']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Bill Ferguson / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Bill Ferguson / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Bill Ferguson / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Bill Ferguson / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid
;  -- Bill Ferguson / Jail Capacity and Incarceration Alternatives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid
;  -- Bill Ferguson / Medicare / Medicaid

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- Bill Ferguson / Police Accountability

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Bill Ferguson / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Bill Ferguson / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Bill Ferguson / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson','https://marylandmatters.org/2021/02/25/blueprint-for-marylands-future/']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Bill Ferguson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Bill Ferguson / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson','https://marylandmatters.org/2024/02/12/fergusons-priorities-for-2024-session/']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Bill Ferguson / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]
WHERE politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Bill Ferguson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Brian Chisholm / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Brian Chisholm / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Brian Chisholm / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Brian Chisholm / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Brian Chisholm / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Brian Chisholm / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Brian Chisholm / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Brooke Lierman / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Brooke Lierman / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS','https://marylandmatters.org/brooke-lierman-climate/']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Brooke Lierman / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid
;  -- Brooke Lierman / Environmental Protection vs. Development

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Brooke Lierman / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Brooke Lierman / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Brooke Lierman / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Brooke Lierman / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Brooke Lierman / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Brooke Lierman / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Brooke Lierman / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Brooke Lierman / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Brooke Lierman / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]
WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Brooke Lierman / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- C. T. Wilson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- C. T. Wilson / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- C. T. Wilson / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- C. T. Wilson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- C. T. Wilson / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- C. T. Wilson / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- C. T. Wilson / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- C. T. Wilson / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- C. T. Wilson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- C. T. Wilson / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- C. T. Wilson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Courtney Watson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Courtney Watson / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Courtney Watson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Courtney Watson / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Courtney Watson / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Courtney Watson / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Courtney Watson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Courtney Watson / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Courtney Watson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://www.ontheissues.org/Governor/Dan_Cox_Immigration.htm','https://mgaleg.maryland.gov/mgawebsite/Members/Details/cox01?ys=2023RS']::text[]
WHERE politician_id = '4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Dan Cox / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cox01?ys=2023RS','https://www.ontheissues.org/Governor/Dan_Cox_Principles_+_Values.htm']::text[]
WHERE politician_id = '4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid
;  -- Dan Cox / Religious Freedom

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Dana Jones / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Dana Jones / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dana Jones / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Dana Jones / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Dana Jones / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Dana Jones / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Dana Jones / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Dana Stein / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Dana Stein / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Dana Stein / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Dana Stein / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Dana Stein / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Dana Stein / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Debra Davis / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Debra Davis / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Debra Davis / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Debra Davis / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Debra Davis / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Debra Davis / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Debra Davis / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Denise Roberts / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Denise Roberts / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Denise Roberts / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Denise Roberts / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Denise Roberts / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Denise Roberts / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Denise Roberts / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Denise Roberts / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Denise Roberts / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Denise Roberts / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]
WHERE politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Denise Roberts / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis%20d?ys=2025RS','https://ballotpedia.org/Dereck_Davis']::text[]
WHERE politician_id = '75378a96-8886-46eb-b0c1-37cbe2579265'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Dereck E. Davis / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://marylandtaxes.gov/','https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis%20d?ys=2025RS']::text[]
WHERE politician_id = '75378a96-8886-46eb-b0c1-37cbe2579265'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Dereck E. Davis / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis%20d?ys=2025RS','https://ballotpedia.org/Dereck_Davis']::text[]
WHERE politician_id = '75378a96-8886-46eb-b0c1-37cbe2579265'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Dereck E. Davis / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis%20d?ys=2025RS','https://marylandtaxes.gov/','https://ballotpedia.org/Dereck_Davis']::text[]
WHERE politician_id = '75378a96-8886-46eb-b0c1-37cbe2579265'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Dereck E. Davis / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Dylan Behler / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dylan Behler / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Dylan Behler / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Dylan Behler / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Dylan Behler / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01','https://ballotpedia.org/Dylan_Behler']::text[]
WHERE politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Dylan Behler / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Edith J. Patterson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Edith J. Patterson / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Edith J. Patterson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Edith J. Patterson / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Edith J. Patterson / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Edith J. Patterson / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Edith J. Patterson / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Edith J. Patterson / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Edith J. Patterson / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Heather Bagnall / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Heather Bagnall / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Heather Bagnall / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Heather Bagnall / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Heather Bagnall / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Heather Bagnall / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Heather Bagnall / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Heather Bagnall / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Heather Bagnall / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Heather Bagnall / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Heather Bagnall / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Joseline Peña-Melnyk / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Joseline Peña-Melnyk / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Joseline Peña-Melnyk / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Joseline Peña-Melnyk / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Joseline Peña-Melnyk / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Joseline Peña-Melnyk / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Joseline Peña-Melnyk / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Joseline Peña-Melnyk / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid
;  -- Joseline Peña-Melnyk / Medicare / Medicaid

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Joseline Peña-Melnyk / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid
;  -- Joseline Peña-Melnyk / Religious Freedom

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Joseline Peña-Melnyk / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
;  -- Joseline Peña-Melnyk / Same-Sex Marriage

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Joseline Peña-Melnyk / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Joseline Peña-Melnyk / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Joseline Peña-Melnyk / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Joseline Peña-Melnyk / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]
WHERE politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Joseline Peña-Melnyk / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Kym Taylor / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Kym Taylor / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Kym Taylor / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Kym Taylor / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Kym Taylor / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Kym Taylor / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Kym Taylor / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Kym Taylor / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Kym Taylor / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Kym Taylor / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Kym Taylor / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Kym Taylor / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01','https://ballotpedia.org/LaToya_Nkongolo']::text[]
WHERE politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- LaToya Nkongolo / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01','https://ballotpedia.org/LaToya_Nkongolo']::text[]
WHERE politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- LaToya Nkongolo / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01','https://ballotpedia.org/LaToya_Nkongolo']::text[]
WHERE politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- LaToya Nkongolo / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01','https://ballotpedia.org/LaToya_Nkongolo']::text[]
WHERE politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- LaToya Nkongolo / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01','https://ballotpedia.org/LaToya_Nkongolo']::text[]
WHERE politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- LaToya Nkongolo / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Marvin E. Holmes, Jr. / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Marvin E. Holmes, Jr. / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Marvin E. Holmes, Jr. / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Marvin E. Holmes, Jr. / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Marvin E. Holmes, Jr. / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Marvin E. Holmes, Jr. / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Marvin E. Holmes, Jr. / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Marvin E. Holmes, Jr. / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Marvin E. Holmes, Jr. / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Marvin E. Holmes, Jr. / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]
WHERE politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Marvin E. Holmes, Jr. / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Mary-Dulany James / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Mary-Dulany James / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mary-Dulany James / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Mary-Dulany James / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Mary-Dulany James / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Mary-Dulany James / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Mary-Dulany James / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Mary-Dulany James / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]
WHERE politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Mary-Dulany James / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Matthew Morgan / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Matthew Morgan / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Matthew Morgan / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Matthew Morgan / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Matthew Morgan / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Matthew Morgan / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Matthew Morgan / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Matthew Morgan / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- N. Scott Phillips / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- N. Scott Phillips / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- N. Scott Phillips / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- N. Scott Phillips / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- N. Scott Phillips / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- N. Scott Phillips / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- N. Scott Phillips / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]
WHERE politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- N. Scott Phillips / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Nancy J. King / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Nancy J. King / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Nancy J. King / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Nancy J. King / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Nancy J. King / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Nancy J. King / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Nancy J. King / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Nancy J. King / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Natalie Ziegler / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Natalie Ziegler / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Natalie Ziegler / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Natalie Ziegler / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Natalie Ziegler / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Natalie Ziegler / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Nicole A. Williams / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Nicole A. Williams / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Nicole A. Williams / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Nicole A. Williams / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Nicole A. Williams / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Nicole A. Williams / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Nicole A. Williams / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Nicole A. Williams / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Nicole A. Williams / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Nicole A. Williams / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Nicole A. Williams / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]
WHERE politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Nicole A. Williams / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Pam Lanman Guzzone / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Pam Lanman Guzzone / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Pam Lanman Guzzone / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Pam Lanman Guzzone / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Pam Lanman Guzzone / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Pam Lanman Guzzone / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]
WHERE politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Pam Lanman Guzzone / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Seth A. Howard / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Seth A. Howard / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Seth A. Howard / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Seth A. Howard / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Seth A. Howard / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Seth A. Howard / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Seth A. Howard / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Terri L. Hill / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Terri L. Hill / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Terri L. Hill / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Terri L. Hill / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Terri L. Hill / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Terri L. Hill / Voting Rights and Electoral Integrity

DO $$
DECLARE bad int;
BEGIN
  -- No politician may still cite THEIR OWN bad slug.
  -- ⚠ This check MUST be per politician, never corpus-wide: `jones01` is Adrienne A. Jones's WRONG
  -- slug and Dana Jones's CORRECT one, so a global "nobody cites jones01" assertion would fire on a
  -- correctly repaired row. Same shape of over-broad assertion as migs 1524/1530.
  -- ⚠ Where the repair only ADDS A SESSION to the same slug (Dan Cox: bare `cox01` is dead,
  -- `cox01?ys=2023RS` names him), the bad and good URLs share a slug. Asserting "no row cites cox01?%"
  -- matches the REPAIRED url, because `?` is a LITERAL in SQL LIKE, not a wildcard. For those entries
  -- assert only that the BARE form is gone. The first version of this guard failed on exactly that.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
    (c.politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND (s LIKE '%Members/Details/jones01' OR s LIKE '%Members/Details/jones01?%'))
    OR (c.politician_id = 'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid AND (s LIKE '%Members/Details/pruski' OR s LIKE '%Members/Details/pruski?%'))
    OR (c.politician_id = '4436b432-a63f-4946-919a-f30c41f899e4'::uuid AND (s LIKE '%Members/Details/healey01' OR s LIKE '%Members/Details/healey01?%'))
    OR (c.politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid AND (s LIKE '%Members/Details/miller01' OR s LIKE '%Members/Details/miller01?%'))
    OR (c.politician_id = '590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid AND (s LIKE '%Members/Details/barnes01' OR s LIKE '%Members/Details/barnes01?%'))
    OR (c.politician_id = '6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid AND (s LIKE '%Members/Details/ferguson01' OR s LIKE '%Members/Details/ferguson01?%'))
    OR (c.politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND (s LIKE '%Members/Details/chisholm' OR s LIKE '%Members/Details/chisholm?%'))
    OR (c.politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid AND (s LIKE '%Members/Details/lierman' OR s LIKE '%Members/Details/lierman?%'))
    OR (c.politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND (s LIKE '%Members/Details/wilson04' OR s LIKE '%Members/Details/wilson04?%'))
    OR (c.politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND (s LIKE '%Members/Details/watson04' OR s LIKE '%Members/Details/watson04?%'))
    OR (c.politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND (s LIKE '%Members/Details/jones08' OR s LIKE '%Members/Details/jones08?%'))
    OR (c.politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND (s LIKE '%Members/Details/stein01' OR s LIKE '%Members/Details/stein01?%'))
    OR (c.politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND (s LIKE '%Members/Details/davis01' OR s LIKE '%Members/Details/davis01?%'))
    OR (c.politician_id = 'd5999df9-83b8-4870-a170-4d13f40473e2'::uuid AND (s LIKE '%Members/Details/roberts03' OR s LIKE '%Members/Details/roberts03?%'))
    OR (c.politician_id = '75378a96-8886-46eb-b0c1-37cbe2579265'::uuid AND (s LIKE '%Members/Details/davisd' OR s LIKE '%Members/Details/davisd?%'))
    OR (c.politician_id = '3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid AND (s LIKE '%Members/Details/behler' OR s LIKE '%Members/Details/behler?%'))
    OR (c.politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND (s LIKE '%Members/Details/patterson03' OR s LIKE '%Members/Details/patterson03?%'))
    OR (c.politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND (s LIKE '%Members/Details/bagnall' OR s LIKE '%Members/Details/bagnall?%'))
    OR (c.politician_id = '8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid AND (s LIKE '%Members/Details/jacobs' OR s LIKE '%Members/Details/jacobs?%'))
    OR (c.politician_id = '00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid AND (s LIKE '%Members/Details/pena01' OR s LIKE '%Members/Details/pena01?%'))
    OR (c.politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid AND (s LIKE '%Members/Details/taylor05' OR s LIKE '%Members/Details/taylor05?%'))
    OR (c.politician_id = '13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid AND (s LIKE '%Members/Details/nkongolo' OR s LIKE '%Members/Details/nkongolo?%'))
    OR (c.politician_id = 'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid AND (s LIKE '%Members/Details/holmes01' OR s LIKE '%Members/Details/holmes01?%'))
    OR (c.politician_id = '18313901-28d8-464c-9368-2873577e9d44'::uuid AND (s LIKE '%Members/Details/james06' OR s LIKE '%Members/Details/james06?%'))
    OR (c.politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND (s LIKE '%Members/Details/morgan03' OR s LIKE '%Members/Details/morgan03?%'))
    OR (c.politician_id = '04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid AND (s LIKE '%Members/Details/phillips04' OR s LIKE '%Members/Details/phillips04?%'))
    OR (c.politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND (s LIKE '%Members/Details/king01' OR s LIKE '%Members/Details/king01?%'))
    OR (c.politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND (s LIKE '%Members/Details/ziegler02' OR s LIKE '%Members/Details/ziegler02?%'))
    OR (c.politician_id = '5c24446e-c9d6-4dda-9703-e3c049798315'::uuid AND (s LIKE '%Members/Details/williams08' OR s LIKE '%Members/Details/williams08?%'))
    OR (c.politician_id = '589ed7af-602a-4ec9-8072-448b05446772'::uuid AND (s LIKE '%Members/Details/guzzone03' OR s LIKE '%Members/Details/guzzone03?%'))
    OR (c.politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND (s LIKE '%Members/Details/howard02' OR s LIKE '%Members/Details/howard02?%'))
    OR (c.politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND (s LIKE '%Members/Details/hill04' OR s LIKE '%Members/Details/hill04?%'))
    OR (c.politician_id = '4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid AND s LIKE '%Members/Details/cox01')
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite their own bad slug', bad; END IF;

  -- Every politician repaired here must end up citing their verified replacement URL on at least one row.
  SELECT count(*) INTO bad FROM (
    SELECT v.pid FROM (VALUES
      ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones'),
      ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski01'),
      ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey'),
      ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller%20a?ys=2019RS'),
      ('590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes'),
      ('6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson'),
      ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01'),
      ('b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS'),
      ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson'),
      ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02'),
      ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01'),
      ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein'),
      ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02'),
      ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01'),
      ('75378a96-8886-46eb-b0c1-37cbe2579265'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis%20d?ys=2025RS'),
      ('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler01'),
      ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02'),
      ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01'),
      ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j'),
      ('00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena'),
      ('9273ed81-2052-428a-b39d-849abeef270b'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03'),
      ('13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo01'),
      ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes'),
      ('18313901-28d8-464c-9368-2873577e9d44'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01'),
      ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02'),
      ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02'),
      ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/king'),
      ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01'),
      ('5c24446e-c9d6-4dda-9703-e3c049798315'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01'),
      ('589ed7af-602a-4ec9-8072-448b05446772'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01'),
      ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01'),
      ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02'),
      ('4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cox01?ys=2023RS')
    ) AS v(pid, newurl)
    WHERE NOT EXISTS (
      SELECT 1 FROM inform.politician_context c, unnest(c.sources) s
      WHERE c.politician_id = v.pid AND s = v.newurl
    )
  ) d;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) lack their replacement citation', bad; END IF;

  -- Nobody may be left sourceless, and no source array may contain duplicates.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = ANY(ARRAY['760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid,'590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid,'6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid,'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid,'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid,'69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid,'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid,'d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'75378a96-8886-46eb-b0c1-37cbe2579265'::uuid,'3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid,'9273ed81-2052-428a-b39d-849abeef270b'::uuid,'13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid,'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'18313901-28d8-464c-9368-2873577e9d44'::uuid,'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'589ed7af-602a-4ec9-8072-448b05446772'::uuid,'2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid])
    AND (c.sources IS NULL OR cardinality(c.sources) = 0);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) left with no sources', bad; END IF;

  SELECT count(*) INTO bad FROM (
    SELECT c.politician_id, c.topic_id FROM inform.politician_context c
    WHERE c.politician_id = ANY(ARRAY['760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'ea9fc2d6-3b26-469a-978c-e8c846d2d49a'::uuid,'590b56b2-1473-4e86-ba96-0490e172f6ff'::uuid,'6e3c30f5-52be-48b0-b5b4-383e5d745c57'::uuid,'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid,'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid,'69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid,'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid,'d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'75378a96-8886-46eb-b0c1-37cbe2579265'::uuid,'3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid,'9273ed81-2052-428a-b39d-849abeef270b'::uuid,'13462ee2-0dd9-4f70-809f-a813c23951d4'::uuid,'b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'18313901-28d8-464c-9368-2873577e9d44'::uuid,'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'589ed7af-602a-4ec9-8072-448b05446772'::uuid,'2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid])
    AND cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s)
  ) d;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) have duplicate sources', bad; END IF;
END
$$;

COMMIT
;
