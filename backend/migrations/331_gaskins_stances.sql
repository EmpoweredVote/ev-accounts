-- ============================================================================
-- Migration 331: Alyia Gaskins Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Alyia Gaskins (Mayor of Alexandria).
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
-- Alyia Gaskins
-- ============================================================

-- ----- Alyia Gaskins / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Gaskins has championed Alexandria's Zoning for Housing/Housing for All overhaul, calling it "a key city priority that advances our commitment to expanding and diversifying housing options across Alexandria." When a Circuit Court judge dismissed a lawsuit challenging the zoning changes in November 2025, Gaskins praised the decision and pledged to continue ensuring "Alexandria remains affordable and accessible to all." The reform allows up to four units on any property in the city. She also led the Fresh Start Initiative in March 2026, rallying faith and nonprofit leaders to pay $1 million in back rent for nearly 450 public housing residents to prevent mass evictions.$$,
        ARRAY['https://www.alxnow.com/2025/11/12/just-in-judge-dismisses-case-against-alexandrias-zoning-for-housing-overhaul/',
              'https://www.alxnow.com/2026/03/19/just-in-mayor-gaskins-rallies-alexandria-church-to-settle-1m-in-arha-back-rent/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Gaskins was a leading defender of Alexandria's Zoning for Housing overhaul, which was approved by City Council in December 2023. The reform includes allowing multi-family homes of up to four units on any residential lot, reducing parking minimums for single-family homes, and facilitating office-to-residential conversions. When the lawsuit against the overhaul was dismissed in November 2025, Gaskins stated that "the zoning amendments reflected years of thoughtful, thorough deliberation." She also lobbied Virginia lawmakers in Richmond for more local authority to expand housing options in January 2026.$$,
        ARRAY['https://www.alxnow.com/2025/11/12/just-in-judge-dismisses-case-against-alexandrias-zoning-for-housing-overhaul/',
              'https://www.alxnow.com/2026/01/30/councilmembers-lobby-for-housing-school-funding-and-gun-safety-laws-in-richmond/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Gaskins launched the Fresh Start Initiative in March 2026, personally rallying faith and nonprofit organizations to contribute over $1 million in donations to pay back rent for nearly 450 public housing residents facing potential eviction. She stated that "housing stability is foundational to thriving families." The initiative paired rent relief with financial empowerment resources. Gaskins noted ARHA's public housing waitlist of over 8,700 people and framed the initiative as preventing homelessness through proactive intervention.$$,
        ARRAY['https://www.alxnow.com/2026/03/19/just-in-mayor-gaskins-rallies-alexandria-church-to-settle-1m-in-arha-back-rent/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Gaskins has been a strong advocate for immigrant protections at the local level. In September 2025, she clarified that Alexandria's Flock Safety surveillance cameras cannot be used by ICE to track immigrants due to new Virginia law, and confirmed APD disabled national data-sharing capabilities to ensure compliance. She stated: "I think you have a council that has made it very clear that we believe that the actions that ICE is taking in this community, that they are wrong, that they deny people their due process, their civil liberties and their constitutional rights." Alexandria police do not participate in federal immigration enforcement.$$,
        ARRAY['https://www.alxnow.com/2025/09/04/alexandria-mayor-clarifies-flock-camera-policies-amid-immigration-enforcement-concerns/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gaskins listed gun violence prevention as a city legislative priority in January 2026, with council members traveling to Richmond to advocate for gun safety legislation including safe storage requirements and restrictions on transfers of guns from domestic violence convicts. She stated the city's legislative priorities include "everything from gun violence prevention to public safety." She also oversaw collective bargaining agreements with police and fire, indicating support for professional policing standards rather than defund approaches.$$,
        ARRAY['https://www.alxnow.com/2026/01/30/councilmembers-lobby-for-housing-school-funding-and-gun-safety-laws-in-richmond/',
              'https://www.alxnow.com/2026/04/30/city-council-approves-979-1m-budget-with-unchanged-real-estate-tax-rate-but-eyes-tougher-choices-ahead/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$In April 2026, Gaskins called a Republican congressional bill to retrocede Alexandria and Arlington back into D.C. "absolutely ridiculous and a huge distraction," framing it as an anti-democratic attempt to silence voters by rewriting boundaries when politicians disagree with electoral outcomes. She stated: "That's not happening here in Alexandria. We're not going to let that happen." She affirmed Alexandria's commitment to voter participation, noting 78.95% of Alexandria voters had backed the Virginia redistricting reform amendment.$$,
        ARRAY['https://www.alxnow.com/2026/04/27/ridiculous-mayor-gaskins-calls-gop-bill-to-return-alexandria-and-arlington-to-d-c/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Gaskins supported the FY2027 Alexandria budget of $979.1 million, which maintained the real estate tax rate at $1.135 per $100 assessed value — no property tax increase. She praised the council for balancing "investing in critically important programs while maintaining affordability." She acknowledged this was a difficult year and that future budgets may require harder choices. Her position reflects a moderate, balanced approach: supporting needed public investment without tax increases when possible.$$,
        ARRAY['https://www.alxnow.com/2026/04/30/city-council-approves-979-1m-budget-with-unchanged-real-estate-tax-rate-but-eyes-tougher-choices-ahead/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyia Gaskins / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c217f344-476f-4b84-90bc-6c731bfb4161',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Gaskins listed transportation funding among Alexandria's state legislative priorities in January 2026, with council members lobbying Richmond for transportation investments. The FY2027 budget includes DASH bus funding as part of the transportation services budget. In her September 2025 community chat, Gaskins identified transportation infrastructure projects as a key area of city investment while warning about federal funding risks to infrastructure. She takes an active role in ensuring transportation projects stay on schedule and residents are informed.$$,
        ARRAY['https://www.alxnow.com/2026/01/30/councilmembers-lobby-for-housing-school-funding-and-gun-safety-laws-in-richmond/',
              'https://www.alxnow.com/2025/09/02/alexandria-mayor-discusses-federal-funding-risks-infrastructure-projects-during-monthly-alxnow-chat/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c217f344-476f-4b84-90bc-6c731bfb4161';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c217f344-476f-4b84-90bc-6c731bfb4161'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c217f344-476f-4b84-90bc-6c731bfb4161'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
