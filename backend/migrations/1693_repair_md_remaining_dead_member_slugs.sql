-- 1693_repair_md_remaining_dead_member_slugs.sql
--
-- 5 politicians whose stances still cited a DEAD mgaleg member page. Same defect and same remedy as
-- mig 1689 -- these were HIDDEN FROM IT by the bug in the original audit.
--
-- 🔴 WHY THEY WERE MISSED, and it is the lesson: the old audit fetched the bare slug and then
-- session-qualified variants but cached them all under the bare slug's filename. `hayes01?ys=2019RS`
-- names Antonio Hayes -- it is his page from when he was a Delegate -- so the audit recorded "OK" while
-- the STORED bare `hayes01` is NotFound. A slug changes when a member moves chamber and the old one
-- stops resolving without a session. Re-running with the cache keyed on the FULL URL exposed all five.
-- ⚠ 3 of them (Hayes, McCray, Carozza) had exactly ONE row repaired by mig 1687, which is why they
-- looked partly fixed; the rest of their rows kept the dead citation.
--
-- Every replacement was confirmed by fetching it IN THE FORM IT WILL BE STORED and reading the page
-- title. All five resolve BARE, each `01` -> `02`:
--   Antonio Hayes: hayes01 -> hayes02 ("Antonio Hayes")
--   Chris West: west01 -> west02 ("Chris West")
--   Cory V. McCray: mccray01 -> mccray02 ("Cory V. McCray")
--   Dalya Attar: attar01 -> attar02 ("Dalya Attar")
--   Mary Beth Carozza: carozza01 -> carozza02 ("Mary Beth Carozza")
--
-- SCOPE: 46 rows across 5 politicians. Citations only -- NO stance value modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-remaining-dead-slugs-1693-rollback.json
--
BEGIN
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Antonio Hayes / Affordable Housing  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = '1fab5edf-6151-4da0-9704-a7f2113ba54c'::uuid
;  -- Antonio Hayes / Bail and Pretrial Decisions  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Antonio Hayes / Civil Rights and Social Justice  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Antonio Hayes / Economic Development Incentives  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Antonio Hayes / Healthcare Access  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid
;  -- Antonio Hayes / Jail Capacity and Incarceration Alternatives  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Antonio Hayes / Reproductive Rights and Abortion Access  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Antonio Hayes / School Vouchers & Public Education Funding  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Antonio Hayes / Taxation and Public Spending  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Antonio Hayes / Voting Rights and Electoral Integrity  (hayes01 -> hayes02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Chris West / Climate Change and Environmental Protection  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Chris West / Economic Development Incentives  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Chris West / Fossil Fuel Policy  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Chris West / Healthcare Access  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Chris West / Public Safety Approach  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Chris West / Reproductive Rights and Abortion Access  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Chris West / School Vouchers & Public Education Funding  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Chris West / Taxation and Public Spending  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Chris West / Voting Rights and Electoral Integrity  (west01 -> west02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Cory V. McCray / Affordable Housing  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Cory V. McCray / Civil Rights and Social Justice  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Cory V. McCray / Climate Change and Environmental Protection  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Cory V. McCray / Economic Development Incentives  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Cory V. McCray / Fossil Fuel Policy  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Cory V. McCray / Healthcare Access  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid
;  -- Cory V. McCray / Jail Capacity and Incarceration Alternatives  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Cory V. McCray / Public Safety Approach  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Cory V. McCray / Reproductive Rights and Abortion Access  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Cory V. McCray / Taxation and Public Spending  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Cory V. McCray / Voting Rights and Electoral Integrity  (mccray01 -> mccray02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Dalya Attar / Affordable Housing  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Dalya Attar / Civil Rights and Social Justice  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dalya Attar / Climate Change and Environmental Protection  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Dalya Attar / Economic Development Incentives  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Dalya Attar / Healthcare Access  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Dalya Attar / School Vouchers & Public Education Funding  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Dalya Attar / Taxation and Public Spending  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Dalya Attar / Voting Rights and Electoral Integrity  (attar01 -> attar02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Mary Beth Carozza / Civil Rights and Social Justice  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Mary Beth Carozza / Economic Development Incentives  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Mary Beth Carozza / Fossil Fuel Policy  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Mary Beth Carozza / Healthcare Access  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Mary Beth Carozza / Reproductive Rights and Abortion Access  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Mary Beth Carozza / School Vouchers & Public Education Funding  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Mary Beth Carozza / Taxation and Public Spending  (carozza01 -> carozza02)

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Mary Beth Carozza / Voting Rights and Electoral Integrity  (carozza01 -> carozza02)

DO $$
DECLARE bad int;
BEGIN
  -- Per politician (never corpus-wide: an 01 slug can be somebody else's correct page).
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
    (c.politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND (s LIKE '%Members/Details/hayes01' OR s LIKE '%Members/Details/hayes01?%'))
    OR (c.politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND (s LIKE '%Members/Details/west01' OR s LIKE '%Members/Details/west01?%'))
    OR (c.politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND (s LIKE '%Members/Details/mccray01' OR s LIKE '%Members/Details/mccray01?%'))
    OR (c.politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND (s LIKE '%Members/Details/attar01' OR s LIKE '%Members/Details/attar01?%'))
    OR (c.politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND (s LIKE '%Members/Details/carozza01' OR s LIKE '%Members/Details/carozza01?%'))
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite their own dead slug', bad; END IF;

  -- Each politician must now carry their verified replacement somewhere.
  SELECT count(*) INTO bad FROM (VALUES
    ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02'),
    ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02'),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02'),
    ('fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02'),
    ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid, 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02')
  ) AS v(pid, newurl)
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c, unnest(c.sources) s WHERE c.politician_id = v.pid AND s = v.newurl
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) lack their replacement citation', bad; END IF;

  -- No duplicates, nobody sourceless.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = ANY(ARRAY['04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid,'54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid,'9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid])
    AND (c.sources IS NULL OR cardinality(c.sources) = 0
         OR cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s));
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) empty or duplicated', bad; END IF;
END
$$;

COMMIT
;
