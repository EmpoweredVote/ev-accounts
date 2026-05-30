-- ============================================================================
-- Migration 216: SF Officials Stances — 20 San Francisco Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data for 20 politicians.
--
-- Topic scope: All 43 compass topics (city + federal); only data-centers excluded.
--
-- Post-state: ~366 rows expected
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
-- Connie Chan
-- ============================================================

-- ----- Connie Chan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chan has consistently opposed market-rate housing development in District 1. In 2021 she voted to block a 495-unit apartment complex near a BART station citing insufficient family-sized units. In 2022 she voted against Mayor Breed's housing permitting referendum and in 2023 asked the city attorney to challenge SB 423, California's streamlined housing approval law. She supports 100% affordable projects but opposes upzoning and market-rate development.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://missionlocal.org/2026/02/sf-connie-chan-china-taiwan-nancy-pelosi-congress/', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Chan has voted against market-rate upzoning and blocked housing projects in her district, reflecting a neighborhood-preservation approach. She challenged SB 423 (state streamlined housing approval) and opposed Mayor Breed's permitting reform referendum in 2022, aligning with the progressive anti-displacement bloc rather than YIMBY positions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$In 2022 Chan co-sponsored the Union-At-Home ordinance, which enabled tenant associations in buildings with 5 or more units to collectively bargain with landlords. In 2025 she pledged to prevent homeless families from being evicted from city-funded housing. Her record consistently favors expanding tenant protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Chan is part of the progressive bloc on homelessness, favoring services and housing-first approaches. As budget chair she has protected homelessness services from cuts, and in 2025 pledged to prevent evictions of homeless families from city-funded housing. She has not supported criminalization-first approaches.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://missionlocal.org/2026/05/connie-chan-budget-deficit-2026/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Chan's approach to homelessness prioritizes services and shelter over enforcement sweeps. As Budget Committee chair she has defended homelessness services funding during fiscal constraints. Her 2025 pledge to prevent family evictions from city-funded housing reflects an outreach-and-shelter-first philosophy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://missionlocal.org/2026/05/connie-chan-budget-deficit-2026/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Chan opposed the 2022 recall of progressive DA Chesa Boudin and in 2023 opposed Mayor Breed's $27 million supplemental SFPD appropriation (though she supported the budgeted $63 million increase). This pattern indicates a balanced approach favoring community resources alongside a well-funded but not expanded police department.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Chan is a Hong Kong-born immigrant who arrived in Chinatown as a child and has made immigrant rights a defining issue of her career. She has been a consistent advocate for sanctuary city policies. Her congressional campaign specifically pledges to protect immigrant rights and she describes herself as representing a working-class immigrant constituency.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2026/03/pelosi-chinatown-forum-wiener-chan-and-taiwan/', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Chan is a vocal immigrant rights advocate who has pledged to protect immigrant communities throughout her supervisorial and congressional campaigns. She opposes mass deportation and ICE cooperation, framing immigrant rights as central to her political identity and district representation.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2026/03/pelosi-chinatown-forum-wiener-chan-and-taiwan/', 'https://missionlocal.org/2026/02/sf-connie-chan-china-taiwan-nancy-pelosi-congress/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chan is an immigrant who arrived in SF's Chinatown as a teenager and has consistently championed immigrant rights throughout her supervisorial tenure. She explicitly commits to protecting immigrant communities and describes her constituency as working-class immigrants. She pledges not to accept AIPAC money and opposes enforcement-focused immigration policy.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2026/03/pelosi-chinatown-forum-wiener-chan-and-taiwan/', 'https://missionlocal.org/2026/02/sf-connie-chan-china-taiwan-nancy-pelosi-congress/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Chan is skeptical of AI's sophistication and favors sector-specific regulation with a light-regulation lean for most uses. She stated: 'AI is really automation and algorithms, maybe on steroids,' and supports regulating AI differently across sectors rather than broadly. She favors fact-checking requirements on social media under Section 230 but does not favor heavy blanket AI restrictions.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-congress-connie-chan-saikat-chakrabarti-scott-wiener-tech-ai-crypto/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Chan supports amending Section 230 to impose fact-checking responsibilities on social media platforms, stating: 'If you are going to be in the business of publishing information, then you ought to also be in the business of fact-checking.' She favors platform accountability for misinformation with government-backed requirements.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-congress-connie-chan-saikat-chakrabarti-scott-wiener-tech-ai-crypto/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Chan explicitly pledges not to accept money from corporate PACs, AIPAC, the NRA, or lobbyists and executives from pharmaceutical, PG&E, fossil fuel, or tobacco companies. She has committed to taxing billionaires and rejecting corporate money. This positions her solidly in favor of strict campaign finance limits and public interest funding.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2026/05/connie-chan-labor-congress/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chan has pushed to increase the minimum wage multiple times as supervisor and supports the Overpaid CEO Act (Prop D), which would raise taxes on companies with high CEO-to-worker pay ratios by $250-300 million annually. She has pledged to tax billionaires and reject corporate money, reflecting a strongly progressive tax stance.$$,
        ARRAY['https://missionlocal.org/2026/05/connie-chan-budget-deficit-2026/', 'https://conniechansf.com/issues', 'https://missionlocal.org/2026/05/connie-chan-labor-congress/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Chan sponsored a resolution affirming San Francisco's commitment to protecting transgender, gender-expansive, and LGBTQIA+ youth and advocated that gender-affirming care should be covered by insurance. She has endorsed the Harvey Milk LGBTQ Democratic Club and has a consistent record of supporting civil rights protections for marginalized communities.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Chan has been endorsed by the Harvey Milk LGBTQ Democratic Club and sponsored resolutions protecting LGBTQIA+ youth and affirming gender-affirming care as healthcare. She represents a progressive district with strong LGBTQ+ community presence and has a consistent record of full support for LGBTQ+ rights.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://missionlocal.org/2024/08/district-1-candidates-bring-tourists-to-the-richmond/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Chan sponsored a resolution protecting transgender and gender-expansive youth in San Francisco and advocates for gender-affirming care as essential healthcare. Her endorsement by the Harvey Milk LGBTQ Democratic Club and progressive stance on trans rights reflects full inclusion for transgender individuals in all aspects of public life.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Chan's campaign website pledges to protect reproductive rights and she has been endorsed by progressive labor and community organizations with strongly pro-choice platforms. As a progressive San Francisco Democrat she is uniformly pro-choice and supports accessible abortion through all stages.$$,
        ARRAY['https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Chan's campaign pledges to expand healthcare access and her supervisorial work included partnering on the Richmond Area Multi-Services (RAMS) mental health facility expansion for culturally competent services. She supports the ACA and healthcare expansion but has not explicitly endorsed single-payer Medicare for All; her platform focuses on expanding coverage and lowering costs within existing frameworks.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chan's campaign explicitly refuses donations from fossil fuel company executives and pledges to address climate change through clean power. She is endorsed by labor organizations aligned with green energy transitions and represents a strongly climate-action district.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2026/05/connie-chan-labor-congress/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Chan refuses campaign donations from fossil fuel company executives and promotes clean power on her platform. As a progressive San Francisco Democrat she supports stopping new fossil fuel development and transitioning to renewable energy, though she has not authored specific fossil fuel legislation at the city level.$$,
        ARRAY['https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Chan supported reopening the Great Highway to car traffic in 2021 after its COVID-era pedestrian closure, a position that aligned with car-owning Richmond District constituents but opposed transit and cycling advocates. She is also a member of the SF County Transportation Authority and supports Muni investments including free fares. Her record reflects a mixed transportation approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Chan's support for reopening the Great Highway to cars in 2021 aligned her with auto-access priorities over environmental-pedestrian advocates. However, her overall record on city environmental matters is progressive and she opposes fossil fuel interests. The Great Highway vote suggests a context-dependent approach balancing constituency needs with environmental values.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$As Budget Committee chair, Chan has protected services funding including sanitation and community resources. In 2026 she stated 'It's enough cuts' when opposing further budget reductions that would have affected city services. Her approach emphasizes maintaining staffing and services rather than enforcement-led responses to cleanliness issues.$$,
        ARRAY['https://missionlocal.org/2026/05/connie-chan-budget-deficit-2026/', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Chan consistently supports managed, community-centered growth over market-led development. She blocked a 495-unit market-rate project, opposed housing permitting reform, and challenged state streamlined approval laws. She supports capital programs that allow residents to nominate community projects (Community Opportunity Fund) reflecting bottom-up development priorities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chan established the API Equity Fund in 2022 to stabilize API-serving small businesses through capital investment and supported the Community Opportunity Fund enabling neighborhood groups to nominate projects for funding. She emphasizes small business diversity and has been skeptical of corporate incentives, stating she favors 'breaking up monopolies' and supports small businesses and competition.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://missionlocal.org/2026/04/sf-congress-connie-chan-saikat-chakrabarti-scott-wiener-tech-ai-crypto/', 'https://missionlocal.org/2024/08/district-1-candidates-bring-tourists-to-the-richmond/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Chan opposed the 2022 recall of progressive DA Chesa Boudin and opposed Mayor Breed's $27 million supplemental SFPD appropriation in 2023. Her record reflects a reform-oriented criminal justice approach emphasizing community-based solutions and diversion over purely punitive enforcement expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://sfbos.archive.sf.gov/supervisor-chan-district-1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Chan's opposition to the DA Boudin recall and to supplemental SFPD appropriations, combined with her support for community investment programs, reflects a philosophy of redirecting incarceration spending into services. As budget chair she has protected social services funding as an alternative to incarceration-focused spending.$$,
        ARRAY['https://en.wikipedia.org/wiki/Connie_Chan_(politician)', 'https://missionlocal.org/2026/05/connie-chan-budget-deficit-2026/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Chan's campaign platform pledges to lower the cost of living and rebuild the middle class, with childcare affordability as a component. She is endorsed by SEIU 1021 and SF Labor Council, which prioritize affordable childcare. Her broader progressive economic platform supports significant childcare subsidies for working families.$$,
        ARRAY['https://conniechansf.com/issues', 'https://missionlocal.org/2024/08/district-1-candidates-bring-tourists-to-the-richmond/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Chan is a progressive Democrat who supports expanding voting access. She has been endorsed by progressive labor organizations and Democratic clubs that uniformly support expanding early voting, mail-in voting, and automatic registration. Her platform opposes voter ID restrictions.$$,
        ARRAY['https://conniechansf.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Chan is a member of the Free City College Oversight Committee and has advocated for free Muni passes for students and free City College tuition for all SF residents. She is endorsed by progressive labor and education organizations that uniformly oppose vouchers that divert public school funding to private institutions.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-chan-district-1', 'https://missionlocal.org/2026/03/pelosi-chinatown-forum-wiener-chan-and-taiwan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Connie Chan / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Chan has stated she advocates for the US to be 'an agent for peace and stability' as her guiding foreign policy principle. On the Taiwan issue she favors dialogue over military confrontation. She did not oppose weapons transfers to Taiwan. This pattern suggests support for diplomatic and security aid to Ukraine over aggressive escalation, consistent with mainstream Democratic positions.$$,
        ARRAY['https://missionlocal.org/2026/02/sf-connie-chan-china-taiwan-nancy-pelosi-congress/', 'https://missionlocal.org/2026/03/pelosi-chinatown-forum-wiener-chan-and-taiwan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chyanne Chen
-- ============================================================

-- ----- Chyanne Chen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chen voted against a December 2025 zoning reform bill that would have upzoned 60% of San Francisco, stating the legislation "applied a top-down framework that has little to do with housing affordability" and criticized doing policy "to our communities, not with our communities." Her campaign included affordable senior housing as a priority. Her vote reflects a community-process-first approach rather than opposition to housing supply per se, placing her in the middle of the scale.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Chen voted against a December 2025 citywide upzoning bill covering 60% of SF, citing concerns that the legislation was a top-down framework divorced from community input. Her stated quote — "This legislation is an example of the government doing things to our communities, not with our communities" — reflects a preference for community-process-driven density decisions over blanket market-led upzoning.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Chen stood alongside the full SF Board of Supervisors in January 2025 to jointly defend San Francisco's sanctuary city status against federal pressure. Her background as a Chinese Progressive Association organizer and first-generation immigrant advocate, combined with representing one of SF's most immigrant-dense districts (Excelsior/Outer Mission), makes sanctuary city defense a core pillar. SF's sanctuary ordinance prohibits city employees from assisting ICE with civil immigration enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/', 'https://sf.gov/information/sanctuary-city-ordinance']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Chen worked for the Chinese Progressive Association, an organization historically focused on immigrant rights and opposing deportations. Her District 11 constituency is heavily first-generation immigrant (Chinese and Latino). She stood with the full Board of Supervisors in January 2025 defending SF's sanctuary city ordinance, which prohibits city employees from cooperating with ICE civil immigration enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chen is a first-generation Chinese immigrant and former organizer with the Chinese Progressive Association, whose mission includes immigrant rights advocacy. She campaigned on expanding translation services for District 11 residents, a heavily immigrant district. She participated in the January 2025 sanctuary city defense rally alongside the full Board of Supervisors.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Chen explicitly included childcare subsidization as a campaign legislative priority. She is herself a working parent with two children in public schools and caring for elderly parents, and she emphasized the need for city-subsidized childcare in her campaign materials and district priorities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Chen listed public safety as a campaign priority but also emphasized community investment as the framework — prioritizing youth programs, parks, and services alongside safety improvements. Her District 11 neighbors cited dangerous speeding and pedestrian hazards as top concerns, and Chen's approach involves infrastructure investment. She has not taken a defund-police stance nor a maximize-enforcement stance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Chen serves as Vice-Chair of the Land Use and Transportation Committee and is a member of the SF County Transportation Authority. District 11 community members emphasized transit needs including paratransit for seniors in hilly terrain, safer pedestrian routes to schools, and traffic-calming measures. Chen's stated transportation priorities align with multimodal investment rather than car-centric approaches.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/', 'https://missionlocal.org/2024/09/district-11-candidates-whats-up-in-the-omi/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Chen's vote against the December 2025 upzoning bill was explicitly framed around community-controlled, process-driven development: "This legislation is an example of the government doing things to our communities, not with our communities." She supports investment in District 11 but prioritizes community input and anti-displacement protections, indicating a managed, community-centered approach to growth.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chen was a labor organizer with SEIU 1021 and the Chinese Progressive Association, both worker and community-centered organizations. Her economic development priorities focus on supporting small businesses (assistance with insurance, online presence, filling vacancies), maintaining nonprofit funding, and protecting community-serving programs during budget cuts rather than offering corporate tax incentives.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chen's stated budget priority is protecting nonprofit and community services funding amid the city's $867 million deficit. As a former SEIU 1021 labor organizer, her background strongly aligns with progressive tax policy. She has not stated a specific tax position on the record, but her labor organizing background and stated priorities of maintaining community investment support a progressive tax approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Chen's campaign emphasized community investment and affordable housing as core priorities. As a progressive supervisor with labor organizing roots, her approach to homelessness centers on services and housing provision. She listed protecting community programs and affordable senior housing as top priorities, indicating a services-first framework rather than enforcement-first.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Chen's community investment framework and progressive endorsements (Supervisors Myrna Melgar, former Supervisors Fewer and Yee) align with outreach- and shelter-first approaches to homelessness rather than enforcement-first sweeps. Her campaign priorities of protecting nonprofit funding and community services reflect this orientation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Chen listed parks and street improvements as a campaign priority, reflecting a services approach to maintaining public spaces. She has not made enforcement-first statements about street cleanliness. Her background as a community organizer and labor advocate suggests a services-investment orientation, but no specific votes or statements on sanitation enforcement have been documented.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2024/09/district-11-candidates-whats-up-in-the-omi/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Chen ran on a platform emphasizing affordable housing and protecting District 11 residents from displacement. Her district is heavily working-class and immigrant, and she received endorsements from progressive supervisors with strong tenant-protection records (Sandra Lee Fewer, Myrna Melgar). Her SEIU 1021 and Chinese Progressive Association background aligns with strong tenant protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Chen worked for the Chinese Progressive Association (CPA), which focuses on racial and economic justice for the working-class Chinese immigrant community in San Francisco. Her background as a SEIU 1021 labor organizer and her campaign's focus on protecting community-serving nonprofits and expanding translation services reflect a strong civil rights orientation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Chen's campaign emphasized public school investment and her own children attend SF public schools. Her labor organizing background with SEIU 1021 (which represents school district workers) and her community investment framework strongly oppose diverting public education funding to private institutions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2025/01/in-district-11-hope-and-needs-go-hand-in-hand-for-new-supervisor-chyanne-chen/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chyanne Chen / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f59c9fd-03f9-4652-bc4a-418bd8764a1f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Chen listed parks improvements and street safety as campaign priorities for District 11, and as Vice-Chair of the Land Use and Transportation Committee she has direct oversight of environmental and land-use decisions. Her community-investment orientation and progressive endorsement base align with strong local environmental protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chyanne_Chen', 'https://missionlocal.org/2024/09/district-11-candidates-whats-up-in-the-omi/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Chiu
-- ============================================================

-- ----- David Chiu / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Chiu co-authored the Reproductive FACT Act (AB 775, 2015) requiring health clinics to provide accurate reproductive health information including abortion access to patients; as City Attorney he has defended reproductive rights policies. He supports abortion access without restrictions through at least the second trimester but has not publicly called for public funding at all stages.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB775', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No direct evidence of a strong position on AI regulation. As City Attorney he has focused on consumer protection and federal overreach litigation. No Assembly bills on AI were found in his legislative record. Assigned a moderate/default value — likely to support basic safety standards given his tech-industry San Francisco constituency and consumer protection focus, but no specific AI legislation found.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)', 'https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$As a progressive Democrat from San Francisco, Chiu has consistently aligned with campaign finance reform positions. His authorship of the Public Banking Act (AB 857, 2019) reflects opposition to Wall Street's influence on public funds. No direct campaign finance bill was found in his record but his broader progressive orientation and San Francisco political background strongly suggest support for limiting corporate donations and dark money.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB857', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Chiu authored the Family Friendly Workplace Ordinance in San Francisco (2013), described as 'the first U.S. city to adopt such a policy,' enabling flexible work arrangements for caregiving including childcare; he also authored AB 943 (2019) enabling community colleges to provide emergency financial aid preventing student homelessness which includes childcare costs. These actions indicate support for expanded childcare subsidies and assistance for working families.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$As City Attorney, Chiu has pursued enforcement actions targeting problematic properties and businesses in the Tenderloin (2026) while also bringing quality-of-life lawsuits; he sued to shut down a corner store selling methamphetamine (May 2026) and has pursued nuisance abatement. This reflects a balanced approach — maintaining sanitation standards through law enforcement while not primarily relying on criminalization of residents.$$,
        ARRAY['https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Chiu authored AB 979 (2020) mandating racial and ethnic diversity on corporate boards; championed anti-bullying training (AB 2291, 2018); authored the transgender name-on-records bill (2020); and led the $156.5M API Equity Budget as API Legislative Caucus Chair. These bills directly strengthen civil rights enforcement and address systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB979', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chiu authored AB 525 (2021) launching California's offshore wind industry and establishing planning goals for 2030 and 2045; authored AB 1236 (2015) streamlining EV charging station permitting; and authored AB 1096 (2015) modernizing e-bike regulations to promote clean transportation. These bills demonstrate active investment in clean energy transition and phasing out fossil fuel dependence.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB525', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB1236', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Chiu authored AB 450 (Immigrant Worker Protection Act, 2017) prohibiting employers from cooperating with ICE raids without judicial warrants; authored AB 291 (Immigrant Tenant Protection Act, 2017) protecting tenants from deportation threats; as City Attorney he has opposed HUD proposals targeting immigrant families (April 2026). These actions indicate he opposes deportation except for those who commit serious violent crimes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB450', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB291', 'https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chiu authored the Public Banking Act (AB 857, 2019) enabling locally-controlled public banks to reinvest tax dollars in communities rather than Wall Street. He authored the Immigrant Business Inclusion Act (AB 2184) enabling business licensing regardless of immigration status. These actions suggest targeted incentives with community benefit requirements rather than blanket corporate subsidies.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB857', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Chiu authored AB 525 (2021) launching California's offshore wind industry with planning goals for renewable energy capacity in 2030 and 2045; authored AB 1096 (e-bikes) and AB 1236 (EV charging) in 2015 promoting clean transportation alternatives. His full legislative record reflects consistent support for transitioning away from fossil fuels, suggesting he would stop issuing new drilling permits while the transition proceeds.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB525', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB1236', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Chiu authored AB 1487 (Bay Area Housing Finance Authority, 2019) to fund regional housing; AB 2923 (2017) allowing BART to set density zoning near transit stations; and AB 1763 (2019) removing density caps for 100% affordable housing near transit. He also authored AB 2162 (2017) streamlining supportive housing approvals. This consistent pattern of removing regulatory barriers to housing production indicates support for streamlined permitting and active development encouragement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1487', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2923', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1763']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Chiu has supported healthcare access legislation including the Reproductive FACT Act ensuring patients know about healthcare programs. His progressive San Francisco political background and consistent record of expanding access to public programs suggests support for a public option alongside private insurance. No specific single-payer bill was found in his record.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB775']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Chiu authored AB 74 (2017) creating the Housing for Healthy California Program providing rental subsidies for chronically homeless individuals; AB 2162 (2017) streamlining supportive housing production for homeless populations; AB 2377 (2020) preventing closure of adult residential facilities housing vulnerable populations. These multiple bills focused on permanent supportive housing indicate a strong investment in housing-first approaches and shelter capacity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB74', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2162', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As City Attorney, Chiu has pursued both supportive housing investments and enforcement actions — he pursued quality-of-life lawsuits in the Tenderloin (2025-2026) and actions against drug-selling establishments while his legislative record (AB 74, AB 2162) emphasizes permanent housing. This pattern is consistent with expanding shelter capacity and services as the primary strategy while using enforcement after services are offered.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB74', 'https://www.sf.gov/cityattorney', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chiu authored the landmark AB 1482 (Tenant Protection Act of 2019) capping rent increases at 5% plus CPI and establishing just-cause eviction protections statewide; authored AB 3088 (COVID-19 Tenant Relief Act, 2020) and AB 832 (2021) extending eviction protections. He also created the Immigrant Tenant Protection Act and authored Ellis Act protections. These actions demonstrate commitment to building affordable housing and expanding rental assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1482', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202020210AB3088', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chiu authored the Immigrant Worker Protection Act (AB 450, 2017) protecting workers from ICE raids, the Immigrant Tenant Protection Act (AB 291, 2017), and the Immigrant Business Inclusion Act (AB 2184) enabling business licensing regardless of immigration status. As City Attorney he has opposed HUD proposals targeting immigrant families (2026) and actively defended San Francisco's sanctuary city policies. This record reflects support for significantly increasing immigration pathways and creating easy citizenship routes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB450', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB291', 'https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Chiu authored AB 2138 (2017) — fair chance licensing reform reducing licensing barriers for those with older criminal convictions — and AB 41 (rape kit tracking) and AB 3118 (rape kit audit, 2018) focused on addressing crime rather than expanding incarceration. His criminal justice record emphasizes rehabilitation over incarceration, consistent with reducing jail population through diversion and bail reform rather than building new capacity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2138', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$As City Attorney, Chiu has filed multiple lawsuits on behalf of workers (wage theft, May 2026) and immigrant families (opposing HUD proposal, April 2026); his Assembly record includes the Public Banking Act and consumer protection legislation. These actions reflect a commitment to expanding access to legal remedies for disadvantaged populations.$$,
        ARRAY['https://www.sf.gov/cityattorney', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Chiu's criminal justice record in the Assembly — including fair chance licensing (AB 2138) emphasizing rehabilitation and reduced collateral consequences — indicates support for pretrial diversion and bail reform over cash bail systems. No specific bail bill was found, but his consistent orientation toward reducing barriers for those with criminal records suggests he opposes cash bail requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2138', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Chiu authored AB 2138 (2017) enabling occupational licensing for people with older convictions; authored rape kit tracking (AB 41) and rape kit audit (AB 3118) prioritizing crime victim justice over mass incarceration. As City Attorney he brought consumer and worker protection lawsuits rather than focusing on criminal prosecution. This record reflects a reform-oriented criminal justice approach emphasizing accountability, rehabilitation, and victim services.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2138', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$As City Attorney, Chiu has filed lawsuits against Trump over DOGE/mass federal employee firings (April 2025), anti-terrorism funding cuts (June 2025), and National Guard deployment threats (October 2025) — all asserting limits on executive power. His affirmative litigation strategy directly challenges executive overreach, indicating he believes courts should check government deference when constitutional limits are exceeded.$$,
        ARRAY['https://www.sf.gov/cityattorney', 'https://sfstandard.com/tag/david-chiu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$As City Attorney, Chiu filed suit against the Trump administration on multiple constitutional grounds — sanctuary city defunding, DOGE, federal funding withdrawals — asserting broad constitutional rights for cities and individuals. His litigation approach uses living constitutionalism to protect immigrant rights, worker protections, and local government autonomy, consistent with a progressive interpretive framework.$$,
        ARRAY['https://www.sf.gov/cityattorney', 'https://sfstandard.com/tag/david-chiu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$No direct bills specifically on police accountability were found in Chiu's legislative record, but his consistent civil rights legislation (corporate diversity mandates, immigrant protections, fair chance licensing) indicates support for ensuring police accountability. His City Attorney role involves oversight of city legal matters including police department legal exposure. Insufficient specific evidence — assigning based on legislative pattern.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$As City Attorney (not DA), Chiu focuses on civil affirmative litigation and city representation rather than criminal prosecution. His office has pursued wage theft lawsuits, drug enforcement actions (Tenderloin corner store), and consumer protection cases. This mixed portfolio — worker protection alongside street-level drug enforcement — suggests balanced prosecution priorities that address both economic crimes and public safety.$$,
        ARRAY['https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Chiu's office has published press releases on all major lawsuits and legal actions. His Assembly record includes for-profit college earnings and debt transparency (AB 1340, 2019) and annual board diversity reporting requirements (AB 979). His public banking bill (AB 857) included transparency requirements for public financial institutions. These actions reflect strong support for government and institutional transparency.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB979', 'https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$While Assemblymember, Chiu created San Francisco's single-use plastic water bottle ban on public property with required public water taps (2014); established the Healthy Nail Salon Recognition Program phasing out toxic chemicals (2010); mandated pharmaceutical take-back programs; and authored reusable container authorization (2019). These actions reflect strong protection of parks and local environment with full environmental review requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As City Attorney, Chiu actively defends San Francisco's sanctuary city policies — he has led coalitions opposing HUD proposals targeting immigrant families (April 2026) and publicly stated the city would sue if Trump deployed the National Guard (October 2025). His authored AB 450 bars employers from cooperating with ICE without judicial warrants. These actions reflect the strongest sanctuary city position: refusing all ICE cooperation and protecting immigration status information.$$,
        ARRAY['https://www.sf.gov/cityattorney', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB450', 'https://sfstandard.com/tag/david-chiu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Chiu authored AB 74 (2017) Housing for Healthy California Program specifically designed for Medi-Cal beneficiaries who are chronically homeless — using Medicaid funding mechanisms to house homeless individuals. This directly expands Medi-Cal/Medicaid coverage and demonstrates strong support for expanding Medicaid significantly. No direct Medicare expansion bill found but his overall progressive healthcare access record indicates support for lowering the Medicare age.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB74', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As City Attorney, Chiu has pursued both quality-of-life enforcement (drug enforcement, Tenderloin nuisance abatement) and worker protection lawsuits. He filed suit against a meth-selling corner store (May 2026) and dismissed quality-of-life lawsuits when resolved. His Assembly record includes rape kit tracking bills (AB 41, AB 3118) focused on improving crime investigation. This pattern reflects maintaining current police staffing while adding targeted interventions.$$,
        ARRAY['https://www.sf.gov/cityattorney', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a progressive San Francisco Democrat, Chiu has operated under California's independent redistricting commission system (established by Prop 11/2008 and Prop 20/2010). No bills directly authored on redistricting were found, but his consistent support for democratic participation (student voter registration AB 2455) and civil rights suggests support for independent redistricting commissions with equal party representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB2455', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No specific religious freedom legislation was found in Chiu's record. His civil rights work (LGBTQ+ protections, corporate diversity) is balanced against San Francisco's strong separation of church and state tradition. His authorship of the Reproductive FACT Act (AB 775), which applied to both licensed and unlicensed facilities including faith-based crisis pregnancy centers, suggests he values civil rights compliance over religious exemptions in public-facing services.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB775', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Chiu authored AB 1482 (Tenant Protection Act of 2019) establishing the first statewide rent cap in California (5% + CPI max annual increase) with just-cause eviction protections; authored the COVID-19 Tenant Relief Act (AB 3088, 2020) halting pandemic evictions; extended eviction protections via AB 832 (2021); and authored both the Immigrant Tenant Protection Act and tenant blacklisting protections. This is one of the most extensive tenant protection legislative records in California history.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1482', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202020210AB3088', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Chiu authored AB 2923 (2017) allowing BART to override local zoning near transit stations to enable density; AB 1763 (2019) removing density caps entirely for 100% affordable projects near transit; AB 2162 (2017) making supportive housing a 'use by right' in multifamily zones; and legalized in-law units citywide in San Francisco (2014). These bills broadly upzone to allow multifamily by right and streamline approvals.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2923', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1763', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2162']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Chiu authored legislation protecting parental rights for LGBTQ+ couples using assisted reproduction and authored the transgender student records bill (2020) ensuring chosen names on official records. His overall legislative record reflects full equality for LGBTQ+ individuals without exceptions, consistent with requiring all states to recognize same-sex marriages with full federal benefits.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$No voucher legislation was found in Chiu's record. As a progressive San Francisco Democrat representing a strongly public-school-oriented district, he has consistently supported public institutions. His student voter registration bill (AB 2455) focused on public colleges and universities. His Assembly record contains no support for private school funding, and his broader policy orientation opposes diverting taxpayer funds to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB2455', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$No direct Social Security legislation was found in Chiu's record, as this is a federal program and he served in the state legislature. However, his overall pattern of expanding public programs, protecting workers (wage theft lawsuits, labor protections), and opposing private-sector control of public funds (Public Banking Act) strongly suggests support for modestly increasing Social Security benefits while raising taxes on higher earners.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB857', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$As City Attorney, Chiu filed a lawsuit challenging Trump's tariff policy as exceeding executive authority (referenced in SF Standard coverage, 2025). This legal challenge is based on constitutional limits of executive power rather than an ideological position on free trade vs. protectionism. He supports using tariffs selectively for legitimate policy goals but contests unilateral executive overreach on trade.$$,
        ARRAY['https://sfstandard.com/tag/david-chiu/', 'https://www.sf.gov/cityattorney']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chiu authored the Bay Area Housing Finance Authority (AB 1487, 2019) enabling regional parcel taxes, gross receipts taxes on businesses, and commercial linkage fees specifically for affordable housing funding. His Public Banking Act (AB 857) sought to reinvest public tax dollars in communities. These actions reflect support for modestly increasing taxes on businesses and higher earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1487', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB857', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Chiu authored legislation ensuring transgender students' chosen names appeared on official school records (2020) and authored LGBTQ+ parental rights protections. His consistent record of full LGBTQ+ equality in legislation, with no qualifications or exceptions, indicates support for allowing transgender athletes to compete on teams matching their gender identity after completing documentation of their transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Chiu authored AB 2923 (2017) overriding local zoning to enable dense housing near BART transit stations; authorized AB 1236 (2015) streamlining EV charging permitting; and modernized e-bike regulations (AB 1096, 2015). As SF Board of Supervisors President he created the city's 'Dig Once' fiber-optic conduit ordinance (2014) requiring utility integration during street repairs. This record reflects equal investment in roads and multimodal options.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180AB2923', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB1236', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        '24e9212c-b011-422a-865c-093e35050901',
        $$No specific Ukraine legislation was found given Chiu's state/city role. As a progressive San Francisco Democrat who has actively sued to protect federal funding from executive overreach, he would be expected to support continuing current levels of military and economic aid. However, foreign policy is outside his direct purview as City Attorney. Assigning based on political orientation with low confidence — this topic should be noted as inference.$$,
        ARRAY['https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Chiu / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Chiu authored AB 2455 (2015) establishing automatic voter registration at California public college enrollment — described as 'preliminary measures towards an automatic voter registration system.' He also authored LGBTQ+ inclusive data collection and anti-discrimination measures throughout his tenure. These actions indicate support for expanding voting access including early voting and mail-in voting for all voters.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB2455', 'https://en.wikipedia.org/wiki/David_Chiu_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Carmen Chu
-- ============================================================

-- ----- Carmen Chu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$When California resumed same-sex marriages on June 28, 2013, Chu kept the SF Assessor-Recorder's office open that first weekend to issue marriage licenses — the only county recorder's office in California to do so statewide. Her office recorded 479 marriage licenses that weekend. She also preserved the 2004 invalidated same-sex marriage licenses for archival at the SF Public Library rather than destroying them.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carmen_Chu', 'https://www.sf.gov/profile--carmen-chu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Chu's record is mixed on immigration. As City Administrator she oversees the Office of Immigrant Affairs and has not moved to weaken SF's sanctuary city protections. However, as a moderate BOS member in 2009 she was part of the bloc of supervisors who opposed expanding sanctuary city ordinance protections for juvenile offenders, a notable departure from the progressive majority. Her parents were Hong Kong immigrants and she grew up in a family that experienced immigration barriers firsthand.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carmen_Chu', 'https://www.sf.gov/profile--carmen-chu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chu has consistently focused on supporting small business development throughout her career: as a District 4 supervisor she streamlined city contracting to create micro-contracting opportunities for small businesses, and as City Administrator she launched a Government Operations Contracting Reform initiative to modernize city purchasing. Her approach favors targeted procurement reform and neighborhood commercial corridor investment rather than large corporate incentives.$$,
        ARRAY['https://www.sf.gov/profile--carmen-chu/', 'https://en.wikipedia.org/wiki/Carmen_Chu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Assessor-Recorder (2013–2021) Chu aggressively enforced property tax compliance, identifying nearly $40 million in underreported transfer tax revenue through audit programs. As Budget and Finance Committee chair (2011–2013) she led the closure of a $380 million General Fund deficit while preserving services — demonstrating a preference for fiscal discipline over either dramatic tax increases or cuts. She increased construction value enrollments from under $500M to over $11B, significantly growing tax revenue without raising rates.$$,
        ARRAY['https://www.sf.gov/profile--carmen-chu/', 'https://en.wikipedia.org/wiki/Carmen_Chu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As District 4 Supervisor representing the Sunset neighborhood, Chu sponsored tenant protections for domestic violence victims and directed funding toward commercial corridor revitalization. She was known as a moderate who balanced neighborhood character concerns typical of the Sunset with incremental housing investments. No record of opposing or championing major upzoning or large-scale affordable housing production bills during her BOS tenure.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carmen_Chu', 'https://www.sf.gov/profile--carmen-chu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$As District 4 Supervisor, Chu collaborated on the Sunset Reservoir municipal solar project, described by Wikipedia as 'the largest municipal solar project in the country at the time.' She also directed funding toward parks, playgrounds, and neighborhood green infrastructure improvements in the Sunset District. This record suggests a supportive stance toward local environmental projects.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carmen_Chu', 'https://www.sf.gov/profile--carmen-chu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmen Chu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f82edba8-5f6b-4c00-af78-b782426f05a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chu's climate record is limited to local infrastructure actions. As District 4 Supervisor she collaborated on the Sunset Reservoir solar project. As City Administrator she has overseen city operations without a documented record of advocacy for stronger climate regulations or fossil fuel restrictions. Her profile reflects a government operations administrator rather than a climate policy champion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Carmen_Chu', 'https://www.sf.gov/profile--carmen-chu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- José Cisneros
-- ============================================================

-- ----- José Cisneros / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cisneros launched multiple community-centered economic programs: the SF Lends initiative connects certified Local Business Enterprises (especially underrepresented owners) to affordable loans prioritizing community benefit, the First Year Free program waived first-year fees for new small businesses, and Proposition M (2024) delivered $10 million in annual fee relief for small businesses. His economic development approach is explicitly centered on small and local businesses and underrepresented communities rather than large corporate attraction.$$,
        ARRAY['https://sftreasurer.org/community/sf-lends', 'https://sftreasurer.org/announcing-leadership-changes-office-treasurer-tax-collector', 'https://sfgov.org/ofe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Bank On San Francisco, founded by Cisneros, explicitly serves people without a social security number or California ID — the program's materials state 'It doesn't matter how much money you have, if you don't have a social security number or California ID.' The Office of Financial Empowerment under Cisneros created a dedicated roadmap with the Office of Civic Engagement and Immigrant Affairs to help recently arrived immigrants establish secure financial foundations. This represents active city-resource use to support undocumented and immigrant residents.$$,
        ARRAY['https://sfgov.org/ofe/find-bank-account', 'https://sfgov.org/ofe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cisneros has directed city financial resources specifically toward immigrant inclusion: Bank On SF opens accounts for people without SSNs, OFE partnered with the Office of Civic Engagement and Immigrant Affairs on a financial inclusion roadmap for newcomers, and Working Families Credit assistance targets low-income families including immigrant households. His programs reflect a welcoming approach that extends city services to all residents regardless of immigration status.$$,
        ARRAY['https://sfgov.org/ofe/find-bank-account', 'https://sfgov.org/ofe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cisneros championed the Working Families Credit in 2005, which put money 'directly into their hands' for low-income families via Earned Income Tax Credit matching. His 2024 Proposition M reform provided small business fee relief while maintaining the Homelessness Gross Receipts Tax and Overpaid Executive Tax structures. His approach consistently supports tax credits for working families and targeted relief for small businesses, consistent with modestly progressive taxation rather than broad tax cuts or radical redistribution.$$,
        ARRAY['https://sftreasurer.org/about-us/news-and-updates/news-releases', 'https://sfgov.org/ofe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cisneros launched the Be The Jury program to compensate low-to-moderate-income jurors $100 daily to increase racial and economic diversity on juries, securing $650K in state funding. The Financial Justice Project waived $33 million in criminal justice debt disproportionately burdening communities of color, cleared 88,000 driver's license holds, and eliminated administrative fees from the criminal legal system. Cisneros also serves on the board of the Alice B. Toklas LGBT Democratic Club, an LGBTQ civil rights organization.$$,
        ARRAY['https://sftreasurer.org/about-us/news-and-updates/news-releases', 'https://sfgov.org/financialjustice/', 'https://en.wikipedia.org/wiki/Jos%C3%A9_Cisneros']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$The San Francisco Treasury investment policy under Cisneros explicitly discourages investments in entities that finance 'the Dakota Access Pipeline or, as determined by the Treasurer, similar pipeline projects.' The investment policy also discourages entities manufacturing tobacco, firearms, or nuclear weapons and encourages environmentally sound practices. This reflects a deliberate divestment from fossil fuel infrastructure embedded in the city's official investment framework.$$,
        ARRAY['https://sftreasurer.org/banking-investments/investments']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cisneros embedded climate-conscious criteria into San Francisco's investment policy, discouraging investment in Dakota Access Pipeline and similar fossil fuel infrastructure projects. The city's socially responsible banking RFP under Cisneros required banks to demonstrate 'safe and environmentally sound practices' and weighted social responsibility at up to 33% of evaluation criteria for city banking contracts. These structural policies reflect active climate-aligned governance rather than market neutrality.$$,
        ARRAY['https://sftreasurer.org/banking-investments/investments', 'https://sftreasurer.org/banking-investments/socially-responsible-banking']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$The Treasurer's Office under Cisneros administers the Homelessness Gross Receipts Tax, a business tax levy dedicated to homeless services — a supply-side revenue tool funding housing and services. Cisneros's office also expanded the Empty Homes Tax to address housing availability and administered the Commercial Vacancy Tax. The 2024 Proposition M business tax reform maintained the Homelessness Gross Receipts Tax structure while providing targeted small business relief, indicating continued commitment to funding homelessness services.$$,
        ARRAY['https://sftreasurer.org/business/taxes-fees/homelessness-gross-receipts-tax-hgr-0', 'https://sftreasurer.org/announcing-leadership-changes-office-treasurer-tax-collector']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Cisneros's Financial Justice Project reduced tow and booting costs by over 50% for low-income people, created payment plans for parking citations, and cleared 88,000 driver's license holds — all policies that reduce financial punishment cascades that push people toward homelessness. The Office of Financial Empowerment's guaranteed income work explicitly frames cash assistance as 'accessible and dignified' and 'effective at moving individuals and families out of poverty.' His approach is services- and outreach-oriented rather than enforcement-centered.$$,
        ARRAY['https://sfgov.org/financialjustice/', 'https://sftreasurer.org/community/guaranteed-income']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cisneros administered the Empty Homes Tax and Commercial Vacancy Tax as tools to increase housing availability. His municipal banking feasibility task force included affordable housing experts and the Mayor's Office of Housing and Community Development, exploring how city banking could support affordable development. The city's investment policy under Cisneros explicitly encourages investment in entities involved in affordable housing development and responsible mortgage servicing.$$,
        ARRAY['https://sftreasurer.org/banking-investments/investments', 'https://sftreasurer.org/banking-investments/municipal-banking-feasibility-task-force']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Cisneros provided a $10 monthly commissary allowance for incarcerated individuals to purchase essential hygiene items, reflecting a dignity-centered approach to incarceration. The Financial Justice Project eliminated criminal administrative fees statewide, removed $33 million in criminal justice debt, and aligned with California's effort to end fee collection from criminal legal system participants — consistent with reducing the financial burden and collateral consequences of incarceration rather than expanding jail capacity.$$,
        ARRAY['https://sftreasurer.org/about-us/news-and-updates/news-releases', 'https://sfgov.org/financialjustice/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$The Financial Justice Project under Cisneros waived $33 million in criminal justice debt, cleared 88,000 driver's license holds for missed traffic court, and eliminated administrative fees charged to people involved in the criminal legal system — a reform approach aimed at reducing financial punishment's role in criminal justice. The Be The Jury program increased racial and economic diversity on juries by compensating low-income jurors, addressing systemic barriers in jury composition.$$,
        ARRAY['https://sfgov.org/financialjustice/', 'https://sftreasurer.org/about-us/news-and-updates/news-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Cisneros's Kindergarten to College program automatically opens college savings accounts for every child entering kindergarten in San Francisco public schools, seeded with $50 in public funds and expanded with private matching up to $100. Cisneros stated: 'We started K2C so that every student in our public schools would know that they have a future worth saving for.' While not a direct childcare subsidy, it reflects a strong belief in public investment in children's economic futures from the earliest ages.$$,
        ARRAY['https://sfgov.org/k2c']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$The Kindergarten to College program is explicitly designed for 'every child entering kindergarten in San Francisco's public schools' — it is a public school-only program. There is no evidence Cisneros has supported school vouchers; all financial empowerment programs for children are channeled through public institutions. His OFE collaborates with SFUSD (public schools), not private or charter institutions.$$,
        ARRAY['https://sfgov.org/k2c']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- José Cisneros / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94035c6d-d6b2-4223-bdeb-e93e2ec26198',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$In 2016, Cisneros suspended Wells Fargo as San Francisco's banking partner citing 'predatory and potentially criminal actions against consumers' — an action that used the city's financial leverage against corporate misconduct. He later praised regulatory penalties against Bank of America for unauthorized account openings. His socially responsible banking RFP required banks to disclose predatory practices history and weighted community reinvestment, reflecting a belief that financial institutions should be held accountable to public interest standards.$$,
        ARRAY['https://sftreasurer.org/about-us/news-and-updates/news-releases', 'https://sftreasurer.org/banking-investments/socially-responsible-banking']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Matt Dorsey
-- ============================================================

-- ----- Matt Dorsey / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Dorsey is openly gay and worked on marriage equality cases for 14 years at the San Francisco City Attorney's office. His SF.gov profile explicitly notes he 'worked to support groundbreaking cases around marriage equality.' He has been a consistent and prominent advocate for full LGBTQ equality throughout his public career.$$,
        ARRAY['https://www.sf.gov/profile--matt-dorsey/', 'https://sfbos.archive.sf.gov/supervisor-dorsey-district-6', 'https://en.wikipedia.org/wiki/Matt_Dorsey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Dorsey spent 14 years at the SF City Attorney's Office working on 'marriage equality, education access, public health, tenants rights, and worker protections' per his official profile. As supervisor he continued advocating for LGBTQ civil rights and is the only openly HIV-positive member of the Board. His record reflects a strong but not maximalist civil rights posture.$$,
        ARRAY['https://www.sf.gov/profile--matt-dorsey/', 'https://sfbos.archive.sf.gov/supervisor-dorsey-district-6']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$As an openly gay supervisor who worked on LGBTQ equality cases at the City Attorney's office, Dorsey's voting record and public statements reflect consistent support for transgender rights. No evidence of any opposition to transgender inclusion; his broader LGBTQ advocacy record indicates support for transgender athletes competing on teams matching their gender identity, consistent with his progressive-to-moderate LGBTQ stance.$$,
        ARRAY['https://www.sf.gov/profile--matt-dorsey/', 'https://en.wikipedia.org/wiki/Matt_Dorsey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Dorsey has actively opposed Housing First policies, introduced legislation to ban city funding for supportive housing that is not drug-free, and imposed drug-free lease conditions on transitional age youth housing. He characterized Housing First as relying on 'tired shibboleths of the drug-decriminalization fringe' and proposed mandatory detoxification programs for drug users, reflecting a clear enforcement-over-services approach to homelessness.$$,
        ARRAY['https://48hills.org/2025/10/dorsey-wants-to-block-city-funding-for-supportive-housing-that-isnt-drug-free/', 'https://48hills.org/2025/11/dorsey-pushes-an-end-to-housing-first/', 'https://48hills.org/2024/12/supes-approve-tay-housing-but-dorsey-makes-it-easier-to-evict-the-vulnerable-residents/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Dorsey's primary homelessness response strategy centers on enforcement, mandatory treatment, and drug-free conditions on housing. He redirected wellness center funding toward jail-based treatment programs and stated it 'makes little sense to fund and staff limited services for voluntary drop-ins by drug users.' His harm reduction measure, passed 3-0 out of committee in April 2025, replaced language away from evidence-based approaches toward abstinence-first frameworks despite widespread medical opposition.$$,
        ARRAY['https://48hills.org/2025/04/dorsey-measure-that-undermines-harm-reduction-moves-forward/', 'https://48hills.org/2023/08/dorsey-attack-on-wellness-center-signals-larger-issues-in-sfs-new-war-on-drugs/', 'https://48hills.org/2025/11/dorsey-pushes-an-end-to-housing-first/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Dorsey states he supports 'new housing at all levels to meet growing demand' and emphasized meeting state Regional Housing Needs Allocation targets. However, he has imposed drug-free lease conditions on affordable housing projects and opposed Costa-Hawkins repeal, framing tenant protections as potential blockers to new housing construction. His record reflects a pro-supply position tempered by enforcement-oriented conditions on publicly-funded units.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-dorsey-district-6', 'https://48hills.org/2022/10/matt-dorseys-treasure-island-problem/', 'https://48hills.org/2024/06/a-truly-bizarre-debate-on-rent-control-at-the-board-of-supes/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Dorsey sponsored legislation to guarantee funding for 2,300 SFPD officers through a city charter mechanism, with an estimated cost of up to $300 million annually. He previously served as SFPD communications director and chairs the Board's Public Safety and Neighborhood Services Committee. He described opponents of his police staffing measure as an 'obstructionist Board of Supervisors majority,' reflecting a strong pro-enforcement and pro-police-funding stance.$$,
        ARRAY['https://48hills.org/2023/12/breed-announces-budget-cuts-as-dorsey-plays-the-cops-tax-card-in-campaign/', 'https://48hills.org/2023/11/who-should-pay-for-more-cops-plus-high-speed-police-chases/', 'https://sfbos.archive.sf.gov/supervisor-dorsey-district-6']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Dorsey advocated for 'mass-arrests of drug users' in South of Market with mandatory detoxification and treatment programs, directing wellness center funding toward jail-based treatment instead of community services. He framed incarceration as the appropriate mechanism for connecting drug users to treatment, preferring jail-based approaches over voluntary community programs.$$,
        ARRAY['https://48hills.org/2023/08/dorsey-attack-on-wellness-center-signals-larger-issues-in-sfs-new-war-on-drugs/', 'https://en.wikipedia.org/wiki/Matt_Dorsey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Dorsey consistently favors enforcement-first approaches to criminal justice, including mandatory arrest of drug users, opposition to harm reduction models, and support for high police staffing. Public Defender Mano Raju characterized his approach as 'politically motivated, War-on-Drugs tactics that ignore decades of research.' He co-sponsored the April 2025 harm reduction measure that shifted city policy away from evidence-based public health approaches.$$,
        ARRAY['https://48hills.org/2023/08/dorsey-attack-on-wellness-center-signals-larger-issues-in-sfs-new-war-on-drugs/', 'https://48hills.org/2025/04/dorsey-measure-that-undermines-harm-reduction-moves-forward/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Dorsey blocked the Board's sanctuary city resolution by refusing to grant unanimous consent in March 2023, preventing its passage (it required all 11 supervisors). He simultaneously proposed an ordinance allowing the city to contact ICE and seek deportation of individuals arrested for selling fentanyl. Ten of eleven supervisors opposed his approach, with Supervisor Safai calling it 'among the most misguided pieces of legislation' in six years on the board.$$,
        ARRAY['https://48hills.org/2023/03/supes-fail-by-one-vote-to-approve-sanctuary-city-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Dorsey proposed a specific ordinance to contact ICE and seek deportation of individuals arrested for selling fentanyl, arguing that removing drug dealers would push users toward heroin which he claimed is less deadly. He also stated that the sanctuary ordinance could 'make exception for crimes that shock the conscience.' This represents a targeted rather than comprehensive deportation stance — focused on drug dealers, not all undocumented immigrants.$$,
        ARRAY['https://48hills.org/2023/03/supes-fail-by-one-vote-to-approve-sanctuary-city-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Dorsey's immigration record is primarily defined by blocking the sanctuary city resolution and seeking ICE referrals for fentanyl dealers. While his position is not about restricting all immigration, his willingness to carve out exceptions to sanctuary protections for drug-related offenses and his support for ICE cooperation for that category of offense places him toward the enforcement end of the spectrum on local immigration policy.$$,
        ARRAY['https://48hills.org/2023/03/supes-fail-by-one-vote-to-approve-sanctuary-city-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Dorsey opposed the Justice for Renters Act (which would have repealed Costa-Hawkins and enabled local rent control expansion), arguing alongside Supervisor Stefani that tenant protections could discourage new housing development. He framed rent control as a 'Nimby plot to block new housing,' reflecting a pro-landlord, pro-supply, anti-rent-control position. He has not supported strengthening existing tenant protections.$$,
        ARRAY['https://48hills.org/2024/06/a-truly-bizarre-debate-on-rent-control-at-the-board-of-supes/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Dorsey explicitly supports 'new housing at all levels to meet growing demand' and emphasized meeting state Regional Housing Needs Allocation targets of 82,000 units over eight years. He has been a consistent advocate for new housing development in his district. However, the record does not contain specific votes on upzoning or zoning reform measures that would place him clearly at one end of the spectrum.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-dorsey-district-6', 'https://48hills.org/2022/10/matt-dorseys-treasure-island-problem/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$As President of the Treasure Island Mobility Management Agency and member of the SF County Transportation Authority, Dorsey has been engaged in major mixed-use development planning. His stated commitment to meeting housing targets and supporting housing at all affordability levels suggests a pro-development stance, though he has focused enforcement conditions on publicly-funded affordable units. His position favors growth but with conditions, placing him in the moderate center.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-dorsey-district-6', 'https://48hills.org/2022/10/matt-dorseys-treasure-island-problem/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Dorsey's approach to street conditions in the Tenderloin and SOMA aligns with enforcement — he sought mass arrests of drug users in South of Market and redirected funding from voluntary drop-in services toward jail-based treatment. His housing-drug-free legislation and anti-harm-reduction measures reflect a consistent preference for enforcement mechanisms over outreach-based approaches to street conditions.$$,
        ARRAY['https://48hills.org/2023/08/dorsey-attack-on-wellness-center-signals-larger-issues-in-sfs-new-war-on-drugs/', 'https://en.wikipedia.org/wiki/Matt_Dorsey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Dorsey introduced legislation to remove private enforcement rights from SF's 2019 surveillance technology oversight ordinance, describing the oversight law as 'an onerous mess' and claiming it encouraged 'baseless but costly lawsuits.' He sought to limit enforcement of surveillance rules to the DA and city attorney only, eliminating citizen suit rights. This reflects a preference for reducing public accountability mechanisms over protecting civil liberties from government surveillance.$$,
        ARRAY['https://48hills.org/2025/10/a-move-to-undermine-sfs-law-that-controls-police-surveillance/', 'https://48hills.org/2025/11/dorsey-pushes-an-end-to-housing-first/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Dorsey / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('68845df3-7103-45d9-8429-7ef51ee6ada3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Dorsey serves as President of the Treasure Island Mobility Management Agency and is a member of the SF County Transportation Authority, reflecting engagement in multimodal transportation planning including the Treasure Island toll and transit project. He initially opposed the Treasure Island toll as 'regressive' but acknowledged its potential necessity for infrastructure funding. No evidence of strong ideological positions on transit vs. car-centric investment.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-dorsey-district-6', 'https://48hills.org/2022/10/matt-dorseys-treasure-island-problem/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jackie Fielder
-- ============================================================

-- ----- Jackie Fielder / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Within her first week in office (January 2025) Fielder introduced a resolution reaffirming San Francisco as a sanctuary city, which passed unanimously. She addressed approximately 9,000 protesters against ICE raids in June 2025 and called for the city to take an official stance against arrests at immigration courts. In March 2026 she called for a full audit of the sheriff's office over ICE-related practices including strip searches and detainers.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Fielder strongly opposes deportation enforcement, introducing a sanctuary city resolution her first week in office and leading protests against ICE raids. She called for an audit of the SF Sheriff's office over cooperation with ICE detention practices, and was reluctant to support street-vendor enforcement legislation citing concerns about its use against immigrant communities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As a democratic socialist and DSA member, Fielder has consistently taken maximally welcoming positions on immigration: sponsoring a unanimous sanctuary city reaffirmation resolution, opposing ICE arrests at courts, auditing the sheriff over ICE cooperation, and publicly leading demonstrations against federal immigration raids in June 2025.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fielder voted against December 2025 legislation that would have upzoned approximately 60% of San Francisco for additional housing density, a position more consistent with tenant-protection and neighborhood-preservation concerns than with aggressive supply expansion. She has focused her housing work on affordable and supportive housing funding — advocating $30 million for transitional youth and family housing — rather than market-rate density increases.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Fielder voted against the December 2025 upzoning measure that would have rezoned 60% of San Francisco for higher housing density, aligning her with progressive supervisors skeptical of market-rate density solutions. Her housing focus has been on tenant protections, permanent supportive housing, and publicly funded affordable units rather than broad rezoning.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Fielder is a Mission District renter and democratic socialist who has prioritized tenant protections throughout her career. She voted against Proposition C amendments that would have redirected permanent supportive housing funds to temporary shelters, and has opposed mayoral eviction policies that lack viable housing alternatives, indicating a strong preference for tenant protections over landlord flexibility.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Fielder, who has personal experience with homelessness (couch-surfing and sleeping in a vehicle), introduced legislation ending the 90-day shelter stay limit for families, endorsed a $66 million annual allocation for homeless families, and opposed eviction policies without viable housing alternatives. She has consistently advocated housing-first and service-based approaches over enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Fielder has championed unlimited shelter extensions for families and $30 million in transitional housing funding, prioritizing outreach and services. She called for informational hearings on Zurich's four-pillar strategy (treatment, harm reduction, prevention, enforcement), indicating support for a comprehensive services approach. She voted for Mayor Lurie's fentanyl ordinance after negotiating limits on it, suggesting she accepts some enforcement as part of a broader strategy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fielder opposed the SF Police Officers Association's use of force policy and has been critical of law enforcement approaches. She championed a hearing on Zurich's four-pillar drug strategy, which balances enforcement with treatment and harm reduction. She voted for a modified fentanyl ordinance and sent inquiries to police about chase policies, suggesting she supports unarmed and social service alternatives while accepting limited targeted enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$As chair of the Government Audit and Oversight Committee, Fielder called for a comprehensive audit of the SF Sheriff's office over strip search practices and ICE cooperation, signaling strong skepticism of carceral expansion. Her support for the Zurich four-pillar drug strategy and harm-reduction approaches indicates preference for diversion and treatment over incarceration.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Fielder is a DSA member who has opposed SFPOA's use of force policy, called for audits of the Sheriff's office over ICE cooperation and strip search practices, and championed harm-reduction and treatment-centered approaches to the drug crisis modeled on Zurich's four-pillar strategy. These positions align with strong criminal justice reform and diversion rather than punitive enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Fielder co-directed Stop the Money Pipeline, a national campaign disrupting financing flows to fossil fuel companies, and co-founded the SF Defund DAPL Coalition in 2017. She chairs SF's LAFCo which oversees Clean Power SF. On the BOS she has focused her public bank proposal on funding renewable energy and climate solutions, stating working San Franciscans face 'the growing threat of climate crisis' requiring public institutions to invest in climate solutions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://www.sf.gov/profile--jackie-fielder/', 'https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Fielder co-founded the SF Defund DAPL Coalition (2017) and participated in Dakota Access Pipeline protests. She co-directed Stop the Money Pipeline, working to cut off private capital flows to fossil fuel companies. She has consistently advocated for divestment from fossil-fuel-financing banks and framed the public bank as a tool to redirect money 'from Wall Street' toward clean energy investment.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://www.sf.gov/profile--jackie-fielder/', 'https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Fielder co-founded the SF Public Bank Coalition to create a city-owned bank to support 'small businesses, affordable housing, and renewable energy' and introduced a 2026 ballot measure tax to fund it. She explicitly framed the public bank as taking 'our money back from Wall Street and reinvest it into housing, clean energy and small businesses right here at home,' reflecting a community-reinvestment and worker-centered economic development approach.$$,
        ARRAY['https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/', 'https://missionlocal.org/2026/02/s-f-supervisor-proposes-tax-to-fund-a-public-bank/', 'https://www.sf.gov/profile--jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$In February 2026 Fielder introduced a ballot measure to levy a new tax to fund a public bank — a position reflecting support for increased public revenue. She was the only supervisor to vote against Mayor Lurie's $15.9 billion budget proposal, suggesting she wanted greater spending on progressive priorities. As a democratic socialist she is on record wanting to redirect private finance toward public goods.$$,
        ARRAY['https://missionlocal.org/2026/02/s-f-supervisor-proposes-tax-to-fund-a-public-bank/', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Fielder is a democratic socialist and DSA member with a record of opposing corporate and private financial power in public institutions. She explicitly framed the public bank as countering Wall Street's influence over public funds. DSA endorsement and her activism history indicate support for strict limits on private money in politics and public campaign financing.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fielder is a woman of Indigenous (Cheyenne River and Fort Berthold Sioux) and Mexican descent who participated in the 2014 Black Lives Matter protests and the Dakota Access Pipeline resistance movement. She taught 'Race, Women, and Class' at SF State in ethnic studies. Her policy work has focused heavily on protecting communities of color from enforcement overreach including auditing the sheriff over ICE and strip-search practices.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Fielder is a DSA-endorsed democratic socialist and queer woman who has not explicitly addressed abortion in her BOS record, but her strong progressive profile — including endorsements from progressive organizations and her 2020 CA Senate campaign on a platform left of Scott Wiener — makes a strong pro-choice position virtually certain. No direct vote or statement found on this topic at the local level, but her ideology and coalition place her squarely in the pro-choice camp.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Fielder publicly identifies as queer and is a DSA member who challenged Scott Wiener (an openly gay senator and leading LGBTQ+ advocate) in the 2020 CA Senate race, campaigning from a more progressive position on the same social justice terrain. Her personal identity and democratic socialist politics place her at strong support for full federal same-sex marriage protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Fielder is a queer-identified democratic socialist whose entire political career has been built within coalitions strongly supportive of full LGBTQ+ inclusion. She has not made a specific statement on transgender athletes in available sources, but her DSA membership, queer identity, and consistent progressive alignment make full inclusion of transgender athletes consistent with her documented positions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fielder ran her 2020 CA Senate campaign as a democratic socialist challenging Scott Wiener from the left, which included single-payer healthcare support. As a DSA member, she is associated with Medicare for All advocacy. No specific legislative action on healthcare was found in her BOS record, but her national healthcare position as a democratic socialist aligns with a public option or single-payer approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$As a democratic socialist and DSA member who ran for CA Senate from the left, Fielder's political alignment is strongly in favor of expanding Medicare and Medicaid rather than cutting or privatizing them. No specific BOS votes on Medicare/Medicaid were found, but her public bank proposal explicitly targets healthcare-adjacent investment in community services.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Fielder is a democratic socialist aligned with expanding, not cutting, Social Security benefits. No direct votes or statements on Social Security were found in her BOS record, but her ideology and DSA affiliation are consistent with expanding Social Security and opposing privatization.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Fielder chairs SF LAFCo, which oversees Clean Power SF (the city's community choice energy program). Her climate activism history — co-directing Stop the Money Pipeline and co-founding the Defund DAPL Coalition — reflects a strong local environmental protection orientation. Her public bank proposal prioritizes low-interest loans for renewable energy projects.$$,
        ARRAY['https://www.sf.gov/profile--jackie-fielder/', 'https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Fielder's homelessness approach focuses on services, housing, and harm reduction over enforcement sweeps. She pushed for a four-pillar drug strategy and has opposed punitive approaches to street homelessness without housing alternatives. No direct vote on sanitation enforcement was found, but her overall orientation favors services-based responses over enforcement as the primary tool.$$,
        ARRAY['https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Fielder voted against the December 2025 upzoning measure and has focused growth priorities on community-centered affordable housing rather than market-rate development. Her public bank is framed as an alternative to private developer finance, with community benefit requirements implied. She has held developers accountable — subpoenaing Nick Podell over an unfulfilled $500K affordable housing pledge.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Fielder sits on the SF County Transportation Authority, signaling engagement with multimodal transportation planning. Her climate-forward positions and urban progressive politics align with prioritizing public transit, cycling, and pedestrian infrastructure. She introduced a call for state legislation allowing cities to regulate autonomous vehicles (Waymo) after a fatal incident in her district, indicating local-control and safety-oriented transportation values.$$,
        ARRAY['https://www.sf.gov/profile--jackie-fielder/', 'https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a democratic socialist and DSA member, Fielder is aligned with reform-oriented redistricting positions favoring independent commissions rather than partisan legislative control. No specific vote or statement on redistricting was found in her BOS record, but her progressive reformist orientation is consistent with support for independent or bipartisan commission-based redistricting.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$No direct vote on voting rights was found in Fielder's BOS record, as this is primarily a state and federal issue. Her democratic socialist politics, DSA membership, and advocacy for marginalized communities strongly indicate support for expanding voting access and opposing restrictive ID requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No direct statement or vote on misinformation regulation was found in Fielder's record. Her progressive politics suggest general support for platform accountability, but her DSA and civil-liberties-adjacent orientation also reflects wariness of government censorship. Insufficient evidence to place her definitively on this scale.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Fielder's work on transitional and supportive housing for families and her democratic socialist platform reflect strong support for publicly subsidized childcare. No specific BOS legislation on childcare was found, but her advocacy for working-class families and community investment through the public bank aligns with expanding public childcare access.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder', 'https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$No direct statement on school vouchers was found in Fielder's BOS record. However, as a DSA-endorsed democratic socialist, a former ethnic studies lecturer at a public university, and a strong supporter of public institutions over private finance, her position is consistent with opposing school voucher programs that divert funds from public schools.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct vote on religious freedom exemptions was found in Fielder's BOS record. As a progressive democratic socialist focused on civil rights and anti-discrimination protections — particularly for LGBTQ+ individuals and communities of color — her positions align with prioritizing anti-discrimination law over broad religious exemptions that could override civil rights protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$No direct statement on federal tariff policy was found in Fielder's record. Federal trade policy is outside the scope of the SF BOS, and her 2020 CA Senate campaign did not address tariffs. Insufficient evidence to place her definitively on this scale.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '24e9212c-b011-422a-865c-093e35050901',
        $$No direct statement on Ukraine aid was found in Fielder's BOS record. Federal foreign policy is outside the scope of her role and her campaign history. As a democratic socialist, she may lean toward skepticism of military aid, but insufficient evidence exists to place her definitively on this scale.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jackie Fielder / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('02f88a57-ccf5-4fe1-a693-7fc949321fb1',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No direct statement on AI regulation was found in Fielder's BOS record. She called for state legislation allowing local governments to regulate autonomous vehicles after a fatal Waymo incident in her district, which indicates some appetite for local government control over emerging technology, but this is too narrow a data point to score the broader AI regulation scale with confidence.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jackie_Fielder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brooke Jenkins
-- ============================================================

-- ----- Brooke Jenkins / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Jenkins has not endorsed criminalizing homelessness by law but enforces laws against public disorder and supports enforcement-first approaches. Her office has prosecuted nonprofit workers who allegedly defrauded homeless shelter programs (Jan 2026). She does not advocate for the right to camp in public and her overall approach prioritizes accountability over decriminalization.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Jenkins' primary strategy has been enforcement — prosecuting repeat offenders, opposing OR releases, and warning that budget cuts would have a crippling effect on public safety. She launched the Access to Hope non-prosecutorial prevention program as a complement to enforcement but has not adopted a housing-first or decriminalization stance as a primary tool.$$,
        ARRAY['https://sfdistrictattorney.org/access-to-hope/', 'https://sfstandard.com/tag/brooke-jenkins/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jenkins has consistently prioritized increasing police cooperation, expanding prosecution of repeat offenders, and warning that budget cuts would have a crippling effect on public safety. She supported Prop E (2022) expanding police surveillance cameras, hired prosecutors to aggressively pursue violent and drug crimes, and convictions rose 5% from 2022 to 2023 under her tenure.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfstandard.com/tag/brooke-jenkins/', 'https://sfdistrictattorney.org/news/press-releases/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Jenkins has consistently opposed own-recognizance and low-bail releases for defendants she considers public safety threats. She publicized cases where defendants released by courts went on to commit new crimes (January 2026 press release on Oakland burglaries by SF-released defendant; February 2026 human trafficking defendant released before arraignment). Her office also launched a statewide Voice of the People tour in January 2026 on smart prison reform — suggesting selective reform rather than broad reduction of incarceration.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Jenkins reversed Chesa Boudin's approach and reinstated cash bail requests for drug traffickers and other defendants. Her office repeatedly publicized cases where defendants were released on own recognizance by courts and went on to commit new crimes, framing OR releases as a public safety failure. She made drug dealers ineligible for community courts, which effectively increases pretrial detention pressure on that category of defendant.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfdistrictattorney.org/news/press-releases/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Jenkins made fentanyl and narcotics trafficking her top prosecution priority — announcing over 30 felony narcotics trafficking charges in a single month (November 2025), pursuing drug trafficking convictions in the Tenderloin and SOMA, and aggressively charging repeat offenders. She also enabled gang enhancements and adult prosecution of minors in a broader range of cases than her predecessor.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfstandard.com/tag/brooke-jenkins/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Jenkins is a law-and-order Democrat who reversed progressive Boudin-era policies: she reinstated cash bail, enabled gang enhancements, pursued adult prosecution of minors more broadly, and opposed OR releases. She also maintained a restorative justice unit and a conviction review unit — but those complement rather than replace her enforcement-first approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfdistrictattorney.org/restorative-justice/', 'https://sfdistrictattorney.org/conviction-review/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Jenkins' office maintains an Independent Investigations Bureau tracking officer-involved shootings and in-custody deaths, and her office has pursued some accountability cases. However, she has strongly supported police cooperation and expanded surveillance (Prop E, 2022). Public defenders alleged her office withheld evidence at least 50 times between September 2024 and February 2025, including body camera footage — suggesting limited enthusiasm for transparency that disadvantages prosecution.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfdistrictattorney.org/data/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Jenkins' office publishes prosecution data through seven public dashboards, making it among the most transparent DAs' offices in California. However, public defenders alleged her office withheld evidence at least 50 times between September 2024 and February 2025. She also shared a confidential rap sheet outside official channels during the Boudin recall campaign — an action the State Bar found evidence of improper handling.$$,
        ARRAY['https://sfdistrictattorney.org/data/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Jenkins sponsored the Restitution First Act (signed by Governor Newsom October 2025), ensuring crime victims receive financial restitution before any fines or fees are collected. She maintains a Victim Services Division, an Access to Hope prevention and reentry program, and restorative justice programs for youth. Her focus on victims and restitution reflects a balanced but prosecution-oriented view of justice access.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://sfdistrictattorney.org/access-to-hope/', 'https://sfdistrictattorney.org/conviction-review/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As a San Francisco DA, Jenkins operates within SF's sanctuary city framework, which limits proactive cooperation with ICE. There is no evidence she has publicly opposed the sanctuary policy or pushed for active ICE cooperation. She has not been documented calling for SF to honor ICE detainers or share immigration data proactively, though she has prosecuted human trafficking cases using local task forces.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jenkins has prosecuted hate crimes (antisemitic and homophobic vandalism charges in March 2026) and maintained a Racial Justice Act review process in her conviction review unit. However, she has also supported expanded surveillance through Prop E (criticized by the ACLU and EFF) and has been accused of prosecutorial overreach. Her record reflects a moderate approach that enforces existing civil rights laws without major advocacy for expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brooke_Jenkins', 'https://sfdistrictattorney.org/conviction-review/', 'https://sfdistrictattorney.org/news/press-releases/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Jenkins' public safety approach focuses on enforcement of criminal laws including vandalism, property damage, and public disorder — consistent with a hold-residents-and-businesses-accountable stance. She prosecuted cases of vandalism (multiple 2025-2026 press releases) and has been a visible proponent of enforcement as the primary tool for improving street conditions.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/', 'https://en.wikipedia.org/wiki/Brooke_Jenkins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Jenkins / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('969f1ca4-4766-44fd-8638-ef813b1835e7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jenkins has pursued consumer protection settlements (Vivint Solar, Wag Hotels, CarMax) and prosecuted fraud and embezzlement by nonprofits and city contractors, which promotes accountability in economic dealings. She has not publicly advocated for specific economic development incentive policies — her role as DA is in enforcement, not economic strategy.$$,
        ARRAY['https://sfdistrictattorney.org/news/press-releases/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Daniel Lurie
-- ============================================================

-- ----- Daniel Lurie / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Lurie's approach combines enforcement (85% reduction in tent encampments, cleared open-air drug markets) with substantial outreach and treatment services (600+ new treatment-focused beds, 822 Geary crisis stabilization center). He declared a fentanyl state of emergency on day one but explicitly said 'We won't arrest our way out of this problem,' situating him as enforcing public space rules while requiring services to be available — consistent with stance 3 (enforcement only when adequate shelter available, citations diverting to services).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-announces-san-francisco-has-reached-lowest-level-of-unsheltered-homelessness-in-15-years/', 'https://missionlocal.org/2025/04/san-francisco-homeless-shelter-1500-beds-daniel-lurie/', 'https://missionlocal.org/2026/02/sf-mission-district-bart-plazas-police-16th-24th-street/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Lurie's Breaking the Cycle plan pairs robust street outreach and treatment (600+ new treatment beds, consolidated DPH outreach teams) with enforcement of public order rules. His 1,500-shelter-bed goal, RESET Center, and 822 Geary crisis center show commitment to shelter capacity before and alongside enforcement. He explicitly rejected pure enforcement ('We won't arrest our way out of this problem') but also cleared tent encampments and drug markets, fitting stance 3 (invest in outreach and shelter while enforcing reasonable public space rules).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-announces-san-francisco-has-reached-lowest-level-of-unsheltered-homelessness-in-15-years/', 'https://missionlocal.org/2025/04/san-francisco-homeless-shelter-1500-beds-daniel-lurie/', 'https://missionlocal.org/2026/02/sf-mission-district-bart-plazas-police-16th-24th-street/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lurie has pushed to expand affordable housing (proposed raising the Housing Trust Fund from $52M to $125M/year through 2058, a $70M preservation bond, office-to-housing conversions downtown with reduced fees) while also opposing a specific 790-unit high-rise in the Marina district. His inclusionary housing update reduced on-site affordable requirements to 5% to encourage market-rate development. He is an active builder-oriented mayor offering tax incentives and fee reductions — fitting stance 3 (tax incentives for affordable housing while helping development broadly).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-supervisor-melgar-announce-transformative-funding-for-affordable-housing/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lurie has prioritized increasing police staffing above all else: his 'Rebuilding the Ranks' initiative targets 425 new officers/deputies/dispatchers within three years, he signed a 4-year SFPD labor contract with 3-5% annual raises and $25,000 signing bonuses, and citywide crime dropped nearly 30% in his first year. He removed a reform-minded police commissioner and centralized public safety authority. He stated 'an investment in public safety is an investment in our comeback.' This aligns with stance 4 (increase police staffing, equipment, and pay to improve response times and deter crime).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-signs-legislation-to-support-san-francisco-police-officers-continue-to-drive-down-crime/', 'https://missionlocal.org/2025/02/mayor-lurie-picks-anti-violence-activist-sfpd-commission-mattie-scott-max-carter-oberstone/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Lurie has launched a Hospitality Zone Task Force to increase cleanliness in tourism areas, modified street cleaning schedules to begin before school starts in the Mission, and launched a Street Safety executive directive coordinating city departments. His administration maintained existing sanitation services while directing them more strategically to problem areas. 73% approval ratings include praise for tackling city cleanliness. This fits stance 3 (maintain services while enforcing anti-dumping laws).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-announces-san-francisco-has-reached-lowest-level-of-unsheltered-homelessness-in-15-years/', 'https://missionlocal.org/2026/02/sf-mission-district-bart-plazas-police-16th-24th-street/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Lurie introduced a 'Family Zoning' plan (June 2025) to broadly boost homebuilding, simplified permitting for office-to-housing conversions, eliminated affordable housing fees for downtown conversions, and launched an online permit tracker to accelerate approvals. His approach is to streamline and upzone while reducing regulatory barriers. However, he opposed one specific 25-story high-rise in the Marina district, suggesting some neighborhood-context sensitivity. Overall posture aligns with stance 4 (upzone broadly, streamline approvals, reduce parking requirements).$$,
        ARRAY['https://en.wikipedia.org/wiki/Daniel_Lurie', 'https://missionlocal.org/2025/02/mayor-lurie-has-99-fixes-for-san-franciscos-downtown-but-a-fix-for-transit-aint-one/', 'https://www.sf.gov/news-mayor-lurie-supervisor-melgar-announce-transformative-funding-for-affordable-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Lurie has consistently pushed to streamline permitting, reduce fees (eliminated affordable housing fees for office-to-housing conversions, reduced inclusionary requirements), and lower barriers to development to grow SF's tax base and economic recovery. He launched an online permit tracker, pushed the Board to expedite approvals, and urged businesses to 'come back and invest.' He stated 'the era of soaring budgets is over' while actively trying to grow commercial and residential activity. This fits stance 4 (streamline permitting, reduce fees, actively recruit development).$$,
        ARRAY['https://missionlocal.org/2025/02/mayor-lurie-has-99-fixes-for-san-franciscos-downtown-but-a-fix-for-transit-aint-one/', 'https://en.wikipedia.org/wiki/Daniel_Lurie', 'https://www.sf.gov/news-mayor-lurie-supervisor-melgar-announce-transformative-funding-for-affordable-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lurie has actively courted businesses to return to downtown SF, pushed state legislation for 20 new liquor licenses downtown, eliminated development fees, proposed a transfer tax cut (from 5.75% to 2.75% on properties over $10M) framed as economic stimulus, and opposed a CEO pay-ratio tax (Prop. D) as anti-business. He launched a Hospitality Zone Task Force around Union Square and Moscone Center. His stated goal is to make SF 'the best city in the world to do business.' This aligns with stance 4 (compete actively for employers with significant tax abatements and infrastructure investment).$$,
        ARRAY['https://missionlocal.org/2025/02/mayor-lurie-has-99-fixes-for-san-franciscos-downtown-but-a-fix-for-transit-aint-one/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/', 'https://missionlocal.org/2026/04/sf-lurie-layoffs-unions-fight-ifpte-seiu-budget/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lurie opposes new taxes on businesses: he opposed Prop. D (CEO pay-ratio tax) as potentially driving businesses away, proposed cutting transfer taxes on high-value real estate (forgoing $78M/year in revenue), and framed his $15.9B budget around spending cuts rather than revenue increases. He stated 'the era of soaring budgets is over' and sought to reduce reliance on gross receipts taxes. His approach is to reduce tax burden on businesses and developers to stimulate economic activity, fitting stance 4 (reduce tax rates).$$,
        ARRAY['https://missionlocal.org/2026/04/sf-lurie-layoffs-unions-fight-ifpte-seiu-budget/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/', 'https://missionlocal.org/2025/05/lurie-unveils-new-budget-proposal-tackling-massive-deficit/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Lurie cut a ribbon on a bike and pedestrian safety project (Terry Francois Boulevard) and launched a Street Safety executive directive coordinating city departments on safer street design. However, he was notably passive on Muni transit cuts, stating 'This is what Muni may need to do to solve the wider budget crisis' — accepting transit service reductions rather than fighting them. His administration focused on roads in high-traffic commercial zones. This mixed record fits stance 3 (maintain roads while selectively adding pedestrian improvements where density supports it).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-cuts-ribbon-on-terry-francois-boulevard-bike-and-pedestrian-safety-improvement-project/', 'https://missionlocal.org/2025/02/mayor-lurie-has-99-fixes-for-san-franciscos-downtown-but-a-fix-for-transit-aint-one/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$At a September 2024 mayoral forum, Lurie explicitly expressed support for San Francisco's sanctuary city ordinance. His administration's budget fully protected legal services for immigrant communities from cuts (included in the explicitly 'protected' category alongside police, fire, and DA). His office framed administering DACA support for a staffer as reflecting 'San Francisco values.' His position aligns with stance 2 (comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral).$$,
        ARRAY['https://missionlocal.org/2024/09/see-how-they-run-breed-lurie-trade-barbs-in-latino-focused-mission-mayoral-forum/', 'https://missionlocal.org/2025/05/lurie-unveils-new-budget-proposal-tackling-massive-deficit/', 'https://missionlocal.org/2026/04/sf-mayor-lurie-staffer-daca-delays/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$In 2026, Mayor Lurie announced free childcare for SF families earning under $250,000 annually and subsidized care for families earning under $310,000 — a very expansive income-based program covering the large majority of SF families. This goes well beyond targeting only low-income families and represents significant subsidy expansion, aligning with stance 2 (significantly expanding subsidies to make childcare affordable for low- and middle-income families).$$,
        ARRAY['https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Lurie's housing approach has focused on increasing supply through streamlined permitting and reduced fees rather than expanding rent control. His inclusionary housing update reduced on-site affordable requirements (from higher to 5%) to encourage market-rate development. He has not publicly campaigned to expand rent stabilization. San Francisco's existing strong rent control system is maintained under his administration. This fits stance 3 (maintain current tenant protections while allowing market rents for new construction).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-supervisor-melgar-announce-transformative-funding-for-affordable-housing/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel Lurie / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('708db738-2bf1-4a6f-b8a5-7ac23d171b33',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Lurie's approach to environmental review reflects a balance: he backed a bike/pedestrian safety project, launched a Street Safety executive directive, but also eliminated environmental impact fees for office-to-housing conversions and reduced inclusionary housing requirements to speed development. He has not moved to remove environmental restrictions or require significant green space offsets. This pragmatic, developer-friendly stance that maintains basic standards but gives flexibility fits stance 3 (consistent environmental standards while giving developers reasonable flexibility on implementation).$$,
        ARRAY['https://www.sf.gov/news-mayor-lurie-cuts-ribbon-on-terry-francois-boulevard-bike-and-pedestrian-safety-improvement-project/', 'https://missionlocal.org/2025/02/mayor-lurie-has-99-fixes-for-san-franciscos-downtown-but-a-fix-for-transit-aint-one/', 'https://en.wikipedia.org/wiki/Daniel_Lurie']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Bilal Mahmood
-- ============================================================

-- ----- Bilal Mahmood / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mahmood is a self-identified YIMBY who has introduced legislation to eliminate shadow analysis from CEQA environmental reviews (blocking 2,195 units across 11 projects since 2017), explored a ballot measure to streamline building permits (currently averaging 280 days), and supported Mayor Lurie's upzoning plan. He frames housing as his top priority and advocates for cutting red tape across Planning and DBI departments, though he co-sponsored a controversial transfer-tax cut that critics say eliminates $500M in affordable housing funding.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-bilal-mahmood-shadow-ceqa-housing/', 'https://missionlocal.org/2026/03/sf-housing-ballot-measure-building-permit-bilal-mahmood/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As a YIMBY, Mahmood supports broad upzoning and backed Mayor Lurie's upzoning plan. He authored legislation to eliminate shadow analysis restrictions that had blocked multifamily infill housing, and supports streamlining approvals to allow significantly more density citywide. He supports converting four rent-controlled apartments into a single-family home in one vote, but his overall record strongly favors density increases.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-bilal-mahmood-shadow-ceqa-housing/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Mahmood consistently prioritizes streamlining development — his platform calls for cutting permit fees, reducing impact fees, parallel-processing approvals, and consolidating Planning and DBI departments. He collaborated with Mayor Lurie on a plan to reduce real-estate transfer taxes to stimulate construction. His approach is market-friendly: reduce regulations and let development scale, trusting economic activity will benefit the city.$$,
        ARRAY['https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/', 'https://missionlocal.org/2026/03/sf-housing-ballot-measure-building-permit-bilal-mahmood/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Mahmood co-sponsored the mayor's fentanyl emergency ordinance, supports the Drug Market Intervention strategy (arresting fentanyl dealers), and backed the RV ban that resulted in 169 vehicle tows and only 82 people housed. He supports expanding shelter capacity and personalized care but couples it with active enforcement and inter-agency coordination, including police patrols and drug market crackdowns.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mahmood opposes arresting people solely for sleeping on streets and supports routing unhoused individuals to shelters then permanent supportive housing; he introduced a shelter placement ordinance to ensure equitable citywide shelter distribution. However, he also voted for the RV ban, supported SFPD overtime and the Drug Market Agency Coordination Center, and pushes kid-safe zones near schools — a mixed enforcement-plus-services approach.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/', 'https://missionlocal.org/2025/07/sf-bilal-mahmood-newcomer-leads-legislation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mahmood voted to fund a new SFPD surveillance center, voted to remove a reform-oriented police commissioner at the mayor's request, supports SFPD overtime funding, and backed expanded police beat patrols in the Tenderloin. He also supported the Drug Market Intervention strategy centering on dealer arrests. While he frames public safety with innovation language, his voting record aligns with a traditional law enforcement expansion approach.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/', 'https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Mahmood has been categorical in opposing ICE enforcement in San Francisco. He passed legislation creating ICE-free zones on city-owned property, introduced an ordinance requiring SFPD to verify and document on body cameras any ICE agent credentials, attended anti-ICE protests, and expanded immigrant legal defense at the public defender's office. He stated he opposes deportations 'categorically' and wants immigrants to 'know that they can count on their government.'$$,
        ARRAY['https://missionlocal.org/2026/03/sfo-sfpd-masked-ice-supervisors-legislation/', 'https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Mahmood stated he opposes deportations 'categorically,' has created ICE-free zones on city property, introduced legislation to have SFPD document any federal agent credentials on body cameras, and condemned deportations of humanitarian mission visitors. He explicitly identifies with protecting Muslim, Yemeni, Palestinian, Pakistani, and Indian immigrant communities in his district.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://missionlocal.org/2026/03/sfo-sfpd-masked-ice-supervisors-legislation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As the son of Pakistani immigrants and the first South Asian and Muslim-American elected to the SF Board of Supervisors, Mahmood strongly supports welcoming immigration policies. He created ICE-free zones, expanded immigrant legal defense, and his campaign explicitly rejected law enforcement money — including federal immigration enforcement collaboration. He stated immigrants should 'know that they can count on their government.'$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://bilalmahmood.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Mahmood voted with moderate colleagues to permanently destroy a rent-controlled housing unit by converting it to a single-family home, and co-sponsored Mayor Lurie's plan to cut transfer taxes on multimillion-dollar real estate deals — legislation that critics say would eliminate $500M in Prop I affordable housing funding. He has not championed expansion of rent control protections in his legislative record.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Mahmood supports the Drug Market Agency Coordination Center (DMACC) model that coordinates DPW street cleaning alongside law enforcement, and his Mid-Market revitalization proposal combines enhanced sanitation with police patrols. He frames cleanliness as a public safety issue requiring inter-agency coordination, neither purely enforcement nor purely a services-first approach.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://sfstandard.com/2026/02/19/san-francisco-theater-mid-market-bilal-mahmood/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mahmood is directing District 5's $700K Neighborhood Transportation Program toward pedestrian safety infrastructure (speed humps, raised crosswalks, painted safety zones). His campaign platform calls for expanding slow streets and car-free initiatives like Hayes Street and the Golden Gate Greenway, and he sits on the SF County Transportation Authority. He advocates automated speed enforcement cameras and street conversions to reduce car dominance.$$,
        ARRAY['https://www.sf.gov/profile--bilal-mahmood', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Mahmood co-led the 2023 Upgrade California campaign supporting building decarbonization legislation and zero-emission buildings. His campaign platform calls for electrifying buildings through partnerships with state legislators on bond and tax credit measures for heat pumps and Smart A/C. He previously worked as a director at Electric Action (climate nonprofit) and advocates for household education on 2026 electrification mandates.$$,
        ARRAY['https://bilalmahmood.com/platform', 'https://bilalmahmood.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Mahmood's campaign platform explicitly rejected fossil fuel company money: 'No fossil fuel money.' He co-led the Upgrade California campaign for zero-emission buildings, advocates for EV charging infrastructure, and worked previously at Electric Action (climate nonprofit). His decarbonization-focused platform aligns with stopping new fossil fuel permits, though he has not authored specific fossil fuel legislation as supervisor.$$,
        ARRAY['https://bilalmahmood.com/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Mahmood supports building electrification and climate action but his housing legislation (eliminating shadow analysis from CEQA, shortening appeal timelines, reducing permit requirements) explicitly weakens environmental review tools used to slow development. He frames CEQA environmental objections as obstacles to housing, compressing review periods from 30 to 15 days. He balances development acceleration with climate goals rather than prioritizing either absolutely.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-bilal-mahmood-shadow-ceqa-housing/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mahmood's Mid-Market revitalization strategy relies on private donations rather than city budget, he co-sponsored transfer tax cuts to benefit large commercial real estate deals, and his platform calls for streamlining permitting and reducing impact fees to attract development. He supports small business grants but frames economic development primarily through reducing regulatory barriers and attracting private investment.$$,
        ARRAY['https://sfstandard.com/2026/02/19/san-francisco-theater-mid-market-bilal-mahmood/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Mahmood authored a DCCC resolution declaring racism and hate crimes a public health crisis, introduced legislation expanding SF's Fair Chance Ordinance to prohibit employers from using out-of-state convictions against LGBTQ+ refugees and others, and has supported anti-hate crime public health investments. He also authored legislation on domestic violence awareness and hate crime prevention education.$$,
        ARRAY['https://sfstandard.com/2026/05/18/fair-chance-ordinance-abortion-transgender/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Mahmood's legislation expanding the Fair Chance Ordinance explicitly protects LGBTQ+ refugees from out-of-state criminal records that criminalize their identities. He noted '13 state legislatures have enacted 28 anti-trans bills into law in 2026 alone' as justification for San Francisco's protections. He received endorsement from the SF Democratic Party and has never expressed opposition to same-sex marriage.$$,
        ARRAY['https://sfstandard.com/2026/05/18/fair-chance-ordinance-abortion-transgender/', 'https://bilalmahmood.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Mahmood received endorsement from Planned Parenthood Northern California Action Fund during his 2024 campaign, indicating alignment with pro-choice positions. As a local city supervisor, abortion is not within his legislative jurisdiction, but his Planned Parenthood endorsement and Democratic Party alignment indicate support for abortion access.$$,
        ARRAY['https://bilalmahmood.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Mahmood supported Proposition D, the 'Overpaid CEO' tax on highly compensated executives, voting for it at the DCCC — breaking with his moderate allies and drawing criticism from Y Combinator CEO Garry Tan. However, he also co-sponsored a plan to cut real-estate transfer taxes on multimillion-dollar deals, reducing rates from 5.75% to 2.75% on properties over $10 million. His record is mixed: taxing high executive pay but cutting taxes on large real estate transactions.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/', 'https://missionlocal.org/2026/03/sf-lurie-mahmood-transfer-tax-cut-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Mahmood's campaign explicitly rejected corporate PAC money, fossil fuel money, and law enforcement money. He states: 'We're running a clean and independent campaign. No corporate PAC Money. No fossil fuel money. No law enforcement money.' However, he was backed by a tech-funded PAC that spent $300,000 against progressive Dean Preston in 2024, suggesting he benefits from outside money even while personally declining certain donations.$$,
        ARRAY['https://bilalmahmood.com/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Mahmood supports Drug Market Intervention which includes providing workforce development off-ramps for non-violent first-time offenders, suggesting some preference for alternatives to incarceration. However, his public safety voting record (fentanyl emergency ordinance, SFPD overtime, surveillance center, drug dealer arrests) does not show active advocacy to reduce jail capacity or redirect incarceration funding to community programs.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://bilalmahmood.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Mahmood's Drug Market Intervention approach distinguishes between dealers (arrest and prosecute) and users (treatment and diversion), and he specifically calls for 'workforce development off-ramps for non-violent first-time offenders.' He also co-investigated GEO Group (a private prison operator) with Supervisor Jackie Fielder. His approach mixes enforcement with diversion rather than purely tough-on-crime or reform-only positions.$$,
        ARRAY['https://missionlocal.org/2025/02/sf-intro-interview-bilal-mahmood-district-5/', 'https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bilal Mahmood / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3c5004c-9ca0-444e-96d9-107d4315abcb',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Mahmood held a hearing on Waymo robotaxis after system failures caused gridlock, demonstrating willingness to scrutinize tech company operations. No specific stance on misinformation regulation or social media content moderation was found; his tech-entrepreneur background and results-oriented governance style suggest he is neither a strong regulator nor a strict hands-off libertarian on platform accountability, though this is low-confidence.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-moderates-bilal-mahmood-oust-leftiest-supe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Rafael Mandelman
-- ============================================================

-- ----- Rafael Mandelman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored 2022 fourplex legislation allowing up to four units on residentially zoned lots and six on corner lots. Co-authored 2018 legislation increasing fines for illegal demolition of rent-controlled housing. Supported Prop 10 to repeal Costa-Hawkins and called for Ellis Act reform. Has secured affordable housing funding including a 100% affordable Mission Street acquisition and senior LGBTQ housing.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://www.sf.gov/profile--rafael-mandelman/', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Authored the 'A Place for All' ordinance (2022) establishing policy that all unhoused people receive shelter access. Co-authored conservatorship legislation for individuals with severe mental illness and substance use disorder. Helped fund Street Crisis Response Teams handling 21,000+ behavioral health crisis calls. Established Hummingbird behavioral health respite center with 30 beds and opened 28 beds at Jazzie's Place for trans and gender nonconforming individuals.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mandelman invests in outreach and shelter — co-authoring the conservatorship expansion and shelter-for-all ordinance — while also supporting reasonable public space enforcement through the moderate Lurie administration agenda. He secured Street Crisis Response Teams and behavioral health services as alternatives to police response, reflecting a services-first but not purely enforcement-free approach.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfstandard.com/2025/12/19/san-francisco-city-hall-board-of-supervisors-2025/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SF's 2019 Climate Emergency Resolution committing the city to Paris Climate Accord goals. In 2020 introduced all-electric new construction ordinance making SF the largest US city to phase out natural gas. In 2025 authored All-Electric Major Renovations legislation requiring all major renovations to transition to all-electric systems effective July 2026.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Authored 2020 ordinance prohibiting natural gas hookups in new construction — making SF the largest US city to take this step. Extended this to all-electric major renovations (2025 legislation). Supports the Healthier, Cleaner, Quieter Communities Act banning gas-powered professional landscaping equipment starting January 2026. His framing: 'nearly half of San Francisco's emissions come from buildings burning natural gas.'$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Authored climate emergency resolution (2019) and all-electric buildings ordinance (2020). Supports Green Infrastructure Grant program (up to $2.5M for eligible projects). Championed ban on gas-powered landscaping equipment. Voted in 2024 to override Mayor Breed's veto of northeast waterfront height restrictions, citing concerns about the character of waterfront development.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$San Francisco's sanctuary city ordinance prohibits city employees from assisting ICE and sharing immigration status information. Mandelman actively defended this framework and championed a $3.5 million city plan to fund immigrant defense services. He stated the pre-2025 situation was 'a status quo of terror and fear for too many people' and pushed Medi-Cal enrollment before restrictions took effect.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://www.sf.gov/information/sanctuary-city-ordinance', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Championed a $3.5 million immigrant defense fund. Pushed Medi-Cal enrollment for residents before December 2025 restrictions for certain immigration statuses. Describes immigrant communities experiencing 'terror and fear' under federal enforcement and works to expand city-funded support services. Consistent with SF's sanctuary city posture.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Advanced $3.5M in city immigrant defense services funding. San Francisco's sanctuary ordinance (which Mandelman supports) prohibits city compliance with ICE detainers and bars sharing information with federal immigration enforcement. Mandelman characterized federal immigration enforcement as creating 'terror and fear' in immigrant communities.$$,
        ARRAY['https://www.sf.gov/information/sanctuary-city-ordinance', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hosts town halls with SFPD station captains and coordinates community safety engagement. Helped fund Street Crisis Response Teams as an alternative to police response for 21,000+ behavioral health calls annually. Hosts joint DA/SFPD safety forums. Does not call for defunding police but advocates adding unarmed crisis co-responders — maintaining current police staffing while adding crisis response capacity.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://sfstandard.com/2025/12/19/san-francisco-city-hall-board-of-supervisors-2025/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Co-chaired the 2019 Muni Reliability Working Group. Chairs the San Francisco County Transportation Authority. Led passage of 2022 ballot measure extending half-cent sales tax directing $2.6 billion in transportation funds over 30 years. Closed funding gap for Upper Market Safety Project streetscape improvements. His district includes Castro Street pedestrian-priority zones and Valencia Street weekend openings.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Authored fourplex legislation (2022) allowing multifamily by right on residential lots citywide. But also opposed California SB 50 state density mandates and voted in 2024 to override Mayor Breed's veto of waterfront height restrictions, showing concern for neighborhood character in some contexts. A moderate pro-housing position: supports targeted upzoning but not blanket elimination of zoning controls.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Co-authored 2018 legislation increasing fines for illegal demolition of rent-controlled housing. Called for Ellis Act reform to protect tenants from no-fault evictions. Supported Proposition 10 (2018 statewide measure to repeal Costa-Hawkins restrictions and expand rent control authority). These actions reflect consistent support for strengthening rent stabilization and tenant protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Mandelman is openly gay and represents the Castro neighborhood, the historic heart of LGBTQ+ San Francisco. He authored legislation creating the Castro LGBTQ Cultural District (2019), ended San Francisco's decades-long ban on bathhouses, opened 28 beds at Jazzie's Place shelter for trans and gender nonconforming individuals, and initiated landmark designation for 16 LGBTQ historic sites. Consistently advocates for full federal LGBTQ equality.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Led implementation of Sexual Orientation and Gender Identity (SOGI) data collection. Authored Castro LGBTQ Cultural District ordinance. Secured $2M+ for Lyon-Martin clinic for LGBTQ patients. Authored landmark designations for LGBTQ historic sites. Championed immigrant defense funding. Arrested at SFO labor protest in May 2026 demonstrating solidarity with workers. Consistently advocates for marginalized communities.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfstandard.com/2026/05/01/san-francisco-politicians-arrested-sfo-protest/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Championed 2024 Proposition M business tax reform, a revenue-neutral restructuring that cuts taxes for thousands of businesses while raising them on others and assists in business retention. Characterized as a pragmatic modernization rather than a broad increase or cut. Led 2022 study on remote work impacts on business tax revenue before designing the reform. Consistent with a close-loopholes/modernize-the-system approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://sfstandard.com/2025/12/19/san-francisco-city-hall-board-of-supervisors-2025/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Secured funding for Street Crisis Response Teams as alternatives to police for behavioral health and quality-of-life calls. Authored behavioral health conservatorship legislation targeting severe cases causing public disorder. His 'A Place for All' ordinance (2022) established shelter-for-all policy. Approached street conditions as primarily a services failure requiring more outreach investment, consistent with increasing sanitation and outreach staffing.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Co-authored conservatorship legislation creating treatment alternatives to incarceration for individuals with severe mental illness and substance use disorder. Helped fund Street Crisis Response Teams to divert behavioral health calls away from police and jail. Established the Hummingbird behavioral health respite center. His approach emphasizes diversion and treatment rather than expanded detention capacity.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Co-chaired the 2019 Methamphetamine Task Force. Co-authored conservatorship legislation for those with severe mental illness and substance use disorders as an alternative to incarceration. Funded Street Crisis Response Teams and Hummingbird behavioral health center. Approaches criminal justice primarily through a treatment and services lens, consistent with diversion and reform over punitive expansion.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Secured over $2 million for Lyon-Martin clinic's transition to independent provider, ensuring LGBTQ healthcare services. Actively promoted Medi-Cal enrollment for residents before December 2025 restriction deadline. Led behavioral health infrastructure including Hummingbird respite center and Street Crisis Response Teams. Consistent with expanding public healthcare access and safety-net programs.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://sfbos.archive.sf.gov/supervisor-mandelman-district-8']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Actively promoted Medi-Cal enrollment before December 31, 2025 deadline as new federal restrictions took effect for certain immigration statuses. Secured $2M+ for Lyon-Martin clinic serving Medi-Cal and low-income LGBTQ patients. His behavioral health programs (Hummingbird, Street Crisis Response Teams) are largely Medi-Cal funded expansions. Consistently advocates for expanding Medicaid-funded services.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-mandelman-district-8', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$As an openly gay supervisor representing the Castro and a consistent LGBTQ+ rights advocate, Mandelman opened 28 new beds at Jazzie's Place specifically for trans and gender nonconforming individuals, ended SF's bathhouse ban, and has championed full LGBTQ inclusion in city programs. No evidence of restrictions on transgender athletes; his legislative record reflects full inclusion of transgender people in city life.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$As an LGBTQ rights champion, Mandelman's record shows he prioritizes anti-discrimination protections over religious exemptions in employment and housing. He ended SF's bathhouse ban, created the Castro LGBTQ Cultural District, and has consistently protected LGBTQ individuals from discrimination — positions incompatible with broad religious liberty exemptions from civil rights laws.$$,
        ARRAY['https://www.sf.gov/profile--rafael-mandelman/', 'https://en.wikipedia.org/wiki/Rafael_Mandelman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Championed 2024 Proposition M business tax reform with targeted incentives for business retention. Authored zoning changes facilitating restaurant and nonprofit openings in vacant storefronts. Secured Castro Commercial Corridor Manager. Co-authored outdoor permitting fee waivers for small businesses. Supported Shared Spaces program. Teaming with Mayor Lurie and SPUR on charter streamlining. Targeted business support without maximum corporate subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rafael Mandelman / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2596e4d-f491-449e-b112-40be13418112',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Authored fourplex legislation (2022) and supports affordable housing production, but opposed California SB 50 state density mandates as overreach and voted in 2024 to restrict waterfront building heights. His approach: proactive investment in infrastructure (led $2.6B transportation sales tax) while allowing housing growth within existing environmental and community character constraints.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rafael_Mandelman', 'https://www.sf.gov/profile--rafael-mandelman/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Myrna Melgar
-- ============================================================

-- ----- Myrna Melgar / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Melgar has a mixed housing record. She voted in 2021 to block a 495-unit apartment project with 25% affordable housing on a valet parking lot site, prompting a state investigation of the BOS. However she received YIMBY endorsements in both 2020 and 2024, and in 2025 negotiated amendments to Mayor Lurie's Family Zoning Plan protecting rent-controlled buildings with 3+ units from demolition while supporting upzoning along corridors. She described the zoning plan's map as still needing 'more work' to ensure it 'includes tenants, small businesses, and affordable housing.'$$,
        ARRAY['https://en.wikipedia.org/wiki/Myrna_Melgar', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php', 'https://48hills.org/2025/10/activists-pressure-melgar-on-key-element-of-mayors-rich-family-zoning-plan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Melgar voted no in the Land Use and Transportation Committee (October 2024) on Supervisor Peskin's rent control expansion bill that would have extended protections to tens of thousands of additional units, citing concerns about impacts on the inclusionary housing program for affordable units in market-rate buildings. However, in 2025 she introduced amendments to Mayor Lurie's zoning plan that limit demolition of rent-controlled buildings with 3 or more units, and she holds the SF Tenants Union endorsement. Her record shows concern for affordable housing mechanisms but opposition to straightforward rent control expansion.$$,
        ARRAY['https://48hills.org/2024/10/rent-control-bill-advances-with-melgar-in-opposition/', 'https://48hills.org/2025/10/activists-pressure-melgar-on-key-element-of-mayors-rich-family-zoning-plan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Melgar chairs the Land Use and Transportation Committee and has generally supported upzoning along commercial and transit corridors, receiving YIMBY endorsements in both 2020 and 2024. She negotiated amendments to Mayor Lurie's 2025 Family Zoning Plan to protect rent-controlled buildings while supporting broader upzoning. However, she has also been protective of neighborhood character in specific cases (2021 block of 495-unit project) and voted against requiring public notification to residents about planned zoning changes, arguing it would 'needlessly alarm' people.$$,
        ARRAY['https://48hills.org/2025/04/supes-approve-public-notice-for-neighborhood-zoning-changes/', 'https://www.westsideobserver.com/24/9-supervisor-melgar-is-bad-fit-for-district-7.php', 'https://en.wikipedia.org/wiki/Myrna_Melgar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Melgar authored the Street Safety Act (passed September 2024), redirecting $34 million from road repair funds toward slow streets, quick builds, traffic neckdowns, and bike lanes. She chairs the SF County Transportation Authority (SFCTA), advocates for AB 43 speed reductions in business districts, sponsored Proposition K to permanently close the Great Highway to cars (passed November 2024), and championed expanding Free Muni for Youth in 2021. Her record consistently prioritizes multimodal and pedestrian-centered transportation over car-centric infrastructure.$$,
        ARRAY['https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php', 'https://en.wikipedia.org/wiki/Myrna_Melgar', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Melgar co-sponsored Proposition K (passed November 2024) to permanently close the Great Highway between Lincoln and Sloat to car traffic, creating a recreational corridor — a significant local environmental and open space action. Her legislative priorities explicitly include 'reducing carbon footprint' and she authored the Street Safety Act emphasizing pedestrian and cycling infrastructure. She supports speed reductions under AB 43 and has identified environmental sustainability as a core district priority.$$,
        ARRAY['https://www.westsideobserver.com/24/11-melgar-beats-the-odds-leaves-bigbucks-togethersf-in-the-dust.php', 'https://www.sf.gov/profile--myrna-melgar/', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Melgar's stated legislative priorities include 'reducing carbon footprint' and 'improving public transportation infrastructure.' She co-sponsored Proposition K (2024) to permanently close the Great Highway to vehicles, creating a car-free public corridor, and authored the Street Safety Act redirecting city infrastructure funding toward pedestrian and cycling improvements. Her support for speed limits per AB 43 and transit-first investments reflect a pattern of climate-aligned local policy.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Melgar lists 'reducing homelessness' as a top legislative priority on her official SF.gov profile. In 2025 she sponsored RV legislation on behalf of Mayor Lurie placing a 2-hour limit on oversized vehicle parking while simultaneously introducing programs to provide 'more targeted resources to RV dwellers' and permanent housing pathways. This approach combines enforcement (parking limits) with services (housing support), suggesting a mixed services-and-accountability rather than pure housing-first stance.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://en.wikipedia.org/wiki/Myrna_Melgar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Melgar's 2025 RV legislation paired a 2-hour parking limit on oversized vehicles with two new programs supporting RV dwellers with 'more targeted resources' toward permanent housing. This enforcement-plus-services model aligns with a balanced approach: she does not favor pure criminalization but also does not pursue housing-first without behavioral requirements. She secured community ambassador funding for neighborhood corridors as part of her District 7 budget priorities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Myrna_Melgar', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Melgar, a Guatemalan immigrant herself, co-authored a 2016 48 Hills op-ed asserting that 'Trump-brand hate has no home in SF' and defending San Francisco's sanctuary city values. SF operates under its 1989 'City and County of Refuge' ordinance and 2013 'Due Process for All' ordinance prohibiting city employees from assisting ICE enforcement. Melgar's immigrant identity and progressive politics place her firmly in support of SF's sanctuary framework with no evidence of any vote or statement favoring ICE cooperation.$$,
        ARRAY['https://www.sf.gov/information/sanctuary-city-ordinance', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Melgar is a Guatemalan immigrant and co-authored a 2016 piece defending San Francisco's sanctuary values against Trump immigration policies. Her official priorities include supporting immigrant communities, and she has consistently aligned with SF's sanctuary city framework. As a progressive Democrat representing a diverse district, she supports welcoming immigration policies and legal pathways, consistent with the broader SF progressive caucus position.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://www.sf.gov/information/sanctuary-city-ordinance']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Melgar is a Guatemalan immigrant who co-authored a 2016 op-ed defending San Francisco's sanctuary city policies against Trump-style immigration enforcement. SF's 'Due Process for All' ordinance (which the BOS passed and has maintained) prohibits cooperation with ICE civil detainers. As a progressive supervisor in a sanctuary city, Melgar's record and identity strongly align with opposing deportation enforcement and protecting undocumented residents.$$,
        ARRAY['https://www.sf.gov/information/sanctuary-city-ordinance', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Melgar serves on the Public Safety and Neighborhood Services Committee and has secured funding for community ambassadors on West Portal and Irving Street corridors. Her Street Safety Act prioritizes infrastructure-based safety interventions (traffic neckdowns, bike lanes, crosswalks) over police enforcement. She has not been identified with defund-police positions but also has not been associated with demands for major police expansion, placing her in a balanced community-plus-infrastructure approach to public safety.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Melgar describes herself as a 'bridge builder' between progressive and moderate factions. She supports development along transit corridors and received YIMBY endorsements in 2020 and 2024, but voted against a 495-unit project in 2021 and has negotiated community protections into the mayor's 2025 zoning plan. Her stated goal is 'ensuring that this progress includes tenants, small businesses, and affordable housing' — a managed-growth position that conditions development on community benefit rather than a pure market-led approach.$$,
        ARRAY['https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php', 'https://en.wikipedia.org/wiki/Myrna_Melgar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Melgar secured district budget funding for graffiti abatement and community ambassadors stationed on West Portal and Irving Street commercial corridors. These represent neighborhood-level cleanliness investments using both service provision (ambassadors) and enforcement-adjacent deterrence (graffiti removal), indicating a balanced maintenance-and-community-presence approach rather than either aggressive enforcement sweeps or purely services-based strategy.$$,
        ARRAY['https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Melgar is a progressive Guatemalan immigrant who explicitly applies an equity lens to her political work, including an endorsement hierarchy she disclosed that prioritizes 'the most progressive candidate always, except if that candidate is a cis hetero white man,' with specific ordering by race and gender identity. She supports workers' rights as a stated legislative priority and has championed immigrant communities and youth services. Her record aligns with strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php', 'https://www.sf.gov/profile--myrna-melgar/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Melgar lists 'expanding education for disadvantaged youth' and 'improving Westside senior services access' as core legislative priorities, and has secured district budget funding for youth services programs and senior YMCA programs. Her background includes work as Executive Director of Jamestown Community Center serving disadvantaged youth. These priorities reflect a commitment to publicly-funded early childhood and youth support programs rather than market-based childcare solutions.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Myrna Melgar / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Melgar lists 'supporting small businesses and workers' rights' as a legislative priority. She has secured district budget funding for Ocean Avenue community events and commercial corridor capacity building. In the mayor's zoning plan negotiations she explicitly demanded protections for small businesses alongside tenant protections. Her approach centers on community-based economic development with small business support, though she also backed development-friendly YIMBY positions and has worked within the Lurie administration's more business-friendly framework.$$,
        ARRAY['https://www.sf.gov/profile--myrna-melgar/', 'https://www.westsideobserver.com/25/11-overlooking-supervisor-melgar''s-shortcomings-she''s-a-keeper.php']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Paul Miyamoto
-- ============================================================

-- ----- Paul Miyamoto / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Miyamoto operates County Jails 2 and 3 under a mission of keeping the public safe, and in 2026 launched a $14M RESET sobering center at 444 Sixth St. as an alternative intake point for intoxicated individuals who would otherwise be booked or hospitalized. The RESET facility adds capacity for a specific population rather than reducing the jail footprint, suggesting a preference for expanded enforcement infrastructure alongside limited diversion, aligning with stance 4 (building additional capacity/enforcement as primary response).$$,
        ARRAY['http://sfsheriff.com/about', 'https://missionlocal.org/2026/05/sfpd-reset-sobering-center/', 'https://missionlocal.org/2026/05/sf-sheriff-reset-center-confusion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Miyamoto's approach blends traditional law enforcement with some alternatives: the RESET sobering center diverts intoxicated individuals from full booking to a 4-8 hour assessment facility, and his department operates rehabilitation and reentry programs inside county jails (Women's Resource Center, Community Programs Building). However, the RESET center is a detention-adjacent enforcement tool rather than a pure social service, and Miyamoto's 2025 endorsement of Republican law-and-order candidate Chad Bianco confirms a law-enforcement-first philosophy. This balances current police staffing with limited crisis-response alternatives — stance 3.$$,
        ARRAY['http://sfsheriff.com/about', 'https://missionlocal.org/2026/05/sf-sheriff-reset-center-confusion/', 'https://missionlocal.org/2025/07/chad-bianco-paul-miyamoto-california-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As SF Sheriff, Miyamoto operates under the 2013 Due Process for All Ordinance, which prohibits cooperation with ICE civil detainer requests and bars city employees from sharing detainee release information with federal immigration authorities. USA Today reported in January 2025 that Miyamoto vowed to protect immigrants from Trump policies. However, he simultaneously endorsed Republican Chad Bianco for California Governor in July 2025 — a candidate whose platform calls for abolishing sanctuary protections statewide — creating ideological tension. His operative practice is sanctuary-compliant (no ICE detainers honored), consistent with stance 2 (comply only with court-ordered detainers; protect undocumented crime victims from referral).$$,
        ARRAY['https://sf.gov/information/sanctuary-city-ordinance', 'https://en.wikipedia.org/wiki/Paul_Miyamoto', 'https://missionlocal.org/2025/07/chad-bianco-paul-miyamoto-california-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$SF's sanctuary ordinance — which Miyamoto as sheriff enforces — prohibits honoring civil ICE detainer requests and prohibits sharing detainee release information with federal authorities, effectively preventing the sheriff's office from facilitating deportations of the general undocumented population in custody. Wikipedia cites reporting that Miyamoto vowed to protect immigrants from Trump policies in January 2025. This is consistent with stance 2 (deport only those who commit serious violent crimes; provide legal status / non-cooperation for others), since the sanctuary framework functionally achieves that outcome.$$,
        ARRAY['https://sf.gov/information/sanctuary-city-ordinance', 'https://en.wikipedia.org/wiki/Paul_Miyamoto', 'https://missionlocal.org/2025/07/chad-bianco-paul-miyamoto-california-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Miyamoto operates within SF's sanctuary framework (which prohibits ICE detainer cooperation), and early-2025 reports cited him vowing to protect immigrants from Trump enforcement. At the same time, his July 2025 endorsement of Chad Bianco — whose platform calls for abolishing sanctuary protections statewide — indicates he does not ideologically oppose reduced immigration or stricter federal enforcement at the national level. As a local law enforcement officer he maintains current city-level non-enforcement posture (stance 3), neither expanding legal pathways nor calling for enforcement-first policies.$$,
        ARRAY['https://sf.gov/information/sanctuary-city-ordinance', 'https://en.wikipedia.org/wiki/Paul_Miyamoto', 'https://missionlocal.org/2025/07/chad-bianco-paul-miyamoto-california-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Miyamoto launched the RESET sobering center in May 2026 specifically to address public intoxication and disorder in public spaces, bringing individuals in handcuffs to a 24-hour enforcement and assessment facility rather than allowing encampments or public sleeping to continue. This aligns with stance 4 (prohibit encampments with graduated warnings and penalties; require basic options like shelter). The RESET approach is enforcement-primary (detention-adjacent) with a service component, not a decriminalization approach.$$,
        ARRAY['https://missionlocal.org/2026/05/sfpd-reset-sobering-center/', 'https://missionlocal.org/2026/05/sf-sheriff-reset-center-confusion/', 'http://sfsheriff.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Miyamoto's RESET sobering center represents a hybrid approach: individuals are brought in by police (sometimes in handcuffs) but processed through an alternative-to-jail facility with assessment and sobering services rather than full criminal booking. The SF Sheriff's Office also operates the Women's Resource Center and Community Programs Building providing services to incarcerated individuals. This blends outreach-adjacent services with enforcement-backed intake — enforcement only after the enforcement trigger, with basic services on-site — aligning with stance 3.$$,
        ARRAY['https://missionlocal.org/2026/05/sfpd-reset-sobering-center/', 'https://missionlocal.org/2026/05/sf-sheriff-reset-center-confusion/', 'http://sfsheriff.com/programs-and-events']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Miyamoto is a pragmatic moderate: he supports in-jail rehabilitation (Women's Resource Center, Community Programs Building, behavioral health support noted on sfsheriff.com) while also prioritizing enforcement. He endorsed pro-law-enforcement Republican Chad Bianco for Governor in 2025, signaling a law-enforcement-first philosophy. But his office also operates diversion programs and collaborates with public defenders and community groups on oversight issues. This pattern — maintain enforcement while adding rehabilitative programming — fits stance 3 (upgrade facilities only as needed; without major expansion or major reduction).$$,
        ARRAY['http://sfsheriff.com/about', 'https://missionlocal.org/2025/07/chad-bianco-paul-miyamoto-california-governor/', 'http://sfsheriff.com/programs-and-events']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$After deputies conducted an unlawful group strip search of 20 women in County Jail 2 in May 2025, Miyamoto's office collaborated with the Department of Police Accountability, the Sheriff's Oversight Board, Human Rights Commission, Department on Status of Women, and Public Defender's Office. Deputies were reassigned by March 2026. The department disputed some factual claims in the lawsuit. This is a mixed record: cooperation with oversight bodies after the fact, but the underlying incident reflects a failure of internal accountability — consistent with stance 3 (balance protecting religious/professional practices while maintaining equal treatment; here, accountability exists but is reactive not preventive).$$,
        ARRAY['https://sfstandard.com/2026/05/22/san-francisco-sheriff-sued-women-strip-search/', 'https://missionlocal.org/2026/05/sf-jail-women-mass-strip-search-lawsuit/', 'http://sfsheriff.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Miyamoto / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$In the aftermath of the 2025 jail strip search incident, Miyamoto's office worked with multiple accountability bodies (Sheriff's Oversight Board, Department of Police Accountability, Human Rights Commission) and reassigned the deputies involved by March 2026. The department issued public statements disputing the plaintiffs' characterization while acknowledging the investigation. This indicates moderate transparency — engaging oversight structures without proactively publishing investigation findings — consistent with stance 3.$$,
        ARRAY['https://sfstandard.com/2026/05/22/san-francisco-sheriff-sued-women-strip-search/', 'https://missionlocal.org/2026/05/sf-jail-women-mass-strip-search-lawsuit/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Manohar Raju
-- ============================================================

-- ----- Manohar Raju / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Raju's office secured the landmark In re Humphrey California Supreme Court ruling establishing that courts cannot jail people pretrial simply because they cannot afford bail. He has consistently opposed pretrial detention as a coercive tactic and argued that resources spent jailing people unnecessarily should instead fund housing, healthcare, education, and jobs. His oath of office explicitly committed to 'advocating for structural changes that contribute to ending the mass incarceration system.'$$,
        ARRAY['https://sfpublicdefender.org/about-us/racial-justice/', 'https://sfpublicdefender.org/news/california-supreme-court-affirms-that-freedom-cannot-depend-on-wealth/', 'https://sfpublicdefender.org/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Raju's stated mission for the office is to 'fiercely defend individuals, confront state sponsored violence, and advocate for community power.' He co-led the Coalition to End Biased Stops to restrict pretextual traffic stops, created the CopMonitor police accountability database, and uses the California Racial Justice Act to challenge convictions tainted by racial bias. His 2020 inaugural pledge vowed to 'advocate for structural changes that contribute to ending the mass incarceration system.'$$,
        ARRAY['https://sfpublicdefender.org/about-us/mission-vision-values-theory-of-change/', 'https://sfpublicdefender.org/copmonitor/', 'https://sfpublicdefender.org/about-us/racial-justice/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Raju consistently argues that incarceration and policing are not the primary drivers of public safety; his 2026 bail ruling statement said resources from unnecessary pretrial jailing 'should instead be invested in what truly makes communities safer: housing, healthcare, education, and job opportunities.' He criticized Mayor Breed's Tenderloin emergency declaration for relying on incarceration to address homelessness and drug use rather than services. He established mental health diversion programs (MAGIC) as alternatives to prosecution.$$,
        ARRAY['https://sfpublicdefender.org/news/california-supreme-court-affirms-that-freedom-cannot-depend-on-wealth/', 'https://sfpublicdefender.org/magic/', 'https://en.wikipedia.org/wiki/Manohar_Raju']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Raju attended the January 2025 citywide rally defending San Francisco's sanctuary city status following ICE enforcement actions. His 2020 oath of office explicitly pledged to 'fight against unjust and racist immigration laws, defend all people regardless of their birthplace or immigration status.' The Public Defender's Office operates an immigration unit that provides legal defense to immigrants facing criminal charges that could lead to deportation.$$,
        ARRAY['https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/', 'https://sfpublicdefender.org/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Raju's 2020 inaugural oath committed the office to fighting 'against unjust and racist immigration laws' and defending 'all people regardless of their birthplace or immigration status.' He personally attended the January 2025 sanctuary city rally organized after ICE targeted workers in downtown SF, standing in public solidarity with city officials opposing federal immigration enforcement. His office provides direct legal defense to immigrants facing deportation consequences from criminal charges.$$,
        ARRAY['https://sfpublicdefender.org/', 'https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Raju's inaugural pledge explicitly committed to fighting 'against unjust and racist immigration laws, defend all people regardless of their birthplace or immigration status.' He and his office provide legal services to immigrants as a core function and he has publicly stood in support of sanctuary city protections against federal enforcement. His racial justice framework explicitly extends to immigrants within the criminal justice system.$$,
        ARRAY['https://sfpublicdefender.org/', 'https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Raju co-led the Coalition to End Biased Stops which secured adoption of the nation's most comprehensive policy restricting pretextual traffic stops disproportionately used against Black residents. His office actively litigates under the California Racial Justice Act to challenge convictions where racial bias infected proceedings by judges, attorneys, or jurors. He founded Public Defenders for Racial Justice and his office's Racial Equity Plan embeds anti-racism throughout organizational practices.$$,
        ARRAY['https://sfpublicdefender.org/about-us/racial-justice/', 'https://sfpublicdefender.org/personnel/mano-raju/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wikipedia documents that Raju criticized Mayor Breed's Tenderloin emergency declaration, opposing incarceration of homeless individuals and those with substance abuse disorders as a solution. His office operates MAGIC programs (mental health diversion) and he has consistently argued that housing, healthcare, and services — not criminal enforcement — are what make communities safer, as he stated in response to the 2026 California Supreme Court bail ruling.$$,
        ARRAY['https://en.wikipedia.org/wiki/Manohar_Raju', 'https://sfpublicdefender.org/magic/', 'https://sfpublicdefender.org/news/california-supreme-court-affirms-that-freedom-cannot-depend-on-wealth/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manohar Raju / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa35ed62-a5a7-47fd-99d3-0ceb3336e405',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Raju opposed Mayor Breed's use of emergency powers in the Tenderloin to criminalize homelessness and substance use, advocating instead for services and treatment. He has explicitly stated that investments in housing, healthcare, and education — not incarceration — are 'what truly makes communities safer.' His office's MAGIC programs provide mental health and addiction services as alternatives to prosecution and incarceration for unhoused clients.$$,
        ARRAY['https://en.wikipedia.org/wiki/Manohar_Raju', 'https://sfpublicdefender.org/magic/', 'https://sfpublicdefender.org/news/california-supreme-court-affirms-that-freedom-cannot-depend-on-wealth/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Danny Sauter
-- ============================================================

-- ----- Danny Sauter / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sauter supports building more housing — especially for families and seniors — and wants to convert vacant office buildings into residential units. He also proposes creating a Special Use District that prioritizes affordable, senior, and family housing, and calls for streamlining bureaucratic processes to accelerate development. He maintains rent control protections as a renter himself and supports neighborhood input on land-use decisions, placing him in a moderate pro-supply but community-centered position.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sauter's stated homelessness philosophy is 'Treatment, Not Tents.' He supports expanding conservatorship for those needing mandated mental health treatment, and calls for arresting and incarcerating drug dealers with enhanced penalties for fentanyl. He also supports permanent supportive housing and sober-living facilities, but his primary frame is enforcement-plus-treatment rather than housing-first.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Sauter's platform calls for disrupting drug dealing through arrest and incarceration, expanding conservatorship, and enforcing drug-free common-area guidelines at shelters — pairing enforcement with treatment rather than leading with outreach. He acknowledges the disproportionate concentration of shelters in Lower Nob Hill and wants good-neighbor policies, but his primary tool is accountability and enforcement alongside services.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sauter explicitly campaigned on hiring more police officers and 911 dispatchers, deploying foot patrols, retaining district station captains, and organizing merchant safety walks. He supports bilingual officers for Chinatown and Russian Hill communities. His platform prioritizes increased police staffing and community policing over shifting resources toward social services.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/', 'https://sfbos.archive.sf.gov/supervisor-sauter-district-3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Sauter's signature early initiative was advocating for 1,500 additional trash cans citywide and creating new street cleaning teams. He introduced this proposal in early 2025 after taking office. His approach treats cleanliness primarily as an infrastructure and enforcement problem — adding receptacles, combating graffiti, and expanding sanitation crews — rather than a services or outreach failure.$$,
        ARRAY['https://missionlocal.org/tag/danny-sauter/', 'https://dannyd3.squarespace.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Sauter has explicitly stated he wants to maintain rent control protections, noting he is a renter himself. His platform includes maintaining rent control safeguards and expanding tenant support programs. He supports current tenant protections while allowing market rents for new construction, consistent with SF's existing rent stabilization framework.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Sauter's platform calls for extending the Central Subway to North Beach and Fisherman's Wharf, creating a more walkable district, and supporting safe bicycle infrastructure through the city's Biking and Rolling Plan. He proposes pedestrian plazas to revitalize commercial areas. His transportation priorities are multimodal with a strong transit and pedestrian emphasis.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sauter's downtown recovery agenda centers on reducing red tape and fees for new entrepreneurs, facilitating new business openings, converting vacant offices to residential use, and pursuing a downtown university initiative. He chairs the SF Downtown Revitalization and Economic Recovery Financing District, signaling a business-attraction focus. He views regulatory reform and incentives as the primary tools for economic recovery.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://sfbos.archive.sf.gov/supervisor-sauter-district-3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Sauter supports streamlining housing development and wants to reform the 'broken planning code' and limit abuse of discretionary review processes. He proposes a Special Use District for affordable, senior, and family housing and wants neighborhood input preserved in land-use decisions. This positions him as moderately pro-density — willing to ease restrictions and speed approvals while retaining community input requirements.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Sauter has not publicly opposed SF's sanctuary city ordinance and has emphasized building trust with immigrant communities — particularly Chinatown's Cantonese-speaking residents — as a policing priority, advocating for bilingual officers rather than immigration enforcement cooperation. No evidence of any call to cooperate with ICE or modify the sanctuary ordinance.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-sauter-district-3', 'https://sf.gov/information/sanctuary-city-ordinance']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sauter supported Senator Scott Wiener's SB 1047 AI safety bill in 2024, stating it would place 'reasonable safeguards' alongside new technology development. This reflects a moderate pro-regulation stance — supportive of basic safety testing and oversight frameworks but not opposed to AI development.$$,
        ARRAY['https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Sauter's agenda prioritizes streamlining permitting, reducing fees and red tape for entrepreneurs, and actively recruiting development including a downtown university. He chairs the SF Downtown Revitalization and Economic Recovery Financing District, reflecting a pro-growth orientation. He supports market-led development with some affordable housing requirements rather than managed growth limits.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://sfbos.archive.sf.gov/supervisor-sauter-district-3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sauter calls for arresting and incarcerating drug dealers with enhanced penalties specifically for fentanyl, and supports expanding conservatorship for individuals with severe mental illness. His 'Treatment, Not Tents' framework combines enforcement with services but places significant emphasis on incarceration and legal intervention. This aligns with a tough-on-crime approach rather than a diversion-first philosophy.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danny Sauter / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a320a9-39e9-4152-85a0-11cab602fdc9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sauter's platform includes planting 1,000 new street trees and supports SF Sierra Club environmental initiatives — consistent with his prior role as SF Sierra Club's first Housing Chair. He promotes tree canopy and green space in his district without opposing development. His record reflects standard environmental stewardship balanced with an active pro-development downtown recovery agenda.$$,
        ARRAY['https://dannyd3.squarespace.com/issues', 'https://missionlocal.org/2024/10/district-3-analysis-how-do-the-candidates-differ/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stephen Sherrill
-- ============================================================

-- ----- Stephen Sherrill / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sherrill lists public safety as his top priority and co-sponsored the RESET Center legislation pairing enforcement with medically supervised treatment for public drug use. He supports expanded police surveillance technology including license plate readers and speed cameras while maintaining the facial recognition ban. His approach is firmly enforcement-first with treatment as a complement, not an alternative.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-district-2-candidates-sherrill-brooke-police-surveillance/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/', 'https://www.sf.gov/profile--stephen-sherrill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sherrill co-sponsored the RESET Center legislation requiring that people using drugs publicly be brought to a medically supervised holding facility rather than left on the street, paired with enforcement rather than a pure services-first approach. He also co-sponsored Supervisor Dorsey's legislation allowing evictions from permanent supportive housing for illicit drug use, diverging from SF's traditional housing-first model. His prior work as Director of the Mayor's Office of Innovation used data systems to coordinate enforcement and services rather than expanding services alone.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-relapse-eviction/', 'https://www.sf.gov/profile--stephen-sherrill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Sherrill co-sponsored RESET Center legislation pairing enforcement of public drug use with a 24-hour medically supervised sobering period and warm handoff to treatment — prioritizing enforcement as the trigger rather than voluntary outreach. He stated San Francisco will not accept open-air drug use as normal and supports targeted arrests of people using fentanyl publicly. He supplements enforcement with treatment infrastructure but the sequencing is enforcement-first.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/', 'https://missionlocal.org/2026/05/meet-the-candidates-all-2026-district-2-supervisor-answers/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sherrill voted for Mayor Lurie's December 2025 upzoning plan permitting six- to eight-story buildings on commercial corridors and developed the Family Zoning Plan parcel by parcel with his district. He backed affordable teacher housing at 750 Golden Gate, veteran housing on Van Ness, senior housing in the Marina, and developments at 3333 and 3700 California. He is endorsed by GrowSF and SF YIMBY and stated 'For 30 years we have said no, no, no, no' while calling for housing in every neighborhood.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-housing/', 'https://missionlocal.org/2026/05/sf-district-2-debate-marina/', 'https://sfstandard.com/2026/04/07/stephen-sherrill-lori-brooke-district-2-daniel-lurie/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Sherrill voted for the Lurie upzoning plan allowing six- to eight-story buildings on commercial corridors citywide and stated the north and west sides have produced only 10% of new housing despite holding 50% of residential land. He supports broad upzoning and backs downtown densification, stating transit-rich downtown must be part of the housing answer. His only reservation is project-specific scale (the 25-story Marina Safeway), not opposition to density as a principle.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-district-2-debate-marina/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-housing/', 'https://missionlocal.org/2026/03/sf-district-2-candidates-sherrill-brooke-housing-views-blocked/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Sherrill opposed Proposition D (CEO tax / gross receipts tax increase) citing its contribution to closures of neighborhood-serving grocery stores and pharmacies, and indicated preference for Prop C's approach of maintaining current tax structures with minor adjustments. He frames his fiscal approach around reducing regulatory and tax burdens on businesses. No direct statement on rent control was found, but his opposition to business tax increases and support for market-driven commercial recovery aligns with a deregulatory position.$$,
        ARRAY['https://missionlocal.org/2026/03/sf-district-2-candidates-stephen-sherrill-lori-brooke-ceo-tax/', 'https://missionlocal.org/2026/05/meet-the-candidates-all-2026-district-2-supervisor-answers/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sherrill championed the 'First Year Free' initiative to remove permitting and licensing barriers for new businesses and strongly supports improving commercial corridors in his district. He opposed the CEO / gross receipts tax citing harm to neighborhood businesses and stated the proposal 'could undermine downtown recovery and make us less competitive with nearby cities.' He aligns closely with Mayor Lurie's business-friendly deregulation agenda and frames economic recovery through reducing bureaucracy rather than public investment.$$,
        ARRAY['https://missionlocal.org/2026/03/sf-district-2-candidates-stephen-sherrill-lori-brooke-ceo-tax/', 'https://www.sf.gov/profile--stephen-sherrill/', 'https://sfstandard.com/2026/04/07/stephen-sherrill-lori-brooke-district-2-daniel-lurie/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sherrill opposed Proposition D, a CEO / gross receipts tax increase on large businesses, citing harm to neighborhood-serving businesses and competitive disadvantage for SF's downtown. He stated it is bad policy to revisit major tax changes so soon after Prop M (2024) and was more open to the Chamber of Commerce's competing Prop C that maintains current rates while expanding small business exemptions. He supports small business tax relief and opposes new business tax increases.$$,
        ARRAY['https://missionlocal.org/2026/03/sf-district-2-candidates-stephen-sherrill-lori-brooke-ceo-tax/', 'https://missionlocal.org/2026/05/meet-the-candidates-all-2026-district-2-supervisor-answers/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Sherrill supports expanding the District 2 bike network and explicitly backs the Muni parcel tax stating 'robust, reliable transit is essential.' He is advancing Webster Street bike protection linking Pacific Heights to the Marina and Arguello corridor improvements, and prioritizes four dangerous intersection upgrades. He uses all modes — driving, transit, and biking — and sits on the SF County Transportation Authority. His position is balanced between multimodal investment and maintaining road access.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-district-2-candidates-brooke-sherrill-bike-lanes/', 'https://missionlocal.org/2026/05/meet-the-candidates-all-2026-district-2-supervisor-answers/', 'https://www.sf.gov/profile--stephen-sherrill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Sherrill emphasizes clean and safe neighborhoods as a core priority and supports enforcement-paired approaches to street conditions. His co-sponsorship of RESET Center enforcement legislation and support for enforcement of public drug use indicate he views sanitation and cleanliness as a public-safety matter addressed primarily through enforcement and accountability rather than expanded services alone. He previously worked on clean streets initiatives in NYC under Bloomberg.$$,
        ARRAY['https://www.sf.gov/profile--stephen-sherrill/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sherrill supports streamlined tree-planting fee requirements to make homeowners' lives easier and backs strategic city-managed planting, but insists on preserving neighborhood input and an appeals process for tree removal. On PG&E, he expressed support for municipalization evaluation 'provided it is fiscally responsible and transparent' and cited climate resilience as a factor. His Sierra Club endorsement reflects mainstream environmental alignment without aggressive regulatory positions.$$,
        ARRAY['https://missionlocal.org/2026/03/meet-the-district-2-candidates-stephen-sherrill-lori-brooke-tree-streamlining/', 'https://missionlocal.org/2026/03/sf-district-2-candidates-stephen-sherrill-lori-brooke-pge/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$No direct statement from Sherrill on ICE cooperation or sanctuary city policy was found in available sources. He is a Democrat closely aligned with Mayor Lurie who has maintained San Francisco's sanctuary city ordinance. His political background (registered D in 2023, Bloomberg administration experience) and coalition suggest alignment with SF's sanctuary city framework, but absent a direct vote or statement this is scored conservatively at 2 based on his Democratic alignment and Lurie coalition membership.$$,
        ARRAY['https://sfstandard.com/2026/04/07/stephen-sherrill-lori-brooke-district-2-daniel-lurie/', 'https://www.sf.gov/profile--stephen-sherrill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Sherrill voted for the Lurie upzoning plan, champions the 'First Year Free' business deregulation initiative, and supports streamlined permitting and reduced bureaucratic barriers across housing and business licensing. He is backed by GrowSF, SF YIMBY, and Mayor Lurie's network and stated the city has said 'no' to growth for 30 years. He frames the city's future around removing regulatory barriers to development while maintaining fiscal responsibility.$$,
        ARRAY['https://missionlocal.org/2026/05/sf-district-2-debate-marina/', 'https://sfstandard.com/2026/04/07/stephen-sherrill-lori-brooke-district-2-daniel-lurie/', 'https://missionlocal.org/2026/04/sf-district-2-sherrill-brooke-canvassing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sherrill co-sponsored the RESET Center legislation diverting drug users from jail to a medically supervised 24-hour facility — a diversion approach — but combined with enforcement rather than decriminalization. He supports targeted enforcement of public drug use and has not called for jail expansion. His approach reflects a middle path: enforcing public order laws while routing people to treatment rather than incarceration.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/', 'https://missionlocal.org/2026/05/meet-the-candidates-all-2026-district-2-supervisor-answers/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sherrill co-sponsored RESET Center enforcement legislation and supports targeted arrests of people using fentanyl publicly, stating 'San Francisco will not accept open-air drug use as normal.' He co-sponsored legislation allowing evictions from permanent supportive housing for drug use, signaling a conviction-of-consequences approach. His framing of accountability — 'accountability with a real path to recovery' — leans toward enforcement with treatment as complement rather than a diversion-first philosophy.$$,
        ARRAY['https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-drug-users-arrested/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-relapse-eviction/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Sherrill / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54e564e7-4788-4913-b75e-95382896d509',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sherrill cited climate change as a rationale for resilient energy infrastructure and has Sierra Club endorsement suggesting mainstream environmental alignment. He supports PG&E municipalization evaluation partly on climate-resilience grounds: 'As climate change intensifies, resilient and well-maintained power systems are critical for public safety.' No evidence of stronger climate legislation or opposition to fossil fuel use at the city level was found; his position appears centrist-pragmatic.$$,
        ARRAY['https://missionlocal.org/2026/03/sf-district-2-candidates-stephen-sherrill-lori-brooke-pge/', 'https://missionlocal.org/2026/04/sf-district-2-candidates-sherrill-brooke-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joaquín Torres
-- ============================================================

-- ----- Joaquín Torres / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Torres served 12 years as President of the SF Housing Authority Commission, overseeing rehabilitation of over 3,400 units of public housing with $750 million in improvements and a 20% increase in housed families (to 16,545 households as of May 2025). As OEWD Director (2018–2022) he led the Invest in Neighborhoods initiative focused on equitable neighborhood economic development. His record consistently prioritizes expanding and preserving affordable housing supply and protecting low-income residents, aligning with aggressive affordability investment short of universal public ownership.$$,
        ARRAY['https://www.sf.gov/profile--joaquin-torres/', 'https://www.sf.gov/departments--assessor-recorder']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Assessor-Recorder, Torres has built the office around property tax 'fairness, care, equity, and excellence,' with a strong emphasis on ensuring vulnerable residents — seniors, disabled persons, veterans, and low-income homeowners — receive full tax relief through exemptions and exclusions. He launched the annual Family Wealth Conference, the city's largest free property tax education event (hundreds attended in 2025), and participated in San Francisco's Government Alliance for Racial Equity program. His prior role as OEWD Director focused on equitable economic impact and workforce development for underserved communities, consistent with a modestly progressive tax equity orientation.$$,
        ARRAY['https://www.sf.gov/departments--assessor-recorder', 'https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Torres's office actively removes unlawful discriminatory racial covenants from recorded property documents, addressing historical injustices embedded in San Francisco's land records. He participated in the City's Government Alliance for Racial Equity program and serves on SPUR's Equity Advisory Council. As OEWD Director he specifically served as liaison to Latino and American Indian communities and focused on equitable economic impact. These actions are consistent with strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.sf.gov/departments--assessor-recorder', 'https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Torres is a San Francisco city official who operates under and implements SF's sanctuary city ordinances (the 1989 City and County of Refuge Ordinance and 2013 Due Process for All Ordinance), which prohibit city employees from using city resources to assist ICE enforcement. As a Democrat appointed by Mayor London Breed and a former liaison specifically to Latino and immigrant communities through OEWD, his institutional role and political background strongly align with the sanctuary/welcoming end of the scale. No evidence of any deviation from SF's sanctuary posture.$$,
        ARRAY['https://www.sf.gov/information/sanctuary-city-ordinance', 'https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Director of OEWD (2018–2022), Torres led citywide economic hardship mitigation during COVID-19 for businesses and workers, oversaw the Invest in Neighborhoods initiative, and focused on small business support, nonprofit capacity building, and equitable economic development. He specifically served underserved communities including Latino and American Indian populations. This community/worker-centered economic development approach, with targeted support for small businesses and nonprofits rather than large corporate incentives, aligns with a value of 2.$$,
        ARRAY['https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Torres served as President of the SF Housing Authority Commission for 12 years (stepping down May 2025), overseeing a $750 million rehabilitation of over 3,400 units of public housing and increasing housed families by 20% to 16,545 households. This sustained institutional leadership in maintaining and improving public housing stock, combined with facilitation of transfer to affordable housing providers, reflects a housing-first and services orientation rather than criminalization of homelessness.$$,
        ARRAY['https://www.sf.gov/departments--assessor-recorder', 'https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joaquín Torres / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As SF Housing Authority Commission President for 12 years, Torres's primary strategy for addressing housing instability was investment in public housing rehabilitation and facilitation of transfer to affordable housing providers — a services and housing supply approach rather than enforcement. His OEWD background also emphasized outreach and capacity building for nonprofit service providers. No evidence of support for enforcement-first or sweeps-based approaches.$$,
        ARRAY['https://www.sf.gov/departments--assessor-recorder', 'https://www.sf.gov/profile--joaquin-torres/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Greg Wagner
-- ============================================================

-- NOTE: No stances found in CSV for Greg Wagner (c3627dfd-6f20-40e8-b9af-55c4af048d92)

-- ============================================================
-- Shamann Walton
-- ============================================================

-- ----- Shamann Walton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Walton authored the CAREN Act (2020) criminalizing racially-motivated fraudulent 911 calls — a landmark civil rights measure. He co-led the Dream Keeper Initiative in 2020 to redirect $120M in police funding toward Black community economic development. In February 2020 he proposed a formal reparations working group for African American residents, and as Board President championed racial equity requirements in city programs.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://sfstandard.com/2024/09/04/san-francisco-dream-keeper-initiative-audit/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Walton stated in January 2025: 'We are going to make sure that our sanctuary policies and laws that have been in place for decades here in San Francisco continue' and 'We are not going to support warrantless searches. We are not going to provide resources to separate families and to separate communities here in San Francisco.' He pledged to 'fight this administration consistently every single day.'$$,
        ARRAY['https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Walton has been a consistent sanctuary city defender, stating San Francisco will not provide resources to separate families or deport community members. In his January 2025 Mission Local interview he noted he had 'prevented deportations of long-term community residents' as a key accomplishment. His sanctuary stance explicitly opposes warrantless immigration enforcement within city limits.$$,
        ARRAY['https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Walton has championed SF's sanctuary city ordinance and opposes cooperation with federal immigration enforcement. He stated he would 'fight this administration consistently every single day' to protect sanctuary policies and prevent family separation. He has personally cited preventing deportations of long-term D10 residents as a key accomplishment.$$,
        ARRAY['https://missionlocal.org/2025/01/s-f-government-bands-together-in-defense-of-sanctuary-status/', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Walton explicitly rejected allowing four-plexes in previously single-family zones, stating such policies would 'speed up the gentrification.' He also supported a resolution opposing California SB 50, which would have mandated denser housing near transit. While he champions affordable housing production (100% affordable projects in D10), he opposes market-rate upzoning as a displacement risk to his majority-Black and working-class district.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Walton opposed four-plex zoning reforms and SB 50 (statewide upzoning near transit), explicitly citing gentrification concerns for Bayview-Hunters Point. He favors community-controlled, 100% affordable housing development over broad market-rate density increases. His opposition to upzoning is grounded in anti-displacement rather than single-family preservation ideology, but the practical effect is resistance to density reform.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Walton represents a district with high concentrations of Black and low-income renters and has consistently championed tenant protections and anti-displacement policies. His opposition to market-rate upzoning is explicitly tied to preventing gentrification and protecting existing renters. He co-led the Dream Keeper Initiative to invest in Black community economic stability, and has prioritized 100% affordable housing development in D10.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-walton-district-10', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Walton has opposed shelters imposed without community input (opposed Lurie's Bayview shelter plan in 2025, stating 'No one in [the] community supports the site. No one.') but supports services-first approaches. His January 2025 interview shows he backed a Vehicle Triage Center and tiny homes at Jerrold Avenue as community-supported alternatives. He opposes top-down enforcement without community consent.$$,
        ARRAY['https://sfstandard.com/2025/05/13/lurie-shelter-beds-bayview-shamann-walton/', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Walton opposed Mayor Lurie's unilateral placement of a shelter at Jerrold Commons in Bayview, saying the mayor was 'bulldozing community' without consent. He advocates for community-designed solutions including safe parking sites for RV dwellers, tiny homes, and outreach. His approach prioritizes services offered with community input over enforcement-first or mayoral top-down shelter siting.$$,
        ARRAY['https://sfstandard.com/2025/05/13/lurie-shelter-beds-bayview-shamann-walton/', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Walton co-led the 2020 Dream Keeper Initiative to redirect $120M from police to Black community investment, and introduced a June 2020 resolution banning police hiring of officers with serious misconduct histories. He created a D10 Public Safety Plan emphasizing violence deterrence and community engagement. His approach blends reformed policing with community investment, not pure enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://sfstandard.com/2024/09/04/san-francisco-dream-keeper-initiative-audit/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Walton co-sponsored a 2018 resolution to close SF's youth detention center by December 2021 — a key criminal justice reform. He championed juvenile justice reform to avoid the prison pipeline. His January 2025 interview cited closing Juvenile Hall as an accomplishment, and he introduced a ban on hiring officers with serious misconduct histories, signaling a reform-oriented criminal justice stance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Walton co-sponsored the 2018 resolution to close SF's youth detention center and championed juvenile justice diversion to prevent youth incarceration. He has opposed policies that funnel youth into the criminal justice system, and his Dream Keeper Initiative redirected public safety funds toward community investment rather than incarceration infrastructure.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$In October 2025, Walton co-signed a measure to tax ridesharing companies (Uber/Lyft) and CEO pay in San Francisco. The proposal is framed as compensating for federal revenue losses from Trump tax cuts. Walton has consistently advocated for wealth redistribution and community investment, and his role in the Dream Keeper Initiative involved redirecting $120M in public funds toward Black community economic programs.$$,
        ARRAY['https://sfstandard.com/2025/10/26/sf-rideshare-ceo-transit-tax/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Walton founded and led Young Community Developers (YCD), which provided job and career training for Bayview residents and eliminated employment barriers through education. As supervisor, he has championed local hiring requirements, community benefit agreements for D10 development projects (Power Station, Pier 70, Candlestick), and the Dream Keeper Initiative for Black-owned business investment. His economic development model is explicitly community- and worker-centered.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Walton has championed environmental justice in Bayview-Hunters Point, demanding full cleanup of the Hunter's Point Naval Shipyard before any redevelopment. He cited bureaucratic obstacles and stated 'There's a schedule and a timeline for cleanup that has never been made.' He sits on the Bay Area Air Quality Management District board, has worked to reduce industrial emissions and shut cement plants near D10, and requires soil testing before housing development.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Walton serves on the Bay Area Air Quality Management District board and has worked to reduce industrial emissions and 'shut cement plants' near Bayview-Hunters Point as part of his environmental justice work. His January 2025 interview cited improving industrial operations and addressing air quality as priorities. His environmental justice focus centers on reducing fossil-fuel-related pollution in a historically overburdened community.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Walton's environmental justice work in Bayview-Hunters Point — demanding full Naval Shipyard cleanup, reducing industrial emissions, shutting cement plants, and serving on the Bay Area Air Quality Management District board — reflects strong climate/environmental action priorities. He has not publicly opposed climate action and his district's industrial pollution legacy makes environmental regulation a core local issue.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Walton eliminated switchbacks on the T-line (Muni Metro), introduced the 15 Express bus service, and prioritized D10 transit restoration post-pandemic. However, he opposed the 2020 Caltrain sales tax measure because the funding mechanism was regressive (sales tax) and the service primarily benefited higher-income commuters, not D10 residents. His transit focus has been on equity-driven public transit serving working-class communities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Walton has insisted on community input and community benefit requirements for D10 development projects including Power Station, Pier 70, and Candlestick. He opposed Lurie's shelter siting without community consent and has spoken against development that bypasses community processes. His approach is community-centered growth — development is acceptable when accompanied by affordability requirements and genuine community involvement.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/', 'https://sfstandard.com/2025/05/13/lurie-shelter-beds-bayview-shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Walton has focused on environmental justice and community services rather than enforcement-first sanitation. His D10 Public Safety Plan addresses neighborhood cleanliness through community engagement. He has opposed top-down enforcement without community input (e.g., the Bayview shelter controversy) and favors service investment in historically neglected districts. His stated goal is equitable resource distribution to districts historically isolated and disenfranchised.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-walton-district-10', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Walton's sf.gov profile lists 'universal healthcare' as an explicit policy commitment. He has championed health equity in Bayview-Hunters Point, including addressing environmental health hazards (Navy shipyard contamination, air quality) that disproportionately affect D10 residents. His progressive caucus alignment and community-investment philosophy are consistent with a single-payer or strong public coverage stance.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Walton explicitly lists 'universal healthcare' as a policy priority and has championed Medicaid/Medi-Cal access for low-income D10 residents. His progressive stance and advocacy for low-income and working-class communities is consistent with strong support for Medicare and Medicaid expansion. He has co-led initiatives to redirect public funding from enforcement toward community health and wellbeing.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Walton has consistently championed community and working-class interests over corporate interests, co-signing the 2025 rideshare/CEO pay tax measure. As a progressive supervisor with a strong anti-corporate stance (calling Lurie an 'oligarch'), he aligns with campaign finance reform and public funding of elections. No direct vote on campaign finance is available, but his progressive caucus alignment and stated values are consistent with strict limits on corporate political spending.$$,
        ARRAY['https://sfstandard.com/2025/10/26/sf-rideshare-ceo-transit-tax/', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Walton has emphasized support services for working families and youth opportunity as core priorities, and his sf.gov profile lists advocacy for 'living-wage job opportunities' and 'support services' as key commitments. His YCD background included eliminating barriers to employment for parents. While no specific childcare legislation has been identified in available sources, his progressive community-investment platform aligns with significantly expanded childcare subsidies.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Walton was a former San Francisco Board of Education President who championed public schools and specifically secured funding for the 'school district's first African American Achievement and Leadership Initiative.' His entire education record is built around investing in public schools, closing achievement gaps, and protecting underserved students — not diverting funds to private alternatives. He has also advocated for educator affordable housing within the public school district.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://sfbos.archive.sf.gov/supervisor-walton-district-10']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Walton has consistently championed expanded civic participation, serving historically disenfranchised communities in D10. His January 2025 interview noted that the current Board is 'less willing to challenge the status quo affecting communities of color,' reflecting his commitment to political power for marginalized communities. As Board President (2021-2022) he directed resources to historically excluded communities, and his progressive stance aligns firmly with expanded voting access.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/', 'https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Walton has advocated for community representation and fairness in governance structures. His January 2025 interview specifically criticized the current Board as 'more conservative' and 'less willing to challenge the status quo affecting communities of color,' reflecting concern about political representation. His progressive alignment is consistent with support for independent redistricting commissions that reduce partisan manipulation.$$,
        ARRAY['https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Walton is a progressive Democrat from San Francisco representing a diverse district who has consistently championed civil rights and non-discrimination. His authorship of the CAREN Act (criminalizing racially-motivated 911 calls) and his focus on civil rights enforcement reflect a strong anti-discrimination stance across categories. San Francisco's progressive caucus, of which he is a member, uniformly supports full marriage equality.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Walton is a member of SF's progressive caucus and has consistently championed non-discrimination and civil rights protections. His co-founding of the SF Black Caucus of the BOS, authorship of the CAREN Act, and overall civil rights record are consistent with support for transgender inclusion in sports. No specific vote or statement on trans athletes has been identified, but his documented civil rights stance supports scoring at 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No specific votes or statements on religious freedom exemptions have been identified for Walton in available sources. His civil rights record (CAREN Act, racial equity focus) suggests support for anti-discrimination laws over broad religious exemptions, but without a direct vote or statement on religious freedom specifically, a moderate position is applied.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Walton is a progressive San Francisco supervisor who has championed reproductive rights as part of his broader civil rights platform. His sf.gov profile lists support for healthcare access, and his progressive caucus alignment includes strong pro-choice positions. While no specific abortion legislation or direct vote at the local level is available (abortion policy is primarily a state/federal issue), his documented progressive stance and district demographics are consistent with strong pro-choice support.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://en.wikipedia.org/wiki/Shamann_Walton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Walton has consistently championed economic security for low-income and working-class communities, explicitly listing support for 'living-wage job opportunities' and 'support services' as core priorities. His progressive economic stance and advocacy for wealth redistribution (co-signing the CEO pay tax measure) are consistent with strong Social Security protection and expansion. No direct vote on Social Security is available as it is a federal issue.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/', 'https://sfstandard.com/2025/10/26/sf-rideshare-ceo-transit-tax/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$No evidence of a specific stance on tariffs has been identified for Walton in available sources. As a city supervisor, tariff policy is outside his direct legislative purview. His progressive economic stance is consistent with fair trade concerns, but no direct statement or vote on tariffs is available to score more precisely.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '24e9212c-b011-422a-865c-093e35050901',
        $$No specific stance on Ukraine aid has been identified for Walton in available sources. As a city supervisor, foreign policy is outside his direct legislative purview. His progressive alignment and opposition to isolationism are consistent with support for Ukraine, but no direct statement has been found.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No specific stance on social media misinformation regulation has been identified for Walton in available sources. His civil rights focus (CAREN Act addressing harm from false reports) shows awareness of the real-world impact of harmful speech, but no direct position on platform regulation or content moderation has been found.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No specific stance on AI regulation has been identified for Walton in available sources. As a city supervisor focused on environmental justice and community investment, AI policy has not featured in his documented record. No score can be assigned with confidence.$$,
        ARRAY['https://www.sf.gov/profile--shamann-walton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shamann Walton / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab7b830-c831-45f9-bca8-11b079f42680',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Walton's civil rights record — authoring the CAREN Act, championing reparations, closing the youth jail, and reforming police hiring — reflects a living constitutionalist approach that interprets rights expansively to address contemporary racial and social justice concerns. His January 2025 interview explicitly stated concern that the current Board is 'less willing to challenge the status quo affecting communities of color,' reflecting his view that law must actively protect marginalized communities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Shamann_Walton', 'https://missionlocal.org/2025/01/interview-supervisor-shamann-walton-wants-less-nuclear-waste-more-affordable-housing-in-district-10/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Alan Wong
-- ============================================================

-- ----- Alan Wong / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As of December 2025, Wong stated he wants to 'fully staff' the SFPD and supports 'ending open-air drug markets,' aligning with moderate enforcement priorities. He is a member of the Public Safety and Neighborhood Services Committee. This marks a significant shift from his 2020 platform calling for a 25% SFPD budget cut.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/', 'https://sfbos.archive.sf.gov/supervisor-wong-district-4']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wong voted in favor of Mayor Lurie's Family Zoning Plan (April 2026), which allows taller residential developments on the west side of the Sunset District. He has described this as aligned with his current values, contrasting with his 2020 opposition to a YIMBY-backed state housing bill. He is characterized as providing a reliable vote for the Lurie moderate development agenda.$$,
        ARRAY['https://sfstandard.com/2026/04/13/alan-wong-ranked-choice-voting/', 'https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Wong voted yes on Mayor Lurie's Family Zoning Plan, which upzones parts of the Sunset to allow taller developments. He is described as a YIMBY-leaning supervisor in his current role, though opponents argue the plan threatens neighborhood character. His past (2020) position opposed YIMBY housing bills.$$,
        ARRAY['https://sfstandard.com/2026/04/13/alan-wong-ranked-choice-voting/', 'https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$In December 2025, Wong announced he supports reopening the Great Highway to vehicle traffic on weekdays, backing a ballot initiative to roll back Proposition K (which had converted the highway to a pedestrian/bike promenade). He stated: 'I believe my values aligned with the majority of Sunset residents to support reopening the Great Highway on weekdays.' This is a car-priority stance over multimodal/pedestrian use.$$,
        ARRAY['https://sfstandard.com/2025/12/19/alan-wong-sunset-dunes-great-highway-reopening/', 'https://en.wikipedia.org/wiki/Alan_Wong_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wong supports 'ending open-air drug markets' as of his December 2025 appointment, indicating an enforcement-oriented approach to street conditions. He is a member of the Public Safety and Neighborhood Services Committee. No specific housing-first or expanded services positions have been documented in his current role.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/', 'https://sfbos.archive.sf.gov/supervisor-wong-district-4']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Wong's stated focus on 'ending open-air drug markets' and fully staffing SFPD suggests he prioritizes enforcement-side responses to homelessness and street conditions. He is aligned with Mayor Lurie's moderate enforcement agenda. No specific outreach-first or diversion program positions have been documented in his current role.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Wong represents San Francisco, a sanctuary city, and as a child of Hong Kong immigrants with progressive roots, he has not indicated any deviation from SF's sanctuary city policy. All SF supervisors operate under the sanctuary ordinance, and his background and 2020 labor/progressive platform provide strong prior alignment with welcoming immigration policies.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-wong-district-4', 'https://en.wikipedia.org/wiki/Alan_Wong_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$In his 2020 City College campaign platform, Wong explicitly backed expanding rent control and affordable housing development. No public reversal of this position has been documented in his 2025-2026 supervisorial role, though his overall ideological shift toward the center on other issues leaves some uncertainty.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$In his 2020 City College campaign, Wong explicitly supported a tax on CEO pay and a tax on vacant storefronts. As a Democrat aligned with labor unions and progressive fiscal policy, he has not reversed these positions publicly in his current supervisorial role.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wong's 2020 City College platform included support for divesting from fossil fuels. As an appointed SF supervisor with no documented reversal of this position, it remains his most recent publicly stated stance on the issue.$$,
        ARRAY['https://sfstandard.com/2025/12/02/alan-wong-sunset-supervisor-daniel-lurie-moderate-progressive/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Wong voted for Mayor Lurie's Family Zoning Plan, which expands allowable building heights in the Sunset, aligning him with moderate pro-growth development. However, he also emphasized listening to constituents and healing a 'divided community,' suggesting he does not favor fully deregulated market-led growth. He occupies a middle ground on development pace.$$,
        ARRAY['https://sfstandard.com/2026/04/13/alan-wong-ranked-choice-voting/', 'https://sfstandard.com/2025/12/19/alan-wong-sunset-dunes-great-highway-reopening/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Wong / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6273727a-26e0-495d-9fda-f827b88029b3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wong served as policy director for the Children's Council of San Francisco prior to his election, with a professional focus on childcare accessibility. His official BOS profile lists 'children and families' as a core priority area. This background strongly indicates support for expanded public childcare subsidies and access.$$,
        ARRAY['https://sfbos.archive.sf.gov/supervisor-wong-district-4', 'https://en.wikipedia.org/wiki/Alan_Wong_(politician)']::text[]::text[])
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
-- WHERE p.id IN ('708db738-2bf1-4a6f-b8a5-7ac23d171b33', '969f1ca4-4766-44fd-8638-ef813b1835e7', '86c12b33-cb76-41da-bdf0-6b58a0cbbed6', 'c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1', 'd2596e4d-f491-449e-b112-40be13418112', '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996', '68845df3-7103-45d9-8429-7ef51ee6ada3', 'd3c5004c-9ca0-444e-96d9-107d4315abcb', '6273727a-26e0-495d-9fda-f827b88029b3', 'd1a320a9-39e9-4152-85a0-11cab602fdc9', '54e564e7-4788-4913-b75e-95382896d509', 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9', '02f88a57-ccf5-4fe1-a693-7fc949321fb1', 'eab7b830-c831-45f9-bca8-11b079f42680', '8f59c9fd-03f9-4652-bc4a-418bd8764a1f', '94035c6d-d6b2-4223-bdeb-e93e2ec26198', 'f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a', 'aa35ed62-a5a7-47fd-99d3-0ceb3336e405', 'c3627dfd-6f20-40e8-b9af-55c4af048d92', 'f82edba8-5f6b-4c00-af78-b782426f05a2')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('708db738-2bf1-4a6f-b8a5-7ac23d171b33', '969f1ca4-4766-44fd-8638-ef813b1835e7', '86c12b33-cb76-41da-bdf0-6b58a0cbbed6', 'c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1', 'd2596e4d-f491-449e-b112-40be13418112', '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996', '68845df3-7103-45d9-8429-7ef51ee6ada3', 'd3c5004c-9ca0-444e-96d9-107d4315abcb', '6273727a-26e0-495d-9fda-f827b88029b3', 'd1a320a9-39e9-4152-85a0-11cab602fdc9', '54e564e7-4788-4913-b75e-95382896d509', 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9', '02f88a57-ccf5-4fe1-a693-7fc949321fb1', 'eab7b830-c831-45f9-bca8-11b079f42680', '8f59c9fd-03f9-4652-bc4a-418bd8764a1f', '94035c6d-d6b2-4223-bdeb-e93e2ec26198', 'f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a', 'aa35ed62-a5a7-47fd-99d3-0ceb3336e405', 'c3627dfd-6f20-40e8-b9af-55c4af048d92', 'f82edba8-5f6b-4c00-af78-b782426f05a2')
--   AND pc.politician_id IS NULL;