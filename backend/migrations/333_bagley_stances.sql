-- ============================================================================
-- Migration 333: Sarah Bagley Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sarah Bagley (Vice Mayor / Council Member, Alexandria).
--
-- Topic scope: All 44 compass topics attempted; evidence-only — topics with no
--   evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
--
-- Sources policy: aggregation indexes and real news articles with date-based paths only.
--   No politician press-release URLs — slugs cannot be verified without fetching.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
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
-- Sarah Bagley
-- ============================================================

-- ----- Sarah Bagley / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bagley testified in Richmond in January 2026 in support of gun safety legislation that would require safe storage of firearms and address transfers of guns from people convicted of domestic violence crimes. She noted the bills advanced from the House Firearms Subcommittee. This reflected the city's legislative priorities on gun violence prevention. She also co-sponsored court technology improvements for Juvenile and Domestic Relations courtrooms to provide a more "trauma-informed approach" to court matters.$$,
        ARRAY['https://www.alxnow.com/2026/01/30/councilmembers-lobby-for-housing-school-funding-and-gun-safety-laws-in-richmond/',
              'https://www.alxnow.com/2026/04/14/bpol-tax-increase-no-new-acps-funding-in-city-councils-add-deletes-as-budget-vote-nears/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Bagley / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Bagley publicly questioned Alexandria's practice of housing federal inmates under a US Marshals Service contract, asking at an April 2026 City Council meeting: "Do we want to be in the federal inmate business, in the federal incarceration business?" She stated the city should reevaluate whether maintaining a large jail capacity for federal inmates is in Alexandria's interest. She also defended the $200,000 budget allocation for a jail operational efficiency study against the Sheriff's objections, arguing the study would inform decisions about future capacity and contracts.$$,
        ARRAY['https://www.alxnow.com/2026/04/24/sheriff-blasts-budget-cut-by-city-council-to-study-u-s-marshals-service-jail-contract/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Bagley / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Bagley co-sponsored (with Elnoubi and Aguirre) a proposal in the FY2027 budget process to increase Alexandria's emergency rental assistance program by $458,500 per year over five years. The purpose was to assist families at risk of eviction, including those behind on rent and facing imminent eviction. She also co-sponsored a one-time $83,000 contingency fund for the Healthy Homes Action Plan, which targets improved health and housing conditions for economically disadvantaged Alexandria residents.$$,
        ARRAY['https://www.alxnow.com/2026/04/14/bpol-tax-increase-no-new-acps-funding-in-city-councils-add-deletes-as-budget-vote-nears/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Bagley / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2be866-a3aa-493b-8475-4a051bcc2461',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bagley participated in Alexandria's January 2026 Richmond lobby day, where she and fellow council members advocated for state legislative authority to expand housing options. The city's legislative priorities that session included "bills that would provide more local authority to expand housing." She also noted in her budget remarks that Alexandria was "hardest hit" by federal job losses yet avoided a tax increase, framing housing affordability as a continued long-term challenge that will require tough choices in future budget years.$$,
        ARRAY['https://www.alxnow.com/2026/01/30/councilmembers-lobby-for-housing-school-funding-and-gun-safety-laws-in-richmond/',
              'https://www.alxnow.com/2026/04/30/city-council-approves-979-1m-budget-with-unchanged-real-estate-tax-rate-but-eyes-tougher-choices-ahead/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 4 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ce2be866-a3aa-493b-8475-4a051bcc2461';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ce2be866-a3aa-493b-8475-4a051bcc2461'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ce2be866-a3aa-493b-8475-4a051bcc2461'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
