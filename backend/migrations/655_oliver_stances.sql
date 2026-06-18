-- ============================================================================
-- Migration 655: New Bedford Ward 3 Councilor Shawn Oliver Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford Ward 3 Councilor
--          Shawn Oliver.
--
-- Oliver won a February 2023 special election and was re-elected unopposed in
-- 2025. He is a corrections officer and constable. He previously identified as
-- unenrolled/conservative, joining the Republican Party in August 2025. He was
-- elected chair of the New Bedford Republican City Committee in February 2026.
-- In June 2026 he announced a run for Massachusetts Lieutenant Governor on the
-- Republican ticket with candidate Brian Shortsleeve.
--
-- Documented position: Co-authored a ballot question (with Ward 1's Choquette)
-- seeking voter approval to restrict NBPD hiring to US citizens only,
-- explicitly calling non-citizen police employment problematic.
--
-- Total rows: 1 (immigration)
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

-- Politician UUID reference:
-- Shawn Oliver (Ward 3)            206795e1-0a66-4f8c-b526-b9200639ff15

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

-- ----- Shawn Oliver / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('206795e1-0a66-4f8c-b526-b9200639ff15',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('206795e1-0a66-4f8c-b526-b9200639ff15',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Oliver co-authored a 2024 ballot question with Ward 1 Councilor Leo Choquette to put before New Bedford voters the question of whether legal permanent residents (non-citizens) should be permitted to serve as NBPD officers — seeking to restrict police hiring to US citizens only. His broader public record reflects a conservative, restrictive immigration posture: he joined the Republican Party in August 2025 after previously being unenrolled, identifying himself as "always a conservative." In his June 2026 Lieutenant Governor announcement, his running mate Brian Shortsleeve praised Oliver as someone who understands "that taxpayer money is not free money" and that government should serve citizens. Oliver's immigration stance aligns with strict enforcement: citizenship is a meaningful threshold, legal permanent residents should not hold sworn law enforcement authority. Value 4 (significantly restrict immigration and prioritize enforcement).$$,
        ARRAY['https://wbsm.com/new-bedford-police-citizenship-question-ordinance/', 'https://wbsm.com/new-bedford-oliver-lieutenant-governor-shortsleeve/', 'https://wbsm.com/new-bedford-councilors-join-republican-party/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
