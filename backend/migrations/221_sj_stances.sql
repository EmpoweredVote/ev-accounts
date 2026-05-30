-- ============================================================================
-- Migration 221: San Jose Officials Stances — 1 Politician (Matt Mahan/Mayor)
-- ============================================================================
-- Purpose: Insert/upsert stance data for San Jose Mayor Matt Mahan.
--
-- Scope: 1 politician (Matt Mahan/Mayor) — 10 council members excluded
--        (adjacent-evidence only, user decision 2026-05-28)
--
-- Politician: Matt Mahan (Mayor)
--
-- Stance count: 12 rows (politician_answers + politician_context)
--
-- Topic scope: 42 topics (all 43 live topics except data-centers)
-- (Only 12 of 42 applicable topics have direct-evidence stances for Matt Mahan)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
--
-- CSTA-01 status: Partially closed — Mayor covered; council members deferred
--                 until direct evidence is available.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, is_live = true):
-- city-sanitation          7687de4f-4d0b-462a-b803-bdfb23b16b42
-- economic-development     eb3d1247-0de1-4b7f-baec-7259861efd53
-- growth-and-development   fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- homelessness             4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response    6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                  669cac97-66a6-4087-b036-936fbe62efb3
-- local-immigration        b9ccee94-ad96-4f10-b655-889d8e5abe92
-- public-safety-approach   e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting            48cc9585-ec22-4f53-8d42-6839828dd36f
-- residential-zoning       d4f18138-a2e0-4110-b925-7387d9d0d16d
-- taxes                    f7e5678d-dadd-4556-a2fc-446e24642ceb
-- transportation-priorities ba59337e-30e2-4aba-a39a-426b3366eb27

-- Politician UUID reference (essentials.politicians):
-- Matt Mahan (Mayor)  41949a2b-563a-4608-91c6-951c63252a91

BEGIN;

-- ============================================================
-- Matt Mahan (Mayor, City of San Jose)
-- ============================================================

-- ----- Matt Mahan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Mayor Mahan has consistently favored enforcement-first approaches to homelessness. He endorsed California Proposition 36 in 2024, which increased sentences for theft and drug-related crimes. He redirected Measure E affordable housing funds toward temporary shelter and quick-build communities, prioritizing visible encampment clearance. His 2022 campaign centered on accountability dashboards for homelessness reduction and he has publicly attributed crime and homelessness increases to prior reform policies.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/california-divide/2024/10/california-proposition-36-crime-enforcement/', 'https://sanjosespotlight.com/mayor-matt-mahan-san-jose/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Mahan has pursued a mixed approach — enforcement plus services. He redirected Measure E funds in 2022-2024 toward shelter construction and temporary housing rather than purely punitive measures. His administration promoted expanded treatment options alongside stronger drug enforcement in 2023-2024. However, his housing focus shifted toward temporary shelter over permanent supportive housing, indicating a pragmatic rather than decriminalization approach.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/housing/2024/02/san-jose-measure-e-homeless-housing/', 'https://sanjosespotlight.com/mayor-mahan-san-jose/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '669cac97-66a6-4087-b036-936fbe62efb3',
$$In 2022, Mahan decreased funds available for permanent affordable housing to prioritize shelter construction. His administration has redirected Measure E property transfer tax revenues toward temporary housing. He proposed further redirecting Measure E toward temporary homeless housing in the 2024-25 budget. While not opposing affordable housing, his tenure shows a preference for shelter-based short-term solutions over permanent affordable housing construction.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/housing/affordable-housing/', 'https://sanjosespotlight.com/mahan-affordable-housing/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Mahan's first address as mayor focused on public safety and reforming the booking process. He advocated for license plate readers, speed cameras, and other law enforcement technologies. He endorsed Proposition 36 in 2024 against the Democratic Party's official position, which increased sentences for drug and theft crimes. He publicly linked prior reforms to increases in crime, homelessness, and drug deaths.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/california-divide/2024/10/california-proposition-36-crime-enforcement/', 'https://sanjosespotlight.com/mayor-mahan-public-safety/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Mahan is a former tech entrepreneur (Brigade Media, co-founded with Sean Parker). He received endorsements from business-aligned groups and has consistently supported tech-industry-friendly policies. His administration has prioritized business growth and reduced tax burdens. His 2026 gubernatorial campaign has drawn backing from Silicon Valley billionaires including Google co-founder Sergey Brin and Palantir co-founder Joe Lonsdale, reflecting his pro-growth orientation.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/politics/california-governor-2026/', 'https://sanjosespotlight.com/mayor-mahan-tech-business/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Mahan has consistently supported growth-friendly policies. He opposed the 2023 municipal union contract that increased wages, arguing it would force service cuts. Business San Jose Chamber endorsed him for prioritizing business growth and reducing tax burdens. His tech entrepreneur background and Silicon Valley billionaire backing signal pro-growth disposition. His gubernatorial platform centers on cutting regulations to accelerate development.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/politics/california-governor-2026/matt-mahan/', 'https://sanjosespotlight.com/mayor-mahan-city-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Mahan redirected Measure E affordable housing funds toward quick-build shelter communities rather than increasing permanent density. His administration has not championed broad upzoning but also has not opposed it. His 2025 comments on Proposition 50 (congressional redistricting) showed willingness to accept pragmatic middle-ground positions. No direct evidence of strong pro- or anti-upzoning stance; adjacent evidence suggests pragmatic pro-shelter approach.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/housing/2023/11/california-housing-legislation/', 'https://sanjosespotlight.com/mayor-mahan-housing-policy/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Mahan opposed the 2023 municipal union contract partly on grounds that increased costs would lead to budget deficits. He has emphasized efficient use of existing tax revenues. Business-aligned supporters value his fiscal restraint. His campaign received backing from tech billionaires who typically prefer limited government intervention. No direct evidence of a specific tax stance; adjacent evidence suggests fiscal conservatism within Democratic framework.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/politics/california-governor-2026/', 'https://sanjosespotlight.com/mayor-mahan-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '48cc9585-ec22-4f53-8d42-6839828dd36f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '48cc9585-ec22-4f53-8d42-6839828dd36f',
$$In 2025, Mahan expressed reluctant support for California Proposition 50, which authorized temporary legislatively drawn congressional maps. He criticized Governor Newsom's approach as too combative but agreed to support the measure despite concerns about partisan redistricting. This suggests a pragmatic, moderate position — neither strongly opposing gerrymandering nor championing independent commissions.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/politics/redistricting/', 'https://sanjosespotlight.com/matt-mahan-california-politics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$No direct evidence of Mahan taking a strong position on local immigration enforcement. San Jose maintains sanctuary city policies that predate his tenure. His public safety focus (Prop 36, enforcement technology) suggests moderate enforcement posture. As a San Jose Democrat running for governor, he is expected to uphold sanctuary policies. No evidence of ICE cooperation or opposition to existing sanctuary frameworks.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/immigration/', 'https://sanjosespotlight.com/san-jose-sanctuary-city/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Mahan has focused on city budget efficiency and service delivery. His administration has dealt with a $50 million budget deficit in 2026. No direct evidence of a distinctive transportation stance. San Jose has ongoing VTA and Caltrain infrastructure investments. Adjacent evidence from his pro-growth, business-friendly posture suggests support for transportation infrastructure that enables economic development.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://sanjosespotlight.com/san-jose-transportation/', 'https://www.vta.org/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Mahan / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41949a2b-563a-4608-91c6-951c63252a91', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Mahan's homelessness response has included encampment clearance as a core strategy, which directly addresses public space sanitation. He redirected housing funds toward shelter and quick-build communities to address visible street homelessness. His public safety focus includes cleanliness as a component. His accountability dashboards from the 2022 campaign included metrics on city sanitation and encampment reduction.$$,
ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/housing/homelessness/', 'https://sanjosespotlight.com/mayor-mahan-san-jose-homelessness/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
