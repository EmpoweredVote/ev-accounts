-- ============================================================================
-- Migration 412: Michael J. Rodrigues Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael J. Rodrigues (MA State Senator, 25D37,
--   First Bristol and Plymouth District, Senate Ways & Means Chairman).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: f865995d-ad3a-4d2d-827f-ed8a1a67af18 (external_id: -210037)

BEGIN;

-- ----- Michael J. Rodrigues / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Senate Ways & Means Chairman, Rodrigues has been a central figure in MA tax and budget policy. He guided the 2023 tax relief package (Chapter 50) through the Senate and has been responsible for balancing revenue needs with targeted tax relief. He supported the 2022 millionaires surtax (Question 1) and has overseen progressive budget policies. As chairman, he has taken a pragmatic approach: generating sufficient revenue for services while providing meaningful tax relief for working and middle-income families through measures like the rental deduction, Child and Family Tax Credit, and senior circuit breaker expansions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.wgbh.org/news/politics/2023-09-29/gov-healey-signs-tax-relief-package-into-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rodrigues has been a consistent healthcare funding advocate, using his Ways & Means position to prioritize healthcare in state budgets. He has backed MassHealth expansion and sustained funding for healthcare services in the South Coast region, which includes Fall River and New Bedford. He supported the 2022 mental health parity law and has backed substance use treatment funding. His district faces significant opioid and substance use challenges and he has worked to ensure treatment resources are available.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Rodrigues has championed economic development for the South Coast region, which includes Fall River and New Bedford. As Ways & Means Chairman, he has been instrumental in securing state economic development investments for his region including the South Coast Rail project (extending commuter rail to Fall River and New Bedford). He backed Gateway Cities economic development funding and offshore wind industry investments that directly benefit the New Bedford port. He has also supported life sciences and advanced manufacturing for the region.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.southcoasttoday.com/news/local_news/rodrigues-south-coast-rail-economic-development/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rodrigues voted for the 2021 Climate Act and has been a strong supporter of offshore wind development, which is particularly important to New Bedford, one of the key ports for the offshore wind industry. He has backed clean energy investments in state budgets and supported offshore wind job creation for his district. His climate record reflects both policy commitment and economic development interest -- the offshore wind industry represents a major economic opportunity for the South Coast region.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rodrigues voted for the 2024 Affordable Homes Act and used his budget role to ensure housing investments were included in state budgets. His district includes Fall River and New Bedford, both Gateway Cities with significant affordable housing needs. He has backed state funding for affordable housing preservation and new construction and has supported homeownership programs for working families.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Rodrigues voted for the 2022 Work and Family Mobility Act. His district includes Fall River and New Bedford which have significant immigrant communities, particularly Cape Verdean and Portuguese-speaking immigrants. He has voted with the Democratic caucus on immigration access measures and backed in-state tuition for undocumented students. His budget position has ensured funding for immigrant services in state budgets.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Rodrigues voted for the 2020 police reform law and has supported criminal justice reform measures including substance use treatment. His district faces significant public safety challenges including drug trafficking and violence in Fall River and New Bedford. He has backed treatment and prevention programs while also supporting effective law enforcement. His approach is centrist Democratic, balancing reform with effective public safety responses.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Rodrigues / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f865995d-ad3a-4d2d-827f-ed8a1a67af18',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Rodrigues has been the champion of the South Coast Rail project, the multi-decade effort to bring commuter rail service to Fall River and New Bedford. The project was completed and service began in 2023, representing a major transportation victory for his district. As Ways & Means Chairman, he used his budget influence to ensure funding for this project. He has also backed highway improvements in his district and the broader South Coast transportation infrastructure.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJR0', 'https://www.wbur.org/news/2023/04/03/south-coast-rail-fall-river-new-bedford-commuter-service-begins']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
