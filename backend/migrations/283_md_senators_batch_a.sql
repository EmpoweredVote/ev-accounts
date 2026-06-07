-- ============================================================================
-- Migration 283: MD Senators Batch A — Districts 1-15
-- ============================================================================
-- Purpose: Insert/upsert stance data for 15 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~177 rows expected
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
-- Benjamin Brooks
-- ============================================================

-- ----- Benjamin Brooks / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Brooks voted NO on SB 798 in 2023$$,
        ARRAY['joining all 13 Republicans and only one other Democrat in opposing Maryland''s reproductive freedom constitutional amendment — a significant departure from most Maryland Democrats.', 'https://fastdemocracy.com/bill-search/md/2023/bills/MDB00027927/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Brooks championed coal plant phase-out legislation in 2020 and worked with AES Corporation to end coal operations at Warrior Run by 2030. He sponsors the Maryland Native Plants Program and supports clean energy transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Brooks introduced legislation creating timelines for Maryland power plants to phase out coal and a transition fund for affected workers. He negotiated a concrete agreement to end coal operations at Warrior Run Generating Station.$$,
        ARRAY['https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Brooks signed a 2015 letter urging Governor Hogan to welcome Syrian refugees into Maryland$$,
        ARRAY['opposing Hogan''s restrictionist position. He voted for the Community Trust Act in 2026 limiting ICE cooperation.', 'https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)', 'https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Brooks introduced the Building Affordably in My Backyard Act in 2026$$,
        ARRAY['creating expedited approval processes for residential development in jurisdictions with documented affordable housing shortages.', 'https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$The Building Affordably in My Backyard Act that Brooks introduced in 2026 targets zoning barriers by expediting approvals in housing-shortage areas$$,
        ARRAY['indicating support for zoning reform to increase supply.', 'https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Brooks opposed Maryland's 2026 mid-decade congressional redistricting$$,
        ARRAY['arguing it would be unrepresentative to eliminate Maryland''s sole Republican congressional district. He avoided a definitive stance on whether it should receive a Senate vote.', 'https://www.thebanner.com/politics-power/state-government/maryland-redistricting-senators-senate-ferguson-HL75HWXXH5ENXKJLO4CRCMIPT4/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Brooks / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a16b94b0-dd22-40a9-af91-03295ea27986',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Brooks participated in a Fraternal Order of Police training exercise in 2020 and stated the experience gave perspective but "did not change his mind on policing reforms$$,
        ARRAY['indicating support for reform while acknowledging law enforcement complexity.,https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician),,
Benjamin Brooks,local-environment,2,Brooks sponsored the Maryland Native Plants Program (signed into law 2023) and chairs the Joint Electric Universal Workgroup Service Program focused on expanding community solar access for low-income residents.,https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician),,
Benjamin Brooks,economic-development,2,Brooks sponsored community solar expansion legislation (SB613, 2023) and property tax incentives for grocery stores in food deserts, prioritizing economic equity and access in underserved communities.,https://www.benbrooksforsenate.com/about,,']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Paul D. Corderman
-- ============================================================

-- ----- Paul D. Corderman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Corderman called the 2026 budget deal "budget sorcery" and proposed a 5% across-the-board spending cut of ~$530 million; he criticized the final package as "$1.6 billion in taxes and fee increases for Marylanders."$$,
        ARRAY['https://marylandmatters.org/2026/03/17/senate-gives-preliminary-approval-to-70-8-billion-spending-plan/', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Corderman opposed the Community Trust Act limiting ICE cooperation saying it was "absolutely absurd" that local law enforcement couldn't collaborate with federal partners even in murder cases.$$,
        ARRAY['https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Corderman introduced an amendment to allow gas utilities to share extension costs broadly and argued against barriers to new gas infrastructure saying it stifled housing development and energy choice.$$,
        ARRAY['https://marylandmatters.org/2026/04/03/senate-house-diverging-energy-bill-gas-lines/', 'https://en.wikipedia.org/wiki/Paul_D._Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Corderman opposed a PILOT agreement for Bethel Gardens low-income housing and opposed the Noland Village redevelopment; his housing stance centers on gas-infrastructure-enabled market development.$$,
        ARRAY['https://en.wikipedia.org/wiki/Paul_D._Corderman', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Corderman has supported the BOOST scholarship program providing private school vouchers and criticized budget cuts to the initiative.$$,
        ARRAY['https://en.wikipedia.org/wiki/Paul_D._Corderman', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Corderman signed a letter calling to cancel police reform hearings citing officer morale concerns and characterized Hagerstown as "in crisis and under siege" under city leadership on safety issues.$$,
        ARRAY['https://en.wikipedia.org/wiki/Paul_D._Corderman', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Corderman opposed a 24-hour addiction crisis center downtown and voted against drug violation decriminalization bills$$,
        ARRAY['while sponsoring legislation increasing Medicaid reimbursements for EMS.', 'https://en.wikipedia.org/wiki/Paul_D._Corderman', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Corderman introduced the Suzanne Jones Act requiring prisoners to be released to their home communities$$,
        ARRAY['and signed a letter opposing early COVID prisoner releases.', 'https://en.wikipedia.org/wiki/Paul_D._Corderman', 'https://ballotpedia.org/Paul_Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul D. Corderman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5127f8d8-ca40-40aa-8773-4c1abad66f41',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Corderman championed natural gas and nuclear energy for economic growth and sponsored sales tax exemptions for redevelopment target areas in Washington County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/corderman02', 'https://en.wikipedia.org/wiki/Paul_D._Corderman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brian J. Feldman
-- ============================================================

-- ----- Brian J. Feldman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Feldman passed a 2023 bill requiring four-year public universities to provide students access to emergency contraception and abortion services$$,
        ARRAY['and supported birth control access legislation (SB527 2024). He consistently supports reproductive rights access legislation.', 'https://en.wikipedia.org/wiki/Brian_Feldman_(politician)', 'https://ballotpedia.org/Brian_Feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Feldman sponsored the Protect Maryland Health Care Act (2018) reinstating the individual mandate$$,
        ARRAY['established a Prescription Drug Affordability Board with price-setting power (2019)', 'banned medical debt wage garnishment and home liens (2021)', 'and created a $1/month health insurance pilot program for young adults.']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Feldman's healthcare work has focused on private insurance affordability and drug pricing rather than direct Medicaid expansion$$,
        ARRAY['though his 2019 Prescription Drug Affordability Board legislation affects Medicaid drug costs as well.', 'https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Feldman chairs the Education Energy and Environment Committee and sponsored the Clean Energy Jobs Act (2019) requiring 50% renewable power by 2030. He supported the POWER Act (2023) targeting 8.5 GW offshore wind by 2031 and opposed Governor Hogan's vehicle emissions rollback.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Feldman_(politician)', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Feldman's sponsorship of the Clean Energy Jobs Act (50% renewable by 2030) and support for 8.5 GW offshore wind development by 2031 reflects strong commitment to transitioning away from fossil fuels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$As Chair of the Education Energy and Environment Committee since 2023$$,
        ARRAY['Feldman has jurisdiction over state environmental legislation and sponsored the Renewable Energy Certainty Act (SB0931 2025) streamlining siting for clean energy generating stations.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS', 'https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Feldman signed a June 2025 state policymaker coalition letter opposing federal AI preemption in the reconciliation bill — specifically opposing the proposed 10-year freeze on state and local regulation of AI and automated decision systems.$$,
        ARRAY['https://ari.us/wp-content/uploads/2025/06/State-Policymaker-Coalition-Letter-Oppose-AI-Preemption-6-3-25.pdf', 'https://ballotpedia.org/Brian_Feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Feldman supported gender-affirming care protections (voted for SB119 expanding legally protected healthcare to include gender-affirming treatments 2024) and sponsored the County Board Member Antibias Training Act (SB0293 2025) requiring antibias training for school board members.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS', 'https://ballotpedia.org/Brian_Feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Feldman sponsored short-term rental taxation legislation (SB0132 2025) and the Income Tax Benefit Transfer Program for economic development (SB0091 2025). His approach is fiscally pragmatic — using tax policy to achieve specific economic and social goals rather than ideological tax reduction.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Feldman sponsored the Income Tax Benefit Transfer Program (SB0091 2025) and the Better Small Business Employee Benefit Act (SB0760 2025). His Cybersecurity Council work also supports tech sector development in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Feldman sponsored the Public Ethics - Conflicts of Interest and Blind Trust - Governor bill (SB0723 2025) and Maryland Public Ethics Law compliance bill (SB0109 2025)$$,
        ARRAY['showing interest in government transparency and ethics enforcement.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Feldman's legislative record does not show primary criminal justice focus$$,
        ARRAY['though he supported gun buyback destruction requirements (voted for SB444 2025) and has addressed public safety through broader ethics and governance reforms.', 'https://ballotpedia.org/Brian_Feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Feldman supported the Property Tax - Day Care Centers co-sponsorship and has prioritized child-focused legislation including school board antibias training. His primary focus in this space is through education and healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Feldman's 2021 medical debt legislation banning wage garnishment and home liens for medical debt provides indirect homelessness prevention by protecting housing stability for low-income patients.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Feldman's medical debt legislation (2021) prevented home liens for medical debt$$,
        ARRAY['protecting homeowners from losing housing due to medical bills. His direct housing legislation record is limited beyond this protective measure.', 'https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Feldman has consistently voted with the Democratic caucus on LGBTQ+ rights and supported the expansion of legally protected healthcare to include gender-affirming treatments (SB119 2024).$$,
        ARRAY['https://ballotpedia.org/Brian_Feldman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian J. Feldman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d423151e-8477-470d-8f73-ba7d2092f714',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Feldman chaired the Education Energy and Environment Committee that heard the Maryland Voting Rights Act of 2026 (SB255)$$,
        ARRAY['which passed April 28 2026 banning vote dilution in local elections. His committee role and consistent Democratic caucus alignment reflect strong support for voting rights protections.', 'https://www.americandemocracyminute.org/wethepeople/2026/05/06/maryland-passed-its-state-voting-rights-act-24-hours-before-the-scotus-callais-decision-will-state-vras-replace-the-federal-protections', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- William G. Folden
-- ============================================================

-- ----- William G. Folden / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Folden voted against banning 287(g) ICE agreements and defended the program; he introduced an amendment to expand ICE holds to those who served 5+ years in other states and argued states cannot restrict federal immigration enforcement.$$,
        ARRAY['https://www.wypr.org/wypr-news/2026-01-29/maryland-senate-gives-initial-approval-to-two-ice-restriction-bills', 'https://en.wikipedia.org/wiki/William_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Folden is an endorsed law enforcement officer and has a 30-year career in law enforcement; he opposed police mask-wearing restrictions and consistently advocates for law enforcement interests.$$,
        ARRAY['https://senatorfolden.com/', 'https://en.wikipedia.org/wiki/William_Folden', 'https://ballotpedia.org/William_%22Bill%22_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Folden was the only Republican committee member to vote against reducing automatic adult charging for youth offenders; he introduced an amendment to require first-degree assault youth to be tried as adults.$$,
        ARRAY['https://en.wikipedia.org/wiki/William_Folden', 'https://ballotpedia.org/William_%22Bill%22_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Folden supported legislation in 2025 to repeal Maryland's statewide fracking ban.$$,
        ARRAY['https://en.wikipedia.org/wiki/William_Folden', 'https://ballotpedia.org/William_%22Bill%22_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As a delegate in 2017 Folden introduced a bill providing state funding and relaxing restrictions on charter schools — consistent with school-choice orientation.$$,
        ARRAY['https://en.wikipedia.org/wiki/William_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Folden opposed mid-decade redistricting designed to help Democrats flip Maryland's sole Republican congressional district.$$,
        ARRAY['https://en.wikipedia.org/wiki/William_Folden', 'https://ballotpedia.org/William_%22Bill%22_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William G. Folden / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a5241b7-8737-4a58-adf2-c5335111d3c4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Folden campaigns on "fiscal responsibility" and small-business job creation; as a Republican on the Judicial Proceedings Committee he has consistently opposed tax-and-spend Democratic proposals.$$,
        ARRAY['https://senatorfolden.com/', 'https://ballotpedia.org/William_%22Bill%22_Folden']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Guy Guzzone
-- ============================================================

-- ----- Guy Guzzone / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Guzzone sponsored the Public Health Abortion Grant Program - Establishment (SB0848 2025) which was signed into law. He consistently supported abortion access legislation throughout his tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone?ys=2025RS', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Guzzone supported a single-payer healthcare system in Maryland (2011)$$,
        ARRAY['championed the Keep the Door Open Act increasing funding for behavioral health clinics', 'and chairs the Health and Human Services budget subcommittee.', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Guzzone was named Maryland League of Conservation Voters Legislator of the Year in 2025. He established the Forest Conservation Task Force (2019) and Clean Water Commerce Fund (2021)$$,
        ARRAY['and has a long record with the Sierra Club.', 'https://ballotpedia.org/Guy_Guzzone', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$As a former State Director of the Sierra Club and former Chesapeake Bay Trust board member$$,
        ARRAY['Guzzone introduced forest conservation legislation (2019) and the Clean Water Commerce Fund (2021). He preferred a plastic bag ban over mere taxation.', 'https://en.wikipedia.org/wiki/Guy_Guzzone', 'https://guyguzzone.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Guzzone voted for transgender/non-binary anti-discrimination protections in 2011 and campaigned against repealing same-sex marriage in 2012$$,
        ARRAY['demonstrating consistent support for LGBTQ+ civil rights.', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Guzzone actively campaigned against repealing same-sex marriage in Maryland (2012)$$,
        ARRAY['demonstrating strong and early commitment to marriage equality.', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Budget and Taxation Committee Chair$$,
        ARRAY['Guzzone has balanced fiscal responsibility with progressive priorities. He supported fuel tax indexing to inflation for infrastructure and online advertising taxes. He sponsored an Earned Income Tax Credit expansion (SB0668 2025) for lower-income workers.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone?ys=2025RS', 'https://en.wikipedia.org/wiki/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Guzzone sponsored the Community Eligibility Provision Expansion Program (SB0769 2025) expanding free school meals to more low-income children$$,
        ARRAY['and sponsored Community Action Agencies funding (SB0666 2025) for anti-poverty services.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Guzzone worked on legislation allowing sensitive locations like churches and schools to set their own immigration enforcement policies$$,
        ARRAY['including privacy protections for migrant data.', 'https://ballotpedia.org/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Guzzone co-sponsored legislation removing certain homes from tax sale when taxes consist only of unpaid water and sewer service liens$$,
        ARRAY['providing targeted tenant protection. His record is less focused on broad housing reform than other progressive Democrats.', 'https://ballotpedia.org/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Guzzone supported criminal records expungement legislation allowing individuals to petition courts for eligibility reviews. His overall record on criminal justice reform is moderate and focused on reentry rather than structural reform.$$,
        ARRAY['https://ballotpedia.org/Guy_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Guzzone advocates responsible zoning for business growth and technology transfer$$,
        ARRAY['prioritizes balanced budgets', 'and has focused on workforce development. His approach balances fiscal responsibility with supporting community economic growth.', 'https://guyguzzone.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Guzzone supports responsible zoning practices for innovative business growth and technology transfer while also promoting environmental protection and land preservation — a balanced growth stance.$$,
        ARRAY['https://guyguzzone.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Guzzone sponsored funding for Maryland Community Action Agencies (SB0666 2025) which provide homelessness prevention and anti-poverty services$$,
        ARRAY['and chairs the Health and Human Services budget subcommittee overseeing these funding streams.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Guy Guzzone / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0fafa0e-3dd9-4d50-bc5e-c96315f766d7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Guzzone has sponsored legislation protecting citizens against sex offenders and strengthening domestic violence laws$$,
        ARRAY['combined with criminal justice reform support', 'indicating a balanced public safety approach.', 'https://guyguzzone.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Katie Fry Hester
-- ============================================================

-- ----- Katie Fry Hester / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hester voted YES on SB 798 in 2023 to place a reproductive freedom amendment on the Maryland ballot. She has stated that "abortion should be rare$$,
        ARRAY['safe and legal" and voted to expand healthcare worker training for reproductive care.', 'https://fastdemocracy.com/bill-search/md/2023/bills/MDB00027927/', 'https://www.katiefryhester.com/issues/reproductive-rights/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hester is Chair of the Energy Subcommittee and has campaigned on "socially and environmentally responsible" job growth. She secured $8.25 million for Ellicott City flood mitigation and advocates clean energy balanced with economic growth.$$,
        ARRAY['https://en.wikipedia.org/wiki/Katie_Fry_Hester', 'https://www.katiefryhester.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$As an environmental engineer by training Hester has championed flood prevention revolving loan funds and supported the 2019 plastic foam container ban while advocating for farmer transition assistance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hester is the Senate sponsor of the Small Business and Nonprofit Health Insurance Subsidies Program$$,
        ARRAY['stating health insurance access "is more important than ever." She also secured Medicaid investment in student mental health services.', 'https://www.katiefryhester.com/', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Hester introduced 2026 bills to ban election-related deepfakes$$,
        ARRAY['criminalize deepfake impersonation causing serious harm', 'and restrict minors from unsafe AI chatbots. Her deepfake election bill passed the Senate unanimously.', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Hester sponsored legislation creating civil and criminal penalties for using AI to spread election misinformation including deepfakes$$,
        ARRAY['which passed unanimously — one of her signature 2026 priorities.', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hester advocates for independent redistricting commissions to draw congressional and legislative districts$$,
        ARRAY['a reform-oriented position. She declined to comment publicly on the 2026 mid-decade redistricting debate.', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester', 'https://www.thebanner.com/politics-power/state-government/maryland-redistricting-senators-senate-ferguson-HL75HWXXH5ENXKJLO4CRCMIPT4/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hester proposed data center incentives in 2025 requiring operators to contribute their own power generation to the grid$$,
        ARRAY['balancing economic development with grid stability and ratepayer costs.', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Hester's platform emphasizes expanding access to healthcare and education funding and supporting families regardless of ZIP code$$,
        ARRAY['consistent with progressive childcare investment priorities.', 'https://www.katiefryhester.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katie Fry Hester / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6da20195-1b0c-43f2-b1b3-7a3954326fe6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hester voted to override the governor's minimum wage veto in 2019 and supported bipartisan amendments for small business relief. She convened a cross-party workgroup on wage policy impacts$$,
        ARRAY['indicating moderate progressive fiscal views.', 'https://en.wikipedia.org/wiki/Katie_Fry_Hester']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Shelly Hettleman
-- ============================================================

-- ----- Shelly Hettleman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hettleman signed a 2019 manifesto reaffirming commitment to abortion rights and sponsored 2023 legislation requiring patient consent before reproductive health records cross state lines. She also sponsored a 2017 law allowing pharmacists to dispense oral contraceptives without a prescription.$$,
        ARRAY['https://ballotpedia.org/Shelly_Hettleman', 'https://en.wikipedia.org/wiki/Shelly_L._Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hettleman voted for the 2019 End-of-Life Option Act and introduced 2020 legislation to allow supervised injection sites. She also sponsored the 2025 Overdose and Infectious Disease Prevention Services Program bill (SB0083).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS', 'https://en.wikipedia.org/wiki/Shelly_L._Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hettleman introduced right-to-counsel legislation for eviction cases (2021)$$,
        ARRAY['sponsored the Affordable Housing Payment In Lieu of Taxes Expansion Act (SB0327 2025)', 'and supported property tax valuation reforms for low-income housing tax credit properties.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hettleman co-introduced the Fair Share for Maryland Act of 2025 (SB0859) to raise $1.6 billion by increasing top income tax rate to 7%$$,
        ARRAY['reducing estate tax exemption', 'and requiring worldwide combined reporting for large corporations — explicitly to make wealthier Marylanders pay more.', 'https://fairsharemaryland.org/fair-share-maryland-revenue-legislation-to-be-introduced/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hettleman passed a 2021 law allowing transgender name changes without newspaper advertising and sponsored the 2025 antihate and antidiscrimination bill (SB0847) for higher education. She co-founded the Maryland Jewish Legislative Caucus in 2024.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shelly_L._Hettleman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Hettleman supported the Time to Care Act in 2022 creating a state paid family leave program$$,
        ARRAY['and sponsors child tax credit expansion under the Fair Share for Maryland Act. Her record indicates consistent support for working families and childcare-related legislation.', 'https://ballotpedia.org/Shelly_Hettleman', 'https://fairsharemaryland.org/fair-share-maryland-revenue-legislation-to-be-introduced/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hettleman sponsored the 2025 Correctional Services - Geriatric and Medical Parole bill (SB0181) and has a track record of criminal justice reform including rape kit testing legislation and expungement reform (Expungement Reform Act of 2025).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS', 'https://en.wikipedia.org/wiki/Shelly_L._Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hettleman sponsored the Family and Law Enforcement Protection Act (SB0943 2025) and the Rape Kit Testing Tracking Program (SB0669 2025)$$,
        ARRAY['indicating a balanced approach that supports both victim services and police accountability reforms.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Hettleman sponsored a 2025 bill (SB0395) requiring impact assessments for major highway capacity expansion projects$$,
        ARRAY['signaling support for environmental review of transportation infrastructure', 'and also the Public EV Supply Equipment Regulation bill (SB0913).', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hettleman chairs the public safety transportation and environment subcommittee as of 2026 and sponsored the EV infrastructure regulation bill (SB0913) and highway impact assessment bill (SB0395) in 2025$$,
        ARRAY['consistent with a progressive-leaning climate policy orientation.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS', 'https://ballotpedia.org/Shelly_Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Hettleman sponsored the Courts - Strategic Lawsuits Against Public Participation (anti-SLAPP) bill (SB0167 2025)$$,
        ARRAY['which protects free speech and public participation against abusive litigation', 'consistent with protecting open public discourse.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hettleman sponsored the RAISE Act (Registered Apprenticeship Investments for a Stronger Economy) and the Maryland STEM Program bill (SB0673 2025)$$,
        ARRAY['reflecting a workforce-focused progressive economic development approach.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS', 'https://ballotpedia.org/Shelly_Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shelly Hettleman / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3089c813-f0a8-46af-9a7b-1699129037e9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Hettleman's consistent sponsorship of affordable housing bills including the Affordable Housing PILOT Expansion Act (SB0327) and tenant right-to-counsel legislation indicates strong support for renter protections and rent stabilization policies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hettleman02?ys=2025RS', 'https://en.wikipedia.org/wiki/Shelly_L._Hettleman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Carl Jackson
-- ============================================================

-- ----- Carl Jackson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jackson voted NO on SB 798 in 2023 alongside all 13 Republicans and only one other Democrat$$,
        ARRAY['opposing the constitutional reproductive freedom amendment. This is a notable departure from his party on abortion access.', 'https://fastdemocracy.com/bill-search/md/2023/bills/MDB00027927/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jackson was one of only two Democratic senators to vote against the Community Trust Act in 2026$$,
        ARRAY['which restricts ICE cooperation. He has expressed more restrictionist instincts than most Maryland Democrats on immigration enforcement.', 'https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/', 'https://en.wikipedia.org/wiki/Carl_W._Jackson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Jackson opposed the Community Trust Act limiting ICE detention authority in 2026$$,
        ARRAY['aligning with Republicans on immigration enforcement — a significant crossover vote for a Baltimore County Democrat.', 'https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Jackson opposed Maryland's 2026 mid-decade redistricting$$,
        ARRAY['stating he aligns with Senate President Ferguson''s position and arguing the process should not proceed mid-decade for partisan advantage.', 'https://www.thebanner.com/politics-power/state-government/maryland-redistricting-senators-senate-ferguson-HL75HWXXH5ENXKJLO4CRCMIPT4/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jackson supported a Republican amendment requiring youth charged with first-degree murder to face adult courts during the 2026 session. He also introduced a bill making false identity statements to police a misdemeanor with hate crime enhancements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carl_W._Jackson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Jackson's support for adult prosecution of youth charged with first-degree murder and his legislation expanding police identity fraud penalties reflect a more punitive criminal justice posture than most Democrats.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carl_W._Jackson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jackson voted against overriding a gubernatorial veto on digital advertising taxes targeting large tech companies in 2021$$,
        ARRAY['suggesting skepticism of broad business tax increases.', 'https://en.wikipedia.org/wiki/Carl_W._Jackson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carl Jackson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fbad601-c2da-4f99-b04f-d28ae30b80f7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jackson introduced legislation banning registered sex offenders from public schools and championed community access to swimming facilities to address historical racial exclusion in public amenities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carl_W._Jackson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- J.B. Jennings
-- ============================================================

-- ----- J.B. Jennings / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jennings voted NO on SB 798 in 2023$$,
        ARRAY['opposing Maryland''s reproductive freedom constitutional amendment. His Republican conservative record is consistent with anti-abortion positions.', 'https://fastdemocracy.com/bill-search/md/2023/bills/MDB00027927/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jennings describes himself as "a guy who hates taxes" and voted against the FY2026 Budget and its accompanying $1.6 billion tax and fee increase. He proposed Republican amendments to eliminate the need to raise taxes.$$,
        ARRAY['https://www.jbjennings.com/budget', 'https://marylandmatters.org/2025/03/31/senate-republicans-score-budget-win-as-spending-plan-clears-preliminary-hurdle/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Jennings supports keeping existing coal capacity operational for peak demand and opposes aggressive green energy mandates$$,
        ARRAY['favoring nuclear and local generation over rapid fossil fuel phase-out. He considers nuclear the "best source" for Maryland.', 'https://www.jbjennings.com/energy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jennings opposes mandatory green energy timelines and is skeptical of aggressive emissions targets$$,
        ARRAY['citing energy reliability concerns and opposing costly transmission infrastructure projects.', 'https://www.jbjennings.com/energy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jennings voted against the Community Trust Act in 2026$$,
        ARRAY['which restricts ICE cooperation. As Senate Minority Leader he led Republican opposition to Maryland sanctuary-style immigration policies.', 'https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As Senate Minority Leader and consistent Republican$$,
        ARRAY['Jennings supports immigration enforcement cooperation including 287(g) programs and voted against limiting ICE detention authority in 2026.', 'https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Jennings opposed Maryland's 2026 mid-decade congressional redistricting effort and argued that allowing every bill a vote could lead to poor policy outcomes on gerrymandering.$$,
        ARRAY['https://www.thebanner.com/politics-power/state-government/maryland-redistricting-senators-senate-ferguson-HL75HWXXH5ENXKJLO4CRCMIPT4/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Jennings voted against the 2012 Civil Marriage Protection Act legalizing same-sex marriage in Maryland and in 2006 supported efforts to advance a constitutional amendment banning same-sex marriage.$$,
        ARRAY['https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jennings opposes gun control laws and prefers mental health service reforms. He introduced a bill allowing the governor to declare a state of emergency over Baltimore's high crime rates.$$,
        ARRAY['https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jennings expressed skepticism toward automatic voter registration proposals in 2016 and wrote to the Maryland State Board of Elections raising voter fraud concerns about mail-in ballots in 2020.$$,
        ARRAY['https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jennings has shown pragmatism on healthcare — supporting a 2018 health insurer tax to stabilize the marketplace and backing 2021 legislation limiting medical debt collection against low-income Marylanders.$$,
        ARRAY['https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Jennings waged a filibuster against a bill prohibiting state vouchers for struggling schools$$,
        ARRAY['signaling support for school choice programs.', 'https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.B. Jennings / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5927d5ab-2fd7-4454-bcc3-34e494821aac',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No documented position on AI or media misinformation regulation found; as a Republican he would be expected to be skeptical of government content regulation.$$,
        ARRAY['https://en.wikipedia.org/wiki/J._B._Jennings']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Clarence K. Lam
-- ============================================================

-- ----- Clarence K. Lam / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lam has sponsored multiple bills expanding abortion care access and contraceptive availability in Maryland. He explicitly states that "access to abortion care is a core tenet of bodily and medical autonomy" and has sponsored emergency pregnancy-related medical conditions legislation (SB0447 2025).$$,
        ARRAY['https://www.clarencelam.com/meet-clarence/', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lam is the only physician in the Maryland Senate and believes healthcare is a human right. He capped insulin at $1/day$$,
        ARRAY['expanded Medicaid for pregnant people and undocumented immigrants', 'and sponsored 15+ healthcare bills in 2025 alone covering drug pricing', 'mental health']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Lam has repeatedly expanded Maryland Medical Assistance (Medicaid) coverage including to undocumented immigrants and sponsored multiple 2025 Medicaid bills (SB0111 step therapy$$,
        ARRAY['SB0438 pharmacy benefits', 'SB0448 self-directed mental health', 'SB0974 nonopioid pain drugs).']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lam helped pass the Climate Solutions Now Act requiring Maryland to reduce carbon footprint 60%+ by 2031 and be carbon neutral by 2045. He also sponsored bills banning toxic pesticides and reducing environmental impacts of state buildings.$$,
        ARRAY['https://www.clarencelam.com/meet-clarence/', 'https://ballotpedia.org/Clarence_Lam']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Lam sponsored the CHERISH Our Communities Act (SB0978 2025) requiring greater public participation in environmental permitting$$,
        ARRAY['and has previously passed legislation banning mercury and lead in trucking and prohibiting chlorpyrifos pesticide.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS', 'https://www.clarencelam.com/meet-clarence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lam's environmental record emphasizes reducing carbon emissions through the Climate Solutions Now Act and repeatedly sponsored bills to limit pollutants$$,
        ARRAY['consistent with strong opposition to fossil fuel expansion.', 'https://www.clarencelam.com/meet-clarence/', 'https://ballotpedia.org/Clarence_Lam']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lam$$,
        ARRAY['a child of immigrants', 'supports comprehensive immigration reform and a citizenship pathway for DREAMers. He sponsored the Maryland Data Privacy Act (SB0977 2025) restricting cooperation with federal immigration enforcement and previously expanded healthcare to undocumented immigrants.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Lam sponsored the Maryland Data Privacy Act (SB0977 2025) restricting law enforcement access to information that could be used for federal immigration enforcement$$,
        ARRAY['directly limiting deportation cooperation.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lam sponsored the Birth Certificate Modernization Act (SB0314 2025) updating sex designation rules$$,
        ARRAY['advocates for LGBTQ+ protections and the Equality Act', 'and has consistently supported anti-discrimination measures throughout his tenure.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Lam supports reducing racially biased policing$$,
        ARRAY['reforming mandatory minimums', 'eliminating crack/powder cocaine sentencing disparities', 'and reducing three-strikes penalties. He also sponsored forensic mental health treatment reform (SB0741 2025).']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Lam supports increased police accountability and reducing racially biased policing$$,
        ARRAY['and has advocated for criminal justice reform that addresses systemic racism throughout his legislative record.', 'https://www.clarencelam.com/meet-clarence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lam explicitly supports making wealthy individuals and large corporations pay their fair share$$,
        ARRAY['and opposes wealth inequality through tax policy. He supports legislation requiring corporations to pay equitable taxes.', 'https://www.clarencelam.com/meet-clarence/', 'https://ballotpedia.org/Clarence_Lam']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lam champions universal early childhood education$$,
        ARRAY['increased K-12 public school funding', 'and supports paid family leave. He also sponsored school health and wellness personnel assessment legislation (SB0486 2025).', 'https://www.clarencelam.com/meet-clarence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Lam serves on the Joint Committee on Ending Homelessness indicating institutional commitment to addressing homelessness$$,
        ARRAY['though specific bill sponsorships focus more on healthcare and environmental policy.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02', 'https://ballotpedia.org/Clarence_Lam']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Lam sponsored the Artificial Intelligence - Health Software and Health Insurance Decision Making bill (SB0987 2025)$$,
        ARRAY['requiring oversight and regulation of AI use in healthcare settings.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Lam's profile does not show specific campaign finance reform legislation though his progressive stance on economic fairness and corporate accountability implies support for campaign finance transparency measures.$$,
        ARRAY['https://ballotpedia.org/Clarence_Lam']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lam sponsored the Maryland Small Business Innovation Research program alterations (SB0302 2025) and supports minority-owned small businesses. His economic approach prioritizes equity alongside growth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS', 'https://www.clarencelam.com/meet-clarence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Clarence K. Lam / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc23b939-0dfd-4968-ab19-fc1e7745e997',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$As a progressive Democrat Lam supports voting rights protections; he sponsored a 2025 bill (SB0171) on general assembly vacancy procedures related to political party representation$$,
        ARRAY['consistent with fair electoral access.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mike McKay
-- ============================================================

-- ----- Mike McKay / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McKay states that life begins at conception and the government has an obligation to protect the unborn — a strongly anti-abortion position.$$,
        ARRAY['https://mikemckaymd.com/', 'https://ballotpedia.org/Mike_McKay']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McKay has consistently supported legalizing fracking in Maryland citing energy prices and introduced legislation to repeal the state fracking ban in 2025. He also voted against the Utility RELIEF Act in 2026.$$,
        ARRAY['https://mikemckaymd.com/state-senators-propose-bill-to-legalize-fracking/', 'https://en.wikipedia.org/wiki/Mike_McKay_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McKay introduced bills to strip protections from state wildlands in Garrett and Allegany counties and opposed climate-related legislation (voted Nay on SB 149 greenhouse gas emission payments in 2025).$$,
        ARRAY['https://mikemckaymd.com/senator-mike-mckaysthird-reader-floor-votes-week-of-march-17th-2025/', 'https://en.wikipedia.org/wiki/Mike_McKay_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McKay campaigns explicitly on cutting taxes and government waste and supported manufacturing business personal property tax exemptions.$$,
        ARRAY['https://mikemckaymd.com/', 'https://ballotpedia.org/Mike_McKay']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McKay pledges to give law enforcement everything they need and to vote against any measure to defund police at every level.$$,
        ARRAY['https://mikemckaymd.com/', 'https://ballotpedia.org/Mike_McKay']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McKay voted Yea on SB 828 (sensitive locations protections for immigrants) suggesting some moderation but his overall Republican platform is enforcement-focused.$$,
        ARRAY['https://mikemckaymd.com/senator-mike-mckaysthird-reader-floor-votes-week-of-march-17th-2025/', 'https://ballotpedia.org/Mike_McKay']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$The Maryland Senate voted 27-17 along party lines to reject an amendment banning transgender athletes from female sports; as a Western MD Republican McKay almost certainly voted for the ban.$$,
        ARRAY['https://marylandmatters.org/2025/04/02/senate-oks-blueprint-bills-next-step-is-to-iron-out-differences-with-house/', 'https://ballotpedia.org/Mike_McKay']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$McKay introduced an amendment in 2026 to designate April as Christian American Heritage Month during debate on a religious heritage months bill — indicating strong religious-conservative orientation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mike_McKay_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McKay serves on the Judicial Proceedings Committee and voted Nay on SB 343 (State's attorneys transparency task force) suggesting resistance to prosecutor accountability measures.$$,
        ARRAY['https://mikemckaymd.com/senator-mike-mckaysthird-reader-floor-votes-week-of-march-17th-2025/', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mckay02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike McKay / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f88cd73d-1970-4da1-9bea-2142a25999a7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$McKay sponsored legislation to strip state wildland protections in Garrett and Allegany counties for economic development purposes.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mike_McKay_(politician)', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mckay02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Justin Ready
-- ============================================================

-- ----- Justin Ready / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ready is publicly 100% pro-life from conception; he opposed a $3.5 million abortion training bill as "reckless and wrong" and attempted to add coercion protections to the 2024 abortion constitutional referendum.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready', 'https://www.justinready.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ready voted against the Civil Marriage Protection Act legalizing same-sex marriage in Maryland in 2012 and defended school pride flag bans in 2022.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Ready opposed legal protections for gender-affirming care providers in 2024 arguing it expanded access to minors; the Maryland Senate voted 27-17 along party lines on trans athletes and Ready voted with Republicans.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://marylandmatters.org/2025/04/02/senate-oks-blueprint-bills-next-step-is-to-iron-out-differences-with-house/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ready supported repealing Maryland's Dream Act (2012) calling it a sanctuary state bill; introduced legislation requiring correctional cooperation with ICE; opposed restrictions on 287(g) agreements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ready blamed Maryland's renewable energy investments for higher electricity prices and opposed the Next Generation Energy Act (2026); he supports nuclear and gas permitting expansion instead.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ready supports nuclear and gas-fired power expansion and opposed accelerating renewable energy mandates; he voted against the Next Generation Energy Act in 2026.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ready supports repealing the Affordable Care Act; he opposed vaccine guidance independence from federal standards in 2026 and criticized the End-of-Life Option Act.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ready introduced voter ID bills citing 2020 election "major deficiencies"; opposed automatic voter registration (2016); supported proof-of-citizenship voting requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ready is Minority Whip and campaigns on bringing down cost of living through conservative reform; he opposed 2017 paid sick leave saying it would "exacerbate income inequality."$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://www.justinready.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ready introduced a bill in November 2025 to ban mid-decade redistricting and require independent redistricting commissions; he opposed Democratic gerrymandering attempts.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ready introduced Laura and Reid's Law increasing penalties for murdering pregnant women; he supports harsher penalties for violent crimes and consistently opposes police reform bills.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ready opposed police reform bills calling use-of-force provisions "the most dangerous"; he supports increased criminal penalties and opposed reforms limiting automatic adult charging of youth offenders.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Ready signed an amicus brief defending the Peace Cross monument and campaigns on values-based conservative governance centered on faith and family.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://www.justinready.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Ready / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('493c5d0c-1986-40d4-9fff-3a3bc3fe62e8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ready opposed the Kirwan Commission education funding recommendations and introduced parental rights legislation (2023); his conservative education platform aligns with school choice.$$,
        ARRAY['https://en.wikipedia.org/wiki/Justin_Ready', 'https://ballotpedia.org/Justin_Ready']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Johnny Ray Salling
-- ============================================================

-- ----- Johnny Ray Salling / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Salling voted NO on SB 798 (2023) to place a reproductive freedom amendment on the Maryland ballot. He also moved to strip state abortion funding from the 2025 budget$$,
        ARRAY['indicating strong anti-abortion views.', 'https://fastdemocracy.com/bill-search/md/2023/bills/MDB00027927/', 'https://marylandmatters.org/2025/03/31/senate-republicans-score-budget-win-as-spending-plan-clears-preliminary-hurdle/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Ray Salling / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Salling proposed an amendment to lower Maryland's 2030 emissions reduction target from 60% to 50%$$,
        ARRAY['which failed on party lines. He also received a 17% score from the Maryland League of Conservation Voters in 2018 — the lowest in the Senate.', 'https://www.marylandmatters.org/2021/03/10/md-senate-advances-far-reaching-climate-bill/', 'https://en.wikipedia.org/wiki/Johnny_Ray_Salling']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Ray Salling / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Salling opposes aggressive clean-energy mandates and aligned with Republican efforts to soften Maryland's greenhouse gas reduction targets$$,
        ARRAY['favoring a slower transition away from fossil fuels.', 'https://www.marylandmatters.org/2021/03/10/md-senate-advances-far-reaching-climate-bill/', 'https://en.wikipedia.org/wiki/Johnny_Ray_Salling']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Ray Salling / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Salling called Baltimore County's undocumented immigrant directive "dangerous" in 2017 and warned in 2025 that restricting 287(g) agreements could "put communities at risk$$,
        ARRAY['indicating strong opposition to sanctuary-style policies.,https://en.wikipedia.org/wiki/Johnny_Ray_Salling,,
Johnny Ray Salling,deportation,5,Salling voted against the Community Trust Act in 2026, which restricted ICE cooperation; as a Republican he consistently supports federal immigration enforcement including deportation operations.,https://marylandmatters.org/2026/04/11/senate-rushes-community-trust-act-through-limiting-immigration-cooperation/,,
Johnny Ray Salling,public-safety-approach,5,Salling strongly advocates increased police funding and training and explicitly disagrees with calls to defund police departments.,https://en.wikipedia.org/wiki/Johnny_Ray_Salling,,
Johnny Ray Salling,redistricting,5,Salling opposed Maryland''s 2026 mid-decade congressional redistricting effort, stating I don''t think there''s a need for it" and calling the proposed map "gerrymandered."', 'https://www.thebanner.com/politics-power/state-government/maryland-redistricting-senators-senate-ferguson-HL75HWXXH5ENXKJLO4CRCMIPT4/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Ray Salling / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Salling co-sponsored Republican amendments during the 2025 budget process aimed at eliminating the need for tax and fee increases$$,
        ARRAY['reflecting consistent anti-tax positions.', 'https://marylandmatters.org/2025/03/31/senate-republicans-score-budget-win-as-spending-plan-clears-preliminary-hurdle/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Ray Salling / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f8d0005-c5ff-42f8-b158-cdb6e4eee872',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Salling has not publicly championed expanded voting access; as a Trump ally and social conservative he aligns with Republican skepticism toward measures like automatic voter registration and mail-in voting expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Johnny_Ray_Salling']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Karen Lewis Young
-- ============================================================

-- ----- Karen Lewis Young / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Young signed the 2019 manifesto with 325 state legislators reaffirming commitment to protecting abortion access and has a consistent pro-abortion-rights record as a Democrat.$$,
        ARRAY['https://en.wikipedia.org/wiki/Karen_Lewis_Young', 'https://ballotpedia.org/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Young sponsored the Patient Bill of Rights and the Right to Try Act; she supports expanding pharmacist access for uninsured patients and worked to secure funding for a new Frederick hospital.$$,
        ARRAY['https://lewisyoungforsenate.com/issues', 'https://en.wikipedia.org/wiki/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Young was lead cosponsor of SB245 (2026) that immediately ended all 287(g) ICE agreements statewide and prohibits new ICE cooperation agreements; she voted for the Community Trust Act.$$,
        ARRAY['https://en.wikipedia.org/wiki/Karen_Lewis_Young', 'https://lewisyoungforsenate.com/issues', 'https://ballotpedia.org/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Young introduced 2023 legislation to expand the EmPOWER energy efficiency program to include greenhouse gas reduction goals; she sponsored data center environmental impact analysis legislation that passed over a veto.$$,
        ARRAY['https://en.wikipedia.org/wiki/Karen_Lewis_Young', 'https://marylandmatters.org/2025/12/16/general-assembly-climate-veto-overrides/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Young supported repealing Maryland's Law Enforcement Officers' Bill of Rights making Maryland the first state to fully repeal it; she backed police reform and body camera requirements.$$,
        ARRAY['https://lewisyoungforsenate.com/issues', 'https://en.wikipedia.org/wiki/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Young opposed Maryland's mid-decade congressional redistricting proposal in 2026 on constitutional grounds even though it favored Democrats — a principled stand against partisan gerrymandering.$$,
        ARRAY['https://en.wikipedia.org/wiki/Karen_Lewis_Young', 'https://ballotpedia.org/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Young sponsored Mason's Law (SB189) requiring storm drain grate safety standards and previously introduced legislation requiring superfund contamination disclosure to homebuyers.$$,
        ARRAY['https://thedailyrecord.com/2025/05/05/karen-lewis-young-2/', 'https://lewisyoungforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Young advocated repealing Maryland's official state song "Maryland My Maryland" for its racist content and supported removing the Roger B. Taney monument from the State House.$$,
        ARRAY['https://en.wikipedia.org/wiki/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Young has fought for Medicaid reimbursement expansions and healthcare access for uninsured and underinsured patients; she opposed Hogan's withholding of school funding from high-cost districts.$$,
        ARRAY['https://lewisyoungforsenate.com/issues', 'https://en.wikipedia.org/wiki/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Young supports gun violence prevention including banning ghost guns expanding background checks on long guns and requiring dealer security measures; she also backed funding the 9-8-8 mental health crisis hotline.$$,
        ARRAY['https://lewisyoungforsenate.com/issues', 'https://justfacts.votesmart.org/bill/32582/85219/122628/karen-lewis-young-voted-yea-conference-report-vote-sb-861-increases-firearm-misdemeanors-into-felonies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Young is a member of the Joint Committee on Ending Homelessness (2023-present) and serves on the Budget and Taxation public safety subcommittee which addresses these issues.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/young04', 'https://ballotpedia.org/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Lewis Young / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f78b5e2-b192-4aae-8112-19338aaa891d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Young supports jobs in Frederick County and concerns about data centers not offsetting environmental costs; she passed SB116 requiring comprehensive data center economic and energy analysis.$$,
        ARRAY['https://lewisyoungforsenate.com/issues', 'https://en.wikipedia.org/wiki/Karen_Lewis_Young']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Craig J. Zucker
-- ============================================================

-- ----- Craig J. Zucker / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Zucker is a suburban Democratic senator but direct abortion bill sponsorship is limited in the available record. He has consistently voted with Democratic caucus on reproductive rights and co-signed letters against defunding healthcare organizations.$$,
        ARRAY['https://ballotpedia.org/Craig_Zucker', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Zucker supports expanding affordable healthcare access through the Maryland Health Care Exchange and protected healthcare funding for low-income pregnant women on the Appropriations Committee. His overall record on healthcare is supportive but not among his primary legislative focus areas.$$,
        ARRAY['https://craigzucker.com/issues/', 'https://ballotpedia.org/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Zucker co-sponsored clean energy promotion legislation and bills protecting the Chesapeake Bay. He opposes fracking and has earned endorsements from the League of Conservation Voters and Sierra Club.$$,
        ARRAY['https://craigzucker.com/issues/', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Zucker co-sponsored Chesapeake Conservation Corps legislation (SB0073 2025) and has repeatedly co-sponsored Chesapeake Bay protection bills. He voted for zero-emission bus legislation (2021) and opposes fracking.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS', 'https://craigzucker.com/issues/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Zucker explicitly opposes fracking and co-sponsored clean energy promotion legislation. He voted for zero-emission transit bus legislation in 2021 prohibiting non-zero-emission bus purchases.$$,
        ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker', 'https://craigzucker.com/issues/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Zucker stated support for Civil Marriage Protection Act (2011)$$,
        ARRAY['voted to repeal capital punishment (2013)', 'sponsored sexual harassment NDA ban legislation (2018)', 'co-sponsored Tommy Bloom Raskin crisis counselor act (2021)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Zucker publicly stated support for the Civil Marriage Protection Act in 2011 and has maintained consistent support for LGBTQ+ rights throughout his legislative career.$$,
        ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Zucker voted to restore voting rights to released felons (2016 veto override)$$,
        ARRAY['proposed an independent redistricting commission (2017)', 'and co-sponsored the Maryland Voting Rights Act of 2025 (SB0342).', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Zucker proposed an independent redistricting commission bill in 2017 that passed but was vetoed by Governor Hogan. He co-sponsored the Voting Rights Act of 2025 county redistricting provisions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Zucker introduced a 2022 bill redirecting $14 million to right-to-counsel programs for tenants facing eviction$$,
        ARRAY['which passed. His housing record is targeted at tenant protection rather than broad housing reform.', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Budget and Taxation Committee member$$,
        ARRAY['Zucker has balanced fiscal caution with progressive revenue measures. He sponsored the Digital Advertising Gross Revenues Tax appeals bill (SB0605 2025) and voted for fuel tax indexing to inflation for infrastructure (2013).', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Zucker voted to repeal capital punishment (2013) and to restore voting rights to released felons (2016). He also co-sponsored the Family and Law Enforcement Protection Act (SB0943 2025).$$,
        ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Zucker authored the Maryland Jobs Reinvestment Act providing tax incentives to small businesses (25 or fewer employees) and helped create jobs through capital budget allocations. His approach prioritizes small business growth with accountability measures.$$,
        ARRAY['https://craigzucker.com/issues/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Zucker sponsored the Property Tax - Day Care Centers bill (SB0516 co-sponsor 2025) to reduce property tax burden on childcare facilities$$,
        ARRAY['and has supported education funding broadly throughout his career.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Zucker sponsored 2018 legislation requiring social media platforms to record political advertisement data to improve transparency around political ads. This represents a moderate approach to combating political misinformation online.$$,
        ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Zucker supports legislation targeting criminal gangs and domestic violence while also advocating for adequate police and firefighter funding. He co-sponsored the Family and Law Enforcement Protection Act (SB0943 2025).$$,
        ARRAY['https://craigzucker.com/issues/', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/zucker01?ys=2025RS']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig J. Zucker / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('82145bc2-770a-421e-a2a1-0e79aae5b643',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Zucker supported requiring social media platforms to record political advertisement data (2018 law)$$,
        ARRAY['indicating interest in transparency but his overall campaign finance reform record is moderate.', 'https://en.wikipedia.org/wiki/Craig_Zucker']::text[]::text[])
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
-- WHERE p.id IN ('f88cd73d-1970-4da1-9bea-2142a25999a7', '5127f8d8-ca40-40aa-8773-4c1abad66f41', '1f78b5e2-b192-4aae-8112-19338aaa891d', '4a5241b7-8737-4a58-adf2-c5335111d3c4', '493c5d0c-1986-40d4-9fff-3a3bc3fe62e8', '9f8d0005-c5ff-42f8-b158-cdb6e4eee872', '5927d5ab-2fd7-4454-bcc3-34e494821aac', '2fbad601-c2da-4f99-b04f-d28ae30b80f7', '6da20195-1b0c-43f2-b1b3-7a3954326fe6', 'a16b94b0-dd22-40a9-af91-03295ea27986', '3089c813-f0a8-46af-9a7b-1699129037e9', 'fc23b939-0dfd-4968-ab19-fc1e7745e997', 'f0fafa0e-3dd9-4d50-bc5e-c96315f766d7', '82145bc2-770a-421e-a2a1-0e79aae5b643', 'd423151e-8477-470d-8f73-ba7d2092f714')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('f88cd73d-1970-4da1-9bea-2142a25999a7', '5127f8d8-ca40-40aa-8773-4c1abad66f41', '1f78b5e2-b192-4aae-8112-19338aaa891d', '4a5241b7-8737-4a58-adf2-c5335111d3c4', '493c5d0c-1986-40d4-9fff-3a3bc3fe62e8', '9f8d0005-c5ff-42f8-b158-cdb6e4eee872', '5927d5ab-2fd7-4454-bcc3-34e494821aac', '2fbad601-c2da-4f99-b04f-d28ae30b80f7', '6da20195-1b0c-43f2-b1b3-7a3954326fe6', 'a16b94b0-dd22-40a9-af91-03295ea27986', '3089c813-f0a8-46af-9a7b-1699129037e9', 'fc23b939-0dfd-4968-ab19-fc1e7745e997', 'f0fafa0e-3dd9-4d50-bc5e-c96315f766d7', '82145bc2-770a-421e-a2a1-0e79aae5b643', 'd423151e-8477-470d-8f73-ba7d2092f714')
--   AND pc.politician_id IS NULL;