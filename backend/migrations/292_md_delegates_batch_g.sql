-- ============================================================================
-- Migration 292: MD Delegates Batch G — Districts 41-47
-- ============================================================================
-- Purpose: Insert/upsert stance data for 21 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~223 rows expected
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- Jackie Addison
-- ============================================================

-- ----- Jackie Addison / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Addison sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation agreements — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Addison co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Addison sponsored Criminal Law - Drug Paraphernalia and Controlled Paraphernalia Prohibitions - Repeal and Qualifying Nonprofit Organizations - Incarcerated Individual Reentry Grant Fund — strongly decarceration-oriented and rehabilitative.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Addison sponsored Commission on the House of Reformation and Instruction for Colored Children and Criminal Procedure - PACE Act protecting artists' expression — strong champion of racial equity and civil liberties.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Addison sponsored Public Safety - Gun Violence Victim Relocation Program and Maryland Use of Force Statute - Failure to Prevent Excessive Force — services and accountability approach over pure enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Addison sponsored Hospitals - Clinical Staffing Committees (Safe Staffing Act 2026) and Income Tax Credit for Physician Preceptors in shortage areas — supports expanded healthcare access and hospital staffing standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Addison sponsored Land Use - Permitting - Development Rights (Maryland Housing Certainty Act) — supports streamlining housing development to address affordability crisis with mixed-income development approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Addison sponsored Child Care Facilities - Criminal History Records Check and Human Services - Foster Care Transition Grant Program — supports expanded child welfare standards and foster care services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Addison sponsored Corporate Income Tax - Addition Modification - Direct-to-Consumer Pharmaceutical Advertising (closing pharma tax loophole) — supports closing corporate tax breaks.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Addison / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Addison sponsored Election Districts - General Assembly and Representatives in Congress — directly working on redistricting as a Baltimore City Democrat who supports fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Regina T. Boyce
-- ============================================================

-- ----- Regina T. Boyce / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Boyce sponsored Voting Rights Act of 2026 - Counties and Municipal Corporations — among the strongest voting rights stances possible demonstrating commitment to expanded local ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Boyce sponsored Public Safety - Immigration Enforcement Agreements - Prohibition legislation directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Boyce co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Boyce sponsored Water Pollution Control - Animal Feeding Operations permits and EV Infrastructure Council and Maryland Zero Emission Electric Vehicle Infrastructure — strong climate/clean energy action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Boyce sponsored Maryland Zero Emission Electric Vehicle Infrastructure Council - Membership and Condominiums - EV Recharging Equipment — supporting EV transition signals opposition to fossil fuel dependence.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Boyce sponsored Water Pollution Control - Animal Feeding Operations and Local Government - Regulatory Powers - Regulation of Invasive Trees and Municipalities - Open Drainage Inlets — active local environmental regulation advocate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Boyce sponsored Health Insurance - Scalp Cooling Systems - Required Coverage (expanding health insurance mandates) — supports government-mandated coverage expansions and public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Boyce sponsored Adult Prison School Board Model Development Committee — prison education/rehabilitation focus — and Task Force on Responsible Use of Natural Psychedelic Substances — progressive on criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Boyce sponsored Civil Actions - Stop Silencing Survivors Act protecting sexual assault disclosure and Criminal Procedure - Protection of Identity of Victims — strong champion of civil protections for vulnerable populations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Boyce sponsored Residential Child Care Programs - Education legislation — supports government standards for child care quality and welfare in her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Boyce sponsored immigration enforcement prohibition and adult prison education — services-first approach with emphasis on social support over enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Regina T. Boyce / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('027a2610-1160-4525-a5c1-469fe85d46e1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a Baltimore City Democrat supporting expanded social programs EV infrastructure and climate legislation Boyce supports higher taxes on high earners and corporations to fund public investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Luke Clippinger
-- ============================================================

-- ----- Luke Clippinger / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Clippinger sponsored Conversion Therapy - Prohibitions and Causes of Action legislation directly prohibiting conversion therapy and creating civil liability — strong LGBTQ+ rights champion; consistent with strong support for same-sex marriage and full LGBTQ+ civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Clippinger sponsored Conversion Therapy - Prohibitions and Causes of Action and HIV Prevention Drugs - Prescribing Dispensing and Insurance Coverage — comprehensive LGBTQ+ and civil rights champion as Judiciary Chair.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Clippinger sponsored HIV Prevention Drugs - Prescribing Dispensing and Insurance Coverage legislation — expanding insurance coverage and access to HIV prevention (PrEP) medication; supports public health access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Clippinger chairs the House Judiciary Committee and sponsored Correctional Services - Incarcerated Individuals - Identification Cards Driver's Licenses and Birth Certificates — providing ID documents at release reduces recidivism; rehabilitative stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$As Judiciary Chair Clippinger leads criminal justice reform legislation including ID access for incarcerated individuals and labor law reform — strongly supports government investment in legal access and equal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Clippinger sponsored Catalytic Revitalization Project Tax Credit and Property Tax Credit for Commercial Buildings Rented to Small Businesses and Labor Law - Child Labor Penalties — supports targeted public investment and worker protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Clippinger as Judiciary Chair shepherds criminal justice bills emphasizing both accountability and rehabilitation — balanced approach supporting incarcerated ID access and progressive criminal procedure reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$As a long-serving Baltimore City Democrat on the Judiciary Committee Clippinger has consistently supported expanded voting access legislation including absentee voting reforms and anti-suppression measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Clippinger sponsored Catalytic Revitalization Tax Credit alterations and Property Tax Credit for small businesses — supports targeted tax incentives for community development and small business support while also supporting progressive tax policy overall.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As a Baltimore City Democrat and Judiciary Chair who has sponsored incarcerated individuals' rights legislation and civil rights bills Clippinger consistently opposes deportation enforcement and supports sanctuary policies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Consistent with his Judiciary Chair role and Baltimore City Democratic profile — Clippinger supports expanded immigration rights and pathways to citizenship and opposes restrictive immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As a Baltimore City Democrat and LGBTQ+ rights champion who has been consistent on reproductive rights — Clippinger supports broad abortion access and opposes restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger', 'https://ballotpedia.org/Luke_Clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Luke Clippinger / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad1aaa25-0ef6-4c88-9d78-d75aec7398c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As a Baltimore City Democrat supporting expanded social programs and infrastructure investment Clippinger supports comprehensive clean energy legislation and climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/clippinger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Eric Ebersole
-- ============================================================

-- ----- Eric Ebersole / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Ebersole sponsored Immigration Enforcement - Expanding Sensitive Locations Notification and Guidance (Maryland Values Act of 2026) and Public Safety - Immigration Enforcement Agreements - Prohibition — strongest possible sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ebersole sponsored two immigration protection bills (Maryland Values Act 2026 and immigration enforcement prohibition) — supports expansive immigration rights and sanctuary protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ebersole sponsored Affordable Solar Act and Maryland Beverage Container Recycling Program — strong support for clean energy transition and environmental programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ebersole sponsored Affordable Solar Act expanding solar renewable energy — favoring phasing out fossil fuel dependence through renewable energy expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ebersole sponsored Corporate Income Tax - Addition Modification - Direct-to-Consumer Pharmaceutical Advertising (closing pharma tax loophole) and Sales and Use Tax/Property Tax Exemptions for Data Centers - Repeal — closing corporate tax breaks.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ebersole sponsored Election Districts - General Assembly and Representatives in Congress and Election Law - Ballot Petition Modernization Act — working on redistricting and election access as a Baltimore County Democrat.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ebersole sponsored Collective Bargaining - Public Employees - Revocation of Certification and Right to Strike and Baltimore County Public Library - Collective Bargaining — supports worker rights and labor standards in economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Ebersole sponsored Education - Artificial Intelligence - Guidelines Professional Development and Collaborative (Artificial Intelligence Ready Schools Act) — supporting AI regulation and safety guidelines in education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ebersole sponsored Adult Prison School Board Model Development Committee — prison education and rehabilitation focus; progressive criminal justice reform stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ebersole sponsored Family Child Care Providers - Reserve Component Members - Substitute Provider and Residential Child Care Programs legislation — supports expanded child care access and standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eric Ebersole / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22610d7f-eaca-4802-b486-0e48544e6e7d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ebersole sponsored Human Trafficking Awareness training for transportation operators and campaign finance - pharmaceutical advertising tax modification — supports expanded healthcare access and pharmaceutical regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mark Edelson
-- ============================================================

-- ----- Mark Edelson / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Edelson sponsored Public Safety - Immigration Enforcement Agreements - Prohibition and Public Safety - State Law Enforcement Agencies - Hiring Restriction (ICE Breaker Act) — two separate immigration enforcement prohibition bills; the strongest possible sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Edelson sponsored both immigration enforcement prohibition AND ICE Breaker Act preventing state agencies from cooperating with ICE — among the strongest pro-immigration stances possible.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Edelson sponsored Transportation - Major Highway Capacity Expansion Projects and Impact Assessments (Transportation and Climate Alignment Act of 2026) — directly limiting highway expansion for climate impact; very strong climate action stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Edelson sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Cost Recovery - Limitations and Climate Alignment Act — supporting fossil fuel cost accountability and clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Edelson sponsored Land Use - Permitting - Development Rights (Maryland Housing Certainty Act) — supports streamlining permitting for housing development; balanced market-rate plus affordability approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Edelson sponsored Police Training - Autism and Dementia (LEAD Act of 2026) — investing in police training for special populations — balanced approach with accountability and de-escalation investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Edelson sponsored Baltimore First Responders Child Care Support and Accessibility Program — government investment in childcare access for first responders; supports expanded childcare programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Edelson sponsored Behavioral Health Rate Methodology Modernization and Health - Newborn Screening Program - Gaucher Disease — supports expanded behavioral health and public health screening programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Edelson sponsored Catalytic Revitalization Project Tax Credit and Maryland Stadium Authority - Carroll Park Soccer Stadium — supports targeted public investment in Baltimore City economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Edelson sponsored Property Tax Credit for Small Businesses and Catalytic Revitalization Tax Credit — targeted tax credits for community development while supporting progressive tax policy overall as a Baltimore City Democrat.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Edelson / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec4b395-bb4b-4740-ac1c-8e89f12608a2',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Edelson sponsored Anti-Nuclear Proliferation Resolution (Back from the Brink Act) — supporting nuclear disarmament consistent with supporting Ukraine and opposing Russian military aggression.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Elizabeth Embry
-- ============================================================

-- ----- Elizabeth Embry / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Embry sponsored Public Utilities - Solar Energy Generating Systems and Solar Renewable Energy Credits (Affordable Solar Act) and Maryland Beverage Container Recycling Refund and Litter Reduction Program — strong clean energy and environmental stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Embry sponsored Affordable Solar Act expanding solar energy — consistent with a position favoring phasing out fossil fuels over a defined timeline by expanding renewable alternatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Embry sponsored Higher Education - Student Financial Assistance for Incarcerated Individuals and Higher Education - Tuition Exemption - Incarcerated Individuals and Parole Commission - Improvements in Transparency and Equity — strongly rehabilitative.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Embry sponsored Civil Actions - Stop Silencing Survivors Act and Child Sexual Abuse Claims - Charitable Immunity Abrogation — strong champion of victim rights and civil protections; supports expanded civil rights enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Embry sponsored Higher Education - Foster Care Recipients and Homeless Youth - Tuition Exemption and Residential Child Care Programs legislation — expanding opportunities for vulnerable youth and improving child care standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Embry sponsored Task Force on Responsible Use of Natural Psychedelic Substances and public health legislation — supports evidence-based health policy including exploration of alternative therapies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Embry sponsored Income Tax - Addition Modifications - Business Stock Gains Fines Penalties and Bonus Depreciation — modifying favorable tax treatment for business — consistent with raising taxes on corporations and closing loopholes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Embry sponsored Consumer Protection - Residential Property Advertisement - Ownership Verification — supports housing transparency but her primary focus is criminal justice and clean energy rather than housing mandates or rent control.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Embry / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03a161cf-1da8-4c34-9c08-d91bbf958987',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Embry sponsored Family and Law Enforcement Protection Act and handgun roster reform — balanced approach investing in community protection while also addressing gun safety; slightly services-oriented.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Diana M. Fennell
-- ============================================================

-- ----- Diana M. Fennell / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Fennell sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Fennell co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her PG County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fennell sponsored Fair Housing and Housing Discrimination - Discriminatory Effect legislation and Civil Actions - Stop Silencing Survivors Act and Public Schools - Ruby Bridges Walk to School Day — strong civil rights champion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Fennell sponsored Custodial Interrogation of Minors - Admissibility of Statements (Exonerated 5 Act) — landmark criminal justice reform protecting juvenile interrogation rights; strongly rehabilitative.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fennell sponsored Public Safety - Law Enforcement - Use of Body-Worn Cameras and Police Training - Autism and Dementia (LEAD Act) — police accountability and training investment; balanced approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fennell sponsored Fair Housing and Housing Discrimination - Regulations Intent and Discriminatory Effect — strengthening anti-discrimination in housing; supports significant fair housing protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Fennell sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Utility Rate Changes (Public Service Company Transparency Act) — promoting utility rate transparency as a step toward clean energy accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Fennell sponsored Election Districts - General Assembly and Representatives in Congress — directly working on redistricting as a PG County Democrat supporting fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Fennell sponsored Human Services - Foster Care Transition Grant Program — supports expanded foster care support and child welfare services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana M. Fennell / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('192e8ffb-e576-41f1-915a-dbc0c30d4769',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fennell sponsored Workers' Compensation - Occupational Disease Presumptions - Hypertension (expanding workers' comp coverage) — supports expanded public health protections for workers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Catherine M. Forbes
-- ============================================================

-- ----- Catherine M. Forbes / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Forbes sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement cooperation with ICE — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Forbes co-sponsored immigration enforcement prohibition — consistent with expansive immigration rights and sanctuary policies for Baltimore County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Forbes sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Cost Recovery - Limitations — restricting fossil fuel utility cost recovery signals support for energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Forbes sponsored Education - School Building Energy Usage - Monthly Report and Maryland Beverage Container Recycling Program — supports climate accountability and environmental programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Forbes sponsored Civil Actions - Stop Silencing Survivors Act and Child Abuse and Neglect - Survivor Reporting Reform Act and State Procurement - Constitutional Violations - Prohibited — supports comprehensive civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Forbes sponsored Qualifying Nonprofit Organizations - Incarcerated Individual Training and Reentry Grant Fund Extension — supports rehabilitation and reentry programming for incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Forbes sponsored Election Districts - General Assembly and Representatives in Congress legislation — directly working on redistricting as a Baltimore County Democrat who supports fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Forbes sponsored Human Services - Foster Care Transition Grant Program and Residential Child Care Programs legislation — supports expanded government programs for vulnerable children and youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Forbes sponsored Income Tax - Decoupling From Federal Changes - Education Expenses (preventing regressive federal tax changes from affecting MD) — supports progressive tax policy protecting educational deductions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Catherine M. Forbes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c017b328-4469-45c4-aa8a-7b9035c77e22',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Forbes sponsored Baltimore County Public Library - Collective Bargaining for library employees — supports worker rights and public service investment as part of economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Michele Guyton
-- ============================================================

-- ----- Michele Guyton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Guyton sponsored Environment - On-Site Wastewater Systems requirements and Beverage Containers Connected With Plastic Rings - Restriction on Sale and Hunting - Lead Ammunition Phase-Out — consistent environmental protection legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Guyton sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Cost Recovery - Limitations legislation restricting fossil fuel utility cost recovery — signals support for transitioning away from fossil fuels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Guyton sponsored Real Property - Landlord and Tenant - Family Child Care Homes and Sale of Residential Real Property - Required Flood Risk Disclosure — supports tenant protections and housing consumer disclosure requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Guyton sponsored Local Government - Regulatory Powers - Regulation of Invasive Trees and Municipalities - Open Drainage Inlets - Inventory and Improvements — strong advocate for local environmental protection measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Guyton sponsored speed monitoring systems and automated traffic enforcement — balanced law enforcement tools focused on traffic safety rather than a primarily social-services or policing approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Guyton sponsored Real Property - Family Child Care Homes protections and Children in Need of Assistance - Permanency Plan Requirements — supports government standards and protections for child care and welfare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Guyton sponsored Criminal Procedure - Protection of Identity of Victim of Sexual Assault (public health/victim safety) and Community Pathways Waiver - Adoption of Regulations — supports public health and disability services access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Guyton sponsored Criminal Procedure - Protection of Identity of Victim of Sexual Assault or Stalking legislation protecting victims' rights — consistent with comprehensive civil rights protections for vulnerable populations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Guyton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb180c23-b965-4bba-a2b9-73febd484d21',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a Baltimore County Democrat supporting expanded environmental regulations and social services Guyton supports raising taxes on high earners and corporations to fund state programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guyton01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Julian Ivey
-- ============================================================

-- ----- Julian Ivey / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Ivey sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ivey co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for his PG County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ivey sponsored Attorney General Actions and Climate Crimes Accountability Fund (Climate Crimes Accountability Act) — holding polluters legally liable for climate crimes; among the strongest climate stances possible.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ivey sponsored Affordable Solar Act expanding solar renewable energy and Electric Companies - Service Outages and Rate Increases - Report on Customer Impact — supporting clean energy transition and utility accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ivey sponsored Fair Housing and Housing Discrimination - Discriminatory Effect and Commission on House of Reformation and Instruction for Colored Children — strong civil rights and racial equity champion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ivey sponsored Custodial Interrogation of Minors - Admissibility of Statements (Exonerated 5 Act) and Occupational Licensing - Criminal History - Predetermination Review Process — strongly rehabilitative; removes barriers for people with criminal records.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ivey sponsored Maryland Violence Intervention and Prevention Program Fund (Community Safety and Intervention Funding Act) and Maryland Use of Force Statute accountability — balanced approach investing in violence prevention and police accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ivey sponsored Land Use - Permitting - Development Rights (Maryland Housing Certainty Act) and Fair Housing - Discriminatory Effect legislation — balanced development with anti-discrimination protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Ivey sponsored State Government - Data-Sharing Agreements and Personal Identifying Information - Prohibition and Reporting (Maryland Data Privacy and Federal Shield Act) — strong data privacy regulation advocating government accountability for personal data.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ivey sponsored Election Districts - General Assembly and Representatives in Congress — directly working on redistricting as a PG County Democrat supporting fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian Ivey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69bf6043-4546-4804-ae04-311cff54a986',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ivey sponsored Institutions of Higher Education - Provision of Menstrual Hygiene Products - Requirement and Civil Actions - Stop Silencing Survivors Act — expanding health and wellness access on campuses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Robbyn Lewis
-- ============================================================

-- ----- Robbyn Lewis / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Lewis sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lewis co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lewis sponsored Landlord and Tenant - Residential Leases - Prospective Tenant Criminal History Records Check (Maryland Fair Chance Housing Act) — banning criminal background check discrimination in housing; strong tenant protection stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lewis sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Cost Recovery - Limitations — restricting fossil fuel utility cost recovery signals support for energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lewis sponsored On-Farm Organics Diversion and Recycling Grant Program and Maryland Beverage Container Recycling Program and Local Government - Invasive Trees Regulation — environmental protection focus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Lewis sponsored Qualifying Nonprofit Organizations - Incarcerated Individual Training and Reentry Grant Fund and Adult Prison School Board Model Development Committee — rehabilitative criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lewis sponsored Employment Discrimination - Reasonable Accommodations - Disabilities Due to Childbirth and Menopause and Criminal Procedure - Protection of Identity of Victim of Sexual Assault — supports civil rights protections for women and vulnerable populations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Lewis sponsored Election Districts - General Assembly and Representatives in Congress and Election Law - Ballot Petition Modernization Act — directly working on redistricting as a Baltimore City Democrat supporting fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lewis sponsored Maryland Medical Assistance Program - Individuals With Intellectual and Developmental Disabilities - Provider Reimbursement and Income Tax Credit for Physician Preceptors in shortage areas — supports Medicaid expansion and healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lewis sponsored Economic Development - Transformational Project Financing Program and Catalytic Revitalization Tax Credit — supports targeted public investment in Baltimore City economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robbyn Lewis / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9285f590-79b5-48de-a1c0-a022629e6ebb',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lewis sponsored Residential Child Care Programs - Education legislation — supports government standards for child care quality in her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Aletheia McCaskill
-- ============================================================

-- ----- Aletheia McCaskill / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$McCaskill sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McCaskill co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her Baltimore County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McCaskill sponsored Attorney General Actions and Climate Crimes Accountability Fund (Climate Crimes Accountability Act) — strongest climate accountability stance possible; holding polluters legally liable for climate crimes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McCaskill sponsored Affordable Solar Act expanding solar energy — favoring phasing out fossil fuels through renewable energy expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McCaskill sponsored Sales and Use Tax and Property Tax - Exemptions for Data Centers - Repeal — closing corporate tax breaks for technology companies; supports raising corporate taxes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$McCaskill sponsored Child Care Scholarship Program - Priority for Child Care Providers and Maryland Child Care Credential Program Extension and Real Property - Family Child Care Homes — comprehensive childcare investment stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McCaskill sponsored Custodial Interrogation of Minors - Admissibility of Statements (Exonerated 5 Act) and Adult Prison School Board Model Development Committee — very progressive criminal justice stance protecting minors and promoting rehabilitation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McCaskill sponsored Commission on the House of Reformation and Instruction for Colored Children (racial history accountability) and Exonerated 5 Act — strong champion of racial equity and civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McCaskill sponsored Hospitals - Clinical Staffing Committees and Plans - Establishment (Safe Staffing Act of 2026) and Maryland Department of Health - Caregiver Resource Webpage — supports expanded healthcare standards and caregiver support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$McCaskill sponsored Community Colleges - Collective Bargaining and Baltimore County Public Library - Collective Bargaining — supports worker rights and public investment as economic development strategies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aletheia McCaskill / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fcfa1844-032e-4dba-9ae0-c52b82447fa8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McCaskill sponsored Baltimore County Board of Education - Alterations of Elected Member Districts and Establishment of Redistricting Process — directly working on redistricting reform to establish independent process.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Samuel I. Rosenberg
-- ============================================================

-- ----- Samuel I. Rosenberg / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rosenberg sponsored Housing Development Projects - Housing Counseling Services legislation and has a career background as Housing Program Coordinator for Baltimore City Department of Housing. He consistently supports affordable housing programs and tenant protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg', 'https://ballotpedia.org/Samuel_Rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Rosenberg sponsored Criminal Procedure - Immigration Arrest - Immunity in Connection With Court Proceeding legislation providing immunity for immigrants in court proceedings — a strong sanctuary-oriented stance opposing cooperation with immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Consistent with his immigration arrest immunity bill and 40-year record as a Baltimore City Democrat representing a diverse urban district — Rosenberg supports expanded immigration rights and pathways.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rosenberg sponsored Department of the Environment - Federal Environmental Policy - Reporting legislation — requiring state tracking of federal environmental policy — indicating support for environmental oversight and climate accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rosenberg sponsored Election Law - Absentee Ballots - Notice of Timely Receipt legislation expanding absentee ballot access and voter notification — a strong voting access stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rosenberg sponsored Public Health - Patient Access to Medication and Maryland Medical Assistance Program funding legislation — supporting expanded public health access and Medicaid-funded care.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Rosenberg sponsored Maryland Medical Assistance Program (Medicaid) and Maryland Children's Health Program transfers legislation — consistent support for Medicaid expansion and public health insurance programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Rosenberg sponsored Criminal Law - Controlled Dangerous Substances and Criminal Organizations and Criminal Procedure - Victim Notification legislation balancing rehabilitation with accountability — broadly progressive on criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Rosenberg's background directing the Homeless Persons Representations Project and his legislative record on criminal procedure$$,
        ARRAY['mental health', 'and housing reflect a services-first public safety approach.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rosenberg sponsored Maryland Justice Corps Program establishment and has a career history running a legal aid program for homeless persons — strong champion of civil rights and legal access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Rosenberg sponsored Algorithmic Addiction Fund establishment legislation — targeting harms from algorithmic social media on youth — indicating support for technology regulation and AI/platform accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Rosenberg's career includes directing the Homeless Persons Representations Project (housing-first legal aid organization) — structural view of homelessness as requiring legal and housing support services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg', 'https://ballotpedia.org/Samuel_Rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Rosenberg sponsored Criminal Law - Obstruction or Interference With Exercise of Religious Beliefs - Prohibition legislation protecting religious exercise from interference — supports baseline religious freedom protections while not endorsing discriminatory exemptions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$As a Baltimore City Democrat consistently supporting expanded social services and public programs across his 40-year legislative career Rosenberg supports childcare subsidies and pre-K investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Consistent with his progressive Baltimore City Democrat profile and support for expanded public programs including housing healthcare and legal aid — Rosenberg supports higher taxes on high earners to fund social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Rosenberg sponsored environment-focused legislation requiring state tracking of federal environmental policy — consistent with a position favoring phasing out fossil fuels over time.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As a Democrat from Baltimore City who has consistently championed public services and legal aid programs throughout his 40-year career Rosenberg opposes school vouchers and supports fully funding public schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Rosenberg sponsored Charitable Organizations - Charitable Donation and Tax-Exempt Status - Revocation (Keeping Charities Nonpartisan Act of 2026) — legislation restricting partisan use of charitable organizations reflects support for campaign finance integrity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samuel I. Rosenberg / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36eecaff-4677-441a-b36e-a323e87d9158',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a 40-year Baltimore City Democrat serving in a diverse urban district — Rosenberg has consistently supported independent redistricting and fair maps in line with Maryland Democratic legislative positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Malcolm P. Ruff
-- ============================================================

-- ----- Malcolm P. Ruff / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ruff sponsored Reparations - Board Fund and Excise Tax on Endowments - Establishment legislation — among the most progressive civil rights stances possible reflecting strong support for racial equity remedies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ruff sponsored Criminal Procedure - Expungement of Records - Good Cause and Qualifying Nonprofit Organizations - Incarcerated Individual Training and Reentry Grant Fund — strongly rehabilitative criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Ruff sponsored Public Safety - Immigration Enforcement Agreements - Prohibition legislation — directly prohibiting local law enforcement from entering ICE cooperation agreements — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ruff sponsored legislation prohibiting immigration enforcement agreements by local agencies — consistent with expansive immigration rights and sanctuary policies for his Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ruff sponsored Public Safety - Law Enforcement Officers - Restrictions (limiting officer conduct) and Correctional Services - Comprehensive Rehabilitative Prerelease Services — services-first approach to public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ruff sponsored Maryland Medical Assistance Program (Medicaid) — Provider Reimbursement for individuals with intellectual/developmental disabilities — supports public health program funding and expanded Medicaid access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Ruff sponsored Maryland Medical Assistance Program reimbursement legislation for disabled individuals — consistent support for Medicaid expansion and public insurance programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ruff sponsored Investor-Owned Electric Gas and Gas and Electric Companies - Cost Recovery - Limitations legislation restricting utility cost pass-through — favors phasing out fossil fuel infrastructure costs borne by consumers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ruff sponsored Catalytic Revitalization Project Tax Credit and Income Tax - Credit for At-Risk Youth Employment Initiatives — supports targeted public investment and job creation programs in underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ruff sponsored Residential Child Care Programs - Education of Children and Training legislation improving child care quality — supports government investment in child welfare and care programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ruff sponsored utility cost recovery limitation legislation for electric and gas companies — restricting fossil fuel utility cost recovery aligns with transition-supporting climate stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm P. Ruff / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ruff sponsored income tax credit for at-risk youth employment and excise tax on endowments for reparations fund — supports targeted tax policy to fund social programs and racial equity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sheila Ruth
-- ============================================================

-- ----- Sheila Ruth / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ruth sponsored Attorney General Actions and Climate Crimes Accountability Fund (Climate Crimes Accountability Act) and PFAS Chemicals - Product Phase Outs — comprehensive climate accountability legislation; among the strongest climate stances.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ruth sponsored Public Health - Universal Health Care Program - Study and Commission — studying universal/single-payer healthcare; the most progressive possible healthcare stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Ruth sponsored Election Law - Election Misinformation Election Disinformation and Deepfakes legislation — strongly supports government action against political misinformation and AI-generated deepfakes in elections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ruth sponsored State Transfer Tax - Rate - Alterations (Housing Affordability for Buyers and Sellers) and Residential Rental Apartments - Air-Conditioning Requirement — supports tenant protections and housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ruth sponsored Motor Vehicles - Driver's Licenses - Eligibility (likely extending licenses to undocumented immigrants) and Correctional Services - Identification Cards for incarcerated individuals — supports expanded rights and identification access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ruth sponsored State Government - Henrietta Lacks Commission - Establishment and Commission on State and Local Government Real Property Bearing Confederate Names — strong champion of racial equity and civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ruth sponsored Police Pursuits of Fleeing Suspects - Standards (Dimeka Thornton Act) — police accountability reform focused on limiting dangerous pursuits; services-oriented with targeted policing accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ruth sponsored Election Law - Affiliating With a Party and Voting - Unaffiliated Voters (expanding voting access for independents) and Ballot Petition Modernization Act — strong voting access expansion stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ruth sponsored State Personnel - Collective Bargaining - Nontenure Track Faculty and Property Taxes - Authority of Counties to Set Special Rate for Commercial and Industrial Property — supports worker rights and targeted economic regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ruth sponsored Income Tax - Individual Itemized Deductions Alterations and Property Tax Credits for renters and homeowners — supports progressive tax policy protecting lower-income households.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheila Ruth / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ruth sponsored PFAS Chemicals phase-outs and Climate Crimes Accountability Act — strongly opposed to harmful industrial pollutants; consistent with opposing new fossil fuel infrastructure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stephanie Smith
-- ============================================================

-- ----- Stephanie Smith / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Smith sponsored Maryland Voting Rights Act of 2026 - Voter Intimidation and Suppression — among the strongest voting rights stances possible; directly combating voter suppression.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Smith sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Smith co-sponsored immigration enforcement prohibition legislation — consistent with expansive immigration rights and sanctuary policies for her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Smith sponsored Criminal Procedure - Sentencing - Domestic Violence as Mitigating Factor (PATH Act) and Criminal Law - Drug Paraphernalia Repeal and Criminal Law - Self-Defense Prior Acts by Victim — comprehensive criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Smith sponsored Employment Discrimination - Reasonable Accommodations - Disabilities Due to Childbirth and Menopause and Civil Actions - Stop Silencing Survivors Act and Commission on House of Reformation — strong civil rights champion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Smith sponsored Higher Education Institutions - Over-the-Counter Contraception - Access and Reporting and Physicians - Licensing - Internationally Trained Physicians — expanding healthcare access and contraceptive availability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Smith sponsored Landlord and Tenant - Residential Leases and Holdover Tenancies - Local Good Cause Termination (Good Cause Eviction) — strong tenant protection stance limiting evictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Smith sponsored Child Placement Services and Human Services - Foster Care Transition Grant Program and Children's Cabinet Fund — supports expanded child welfare services and foster care investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Smith sponsored Department of Social and Economic Mobility - Workforce Opportunities Grant Program and Community Eligibility Provision Expansion (school meals) — supports targeted public investment and workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Smith sponsored Election Districts - General Assembly and Representatives in Congress — directly working on redistricting as a Baltimore City Democrat supporting fair maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Smith sponsored Higher Education Institutions - Over-the-Counter Contraception - Access and Reporting — expanding contraceptive access in colleges; consistent with strong support for reproductive rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Smith / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('848ac881-004b-436a-9a17-dfacbd33de5a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a Baltimore City Democrat supporting expanded social programs education equity and workforce development Smith supports higher taxes on high earners and corporations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sean A. Stinnett
-- ============================================================

-- ----- Sean A. Stinnett / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Stinnett sponsored Voting Rights Act of 2026 - Counties and Municipal Corporations legislation — one of the strongest possible voting rights stances demonstrating commitment to expanded ballot access at local levels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Stinnett sponsored Criminal Procedure - Motion to Reduce Duration of Sentence - Repeal of Sentencing Date Limitation and Criminal Procedure - Expungement - Conviction of Drug Distribution — strongly rehabilitative criminal justice record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Stinnett sponsored Public Safety - Law Enforcement - Use of Body-Worn Cameras (police accountability) and school-based mental health services — balanced approach investing in both oversight and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Stinnett sponsored voting rights legislation and expungement reform — supports comprehensive civil rights but record is more focused on criminal justice reform than broader anti-discrimination enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Stinnett sponsored Public Schools - School-Based Mental Health Services - Full-Time Therapist legislation — expanding mental health services access as part of public health infrastructure in Baltimore City schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Stinnett sponsored Sale of Residential Real Property - Required Flood Risk Disclosure legislation — expanding consumer protections in housing transactions; consistent with urban Baltimore City Democrat on housing policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Stinnett sponsored Child Care - Child Abuse and Neglect - Training Requirements and Residential Child Care Programs - Education legislation — supports government standards for child welfare and care quality.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stinnett sponsored Sale of Residential Real Property - Required Flood Risk Disclosure — acknowledging climate-driven flood risks in housing; consistent with a Democrat supporting climate adaptation measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Stinnett sponsored Small Business Reserve Program - Veteran-Owned Small Business Enterprises - Outreach and education funding task force — supports targeted public investment and small business support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean A. Stinnett / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a Baltimore City Democrat serving a low-income urban district Stinnett supports higher taxes on wealthy individuals and corporations to fund expanded social services and education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joshua J. Stonko
-- ============================================================

-- ----- Joshua J. Stonko / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stonko sponsored Environment - Building Energy Performance Standards - Repeal legislation and Electric Companies - Environmental Surcharges or Fees - Prohibition on Collection — actively opposing climate mandates and green energy fees.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Stonko sponsored Retail Supply of Electricity and Gas (Energy Savings Act of 2026) and Maryland Co-Location Energy Innovation and Reliability Act — supports continued fossil fuel and gas use alongside emerging energy sources.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Stonko sponsored Corporate Income Tax - Rate Reduction (Economic Competitiveness Act of 2026) — directly advocating for corporate tax cuts; strong conservative tax reduction stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Stonko sponsored Maryland Public Charter School Program - School Facilities - Funding legislation — supports charter school expansion and alternative school funding as a Carroll County Republican.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Stonko sponsored Office of Regulatory Management and State Government Authorizations (regulatory reduction) and Economic Competitiveness Act — strongly favors deregulation and reducing government burden on business.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Stonko sponsored Family Law - Guardianship Assistance Program and Children in Unlicensed Settings - Placement legislation — supports child welfare policy but through existing program reforms rather than expanded government subsidies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$As a Carroll County Republican opposing environmental mandates and supporting deregulation Stonko favors market-based healthcare approaches over government expansion of public programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua J. Stonko / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a Carroll County Republican serving in a partisan-drawn district Stonko supports legislature-controlled redistricting consistent with Maryland Republican positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Deni Taveras
-- ============================================================

-- ----- Deni Taveras / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Taveras sponsored Voting Rights Act of 2026 - Counties and Municipal Corporations — among the strongest possible voting rights stances demonstrating commitment to expanded local ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Taveras sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Taveras co-sponsored immigration enforcement prohibition — consistent with expansive immigration rights and sanctuary policies for her PG County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Taveras sponsored Net Energy Metering - Portable Solar Electric Generating Facilities and Affordable Solar Act and Condominiums - Electric Vehicle Recharging Equipment — consistent support for clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Taveras sponsored Net Energy Metering Solar legislation and Affordable Solar Act and EV charging infrastructure — actively expanding renewable alternatives to fossil fuels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Taveras sponsored Health Insurance - Bulk Purchasing Pools for Prescription Drugs and Pharmaceutical Drugs and Devices - Gifts to Health Care Professionals - Prohibition and Health Insurance - Specialty Drugs Coverage — comprehensive healthcare cost reduction and access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Taveras sponsored Maryland Medical Assistance Program - Coverage for Orthoses and Prostheses (So Every Body Can Move Act) — expanding Medicaid coverage for prosthetics and mobility devices.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Taveras sponsored Landlord and Tenant - Investor-Owned Single-Family Rental Property - Landlord Requirements and Fair Housing and Housing Discrimination - Discriminatory Effect legislation — strong tenant and fair housing protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Taveras sponsored Fair Housing and Housing Discrimination - Discriminatory Effect and Maryland Commission on Women's Health Advancement and Criminal Procedure - Protection of Identity of Victim of Sexual Assault — supports civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Taveras sponsored Residential Child Care Programs - Education and Child Support - Capacity of Minors — supports expanded child welfare standards and child support access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Taveras sponsored Adult Prison School Board Model Development Committee — prison education/rehabilitation focus; progressive criminal justice reform stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deni Taveras / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a92085b6-642a-4cf6-a73e-c985a6fd09fa',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a PG County Democrat supporting bulk pharmaceutical purchasing healthcare expansion and clean energy programs Taveras supports higher taxes on corporations and high earners to fund public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Vacant
-- ============================================================

-- NOTE: No stances found in CSV for Vacant (67acad60-5839-4a8a-95ac-c881c3ca39a9)

-- ============================================================
-- Caylin Young
-- ============================================================

-- ----- Caylin Young / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Young sponsored Voting Rights Act of 2026 - Counties and Municipal Corporations — among the strongest possible voting rights stances demonstrating commitment to expanded local ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Young sponsored Public Safety - Immigration Enforcement Agreements - Prohibition — directly prohibiting local law enforcement from ICE cooperation — strong sanctuary stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Young co-sponsored immigration enforcement prohibition and Maryland-Africa and the Caribbean Investment and Development Program — consistent with expansive immigration rights and welcoming policies for her Baltimore City district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Young sponsored Income Tax - Credit for Small Political Contributions — directly incentivizing small-dollar political participation; classic campaign finance reform stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Young sponsored Comprehensive Community Safety Funding Act — investing in community-based safety approaches — balanced stance supporting both community investment and law enforcement tools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Young sponsored Adult Prison School Board Model Development Committee (prison education) — progressive rehabilitation stance for incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Young sponsored Courts - Jury Service - Disqualification (expanding jury eligibility) and adult prison education — supports civil rights reforms in the criminal justice system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Young sponsored Maryland Medical Assistance Program - Coverage for Orthoses and Prostheses (So Every Body Can Move Act) — expanding Medicaid coverage for prosthetics and mobility devices.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Young sponsored Maryland Medical Assistance Program - Coverage for Orthoses and Prostheses — expanding Medicaid coverage; supports broadening public health insurance access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Young sponsored Family Child Care Providers - Reserve Component Members - Substitute Provider and Residential Child Care Programs — supports expanded child care access and standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Caylin Young / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92075c9b-6c7e-4763-981f-5a42a8afddf5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Young sponsored Maryland-Africa and the Caribbean Investment and Development Program and Property Tax Credit - Urban Agricultural Property — supports targeted public investment in community economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Per-candidate row count (every candidate must have >= 10 topics):
-- SELECT p.full_name, COUNT(pa.topic_id) AS topic_count
-- FROM essentials.politicians p
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE p.id IN ('36eecaff-4677-441a-b36e-a323e87d9158', '7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4', '012af8f7-693a-4ddc-b0bc-953dae8d2bc2', '67acad60-5839-4a8a-95ac-c881c3ca39a9', 'bb180c23-b965-4bba-a2b9-73febd484d21', '656a8bc9-348e-4ffc-819c-2f4611b3ddc8', '027a2610-1160-4525-a5c1-469fe85d46e1', '03a161cf-1da8-4c34-9c08-d91bbf958987', 'c017b328-4469-45c4-aa8a-7b9035c77e22', '22610d7f-eaca-4802-b486-0e48544e6e7d', 'fcfa1844-032e-4dba-9ae0-c52b82447fa8', 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e', '01aaf4ba-c8ec-4a50-bd56-8d181d35e903', '848ac881-004b-436a-9a17-dfacbd33de5a', '92075c9b-6c7e-4763-981f-5a42a8afddf5', 'ad1aaa25-0ef6-4c88-9d78-d75aec7398c7', 'bec4b395-bb4b-4740-ac1c-8e89f12608a2', '9285f590-79b5-48de-a1c0-a022629e6ebb', '192e8ffb-e576-41f1-915a-dbc0c30d4769', '69bf6043-4546-4804-ae04-311cff54a986', 'a92085b6-642a-4cf6-a73e-c985a6fd09fa')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('36eecaff-4677-441a-b36e-a323e87d9158', '7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4', '012af8f7-693a-4ddc-b0bc-953dae8d2bc2', '67acad60-5839-4a8a-95ac-c881c3ca39a9', 'bb180c23-b965-4bba-a2b9-73febd484d21', '656a8bc9-348e-4ffc-819c-2f4611b3ddc8', '027a2610-1160-4525-a5c1-469fe85d46e1', '03a161cf-1da8-4c34-9c08-d91bbf958987', 'c017b328-4469-45c4-aa8a-7b9035c77e22', '22610d7f-eaca-4802-b486-0e48544e6e7d', 'fcfa1844-032e-4dba-9ae0-c52b82447fa8', 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e', '01aaf4ba-c8ec-4a50-bd56-8d181d35e903', '848ac881-004b-436a-9a17-dfacbd33de5a', '92075c9b-6c7e-4763-981f-5a42a8afddf5', 'ad1aaa25-0ef6-4c88-9d78-d75aec7398c7', 'bec4b395-bb4b-4740-ac1c-8e89f12608a2', '9285f590-79b5-48de-a1c0-a022629e6ebb', '192e8ffb-e576-41f1-915a-dbc0c30d4769', '69bf6043-4546-4804-ae04-311cff54a986', 'a92085b6-642a-4cf6-a73e-c985a6fd09fa')
--   AND pc.politician_id IS NULL;